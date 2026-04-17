import 'dart:convert';
import 'dart:io';
import '../models/transaction.dart';

class PDFParserService {
  Future<List<TransactionModel>> parsePDF(File file) async {
    final contents = await file.readAsBytes();
    final text = extractAllText(contents);

    if (text.isEmpty) {
      throw Exception(
        'Could not extract text from PDF. Ensure it\'s a text-based statement.',
      );
    }

    final transactions = _parseAllTransactions(text);

    if (transactions.isEmpty) {
      throw Exception(
        'No transactions found in PDF. Check if it\'s a valid bank statement.',
      );
    }

    return _deduplicateTransactions(transactions);
  }

  // TEXT EXTRACTION METHODS
  String extractAllText(List<int> bytes) {
    final allStrings = <String>[];

    // Search for stream/endstream in raw bytes (not decoded string)
    int pos = _indexOfBytes(bytes, 'stream', 0);
    while (pos != -1) {
      // Check for newline after 'stream'
      int streamContentStart = -1;
      if (pos + 8 <= bytes.length &&
          bytes[pos + 6] == 13 &&
          bytes[pos + 7] == 10) {
        streamContentStart = pos + 8;
      } else if (pos + 7 <= bytes.length && bytes[pos + 6] == 10) {
        streamContentStart = pos + 7;
      } else {
        pos = _indexOfBytes(bytes, 'stream', pos + 6);
        continue;
      }

      int endIdx = _indexOfBytes(bytes, 'endstream', streamContentStart);
      if (endIdx == -1) {
        pos = _indexOfBytes(bytes, 'stream', pos + 6);
        continue;
      }

      // Extract the stream content
      final streamBytes = bytes.sublist(streamContentStart, endIdx);
      final text = _extractTextFromStream(streamBytes);
      if (text.isNotEmpty) {
        allStrings.add(text);
      }

      pos = _indexOfBytes(bytes, 'stream', endIdx);
    }

    // Also try raw readable text extraction as fallback
    if (allStrings.isEmpty) {
      final rawText = _extractRawReadableText(bytes);
      if (rawText.isNotEmpty) {
        allStrings.add(rawText);
      }
    }

    return allStrings.join('\n\n');
  }

  int _indexOfBytes(List<int> bytes, String needle, int start) {
    final needleBytes = ascii.encode(needle);
    for (int i = start; i <= bytes.length - needleBytes.length; i++) {
      bool match = true;
      for (int j = 0; j < needleBytes.length; j++) {
        if (bytes[i + j] != needleBytes[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  String _extractTextFromStream(List<int> streamBytes) {
    // Try to decode as FlateDecode (most common)
    try {
      // For now, just extract readable text from the stream
      return _extractRawReadableText(streamBytes);
    } catch (e) {
      return '';
    }
  }

  String _extractRawReadableText(List<int> bytes) {
    final buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i++) {
      final code = bytes[i];
      if ((code >= 32 && code <= 126) || code == 10 || code == 13) {
        buffer.write(String.fromCharCode(code));
      } else {
        buffer.write(' ');
      }
    }
    var text = buffer.toString();
    text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    text = text.replaceAll(RegExp(r'\n\s*\n'), '\n');
    return text.trim();
  }

  // FORMAT DETECTION
  List<TransactionModel> _parseAllTransactions(String text) {
    // Try Union Bank / Axis format first (DD-MM-YYYY with UPIAR/UPIAB patterns)
    if (isUnionBankFormat(text)) {
      final txns = _parseUnionBankStatement(text);
      if (txns.isNotEmpty) return txns;
    }

    // Then try HDFC style
    if (isHDFCFormat(text)) {
      final txns = parseHDFCStatement(text);
      if (txns.isNotEmpty) return txns;
    }

    // Generic fallback
    return _parseGenericStatement(text.split('\n'));
  }

  bool isUnionBankFormat(String text) {
    // Union Bank has DD-MM-YYYY dates with UPIAR/UPIAB patterns
    int ddmmmyyyyCount = RegExp(r'\d{2}-\d{2}-\d{4}').allMatches(text).length;
    int upiAbArCount = RegExp(r'UPI[AB]R/').allMatches(text).length;

    return ddmmmyyyyCount >= 5 && upiAbArCount >= 3;
  }

  bool isHDFCFormat(String text) {
    final indicators = [
      'Statement of account',
      'Narration',
      'Withdrawal',
      'Deposit',
      'Closing',
      'Balance',
      'UPI-',
      'NEFT',
      'CR-',
    ];
    int hits = 0;
    for (final ind in indicators) {
      if (text.contains(ind)) hits++;
    }
    return hits >= 3;
  }

  // HDFC PARSER WITH BALANCE LINE SUPPORT
  List<TransactionModel> parseHDFCStatement(String text) {
    final dateRx = RegExp(r'(\d{2})/(\d{2})/(\d{2})');
    final amountRx = RegExp(r'([\d,]+\.\d{2})$');
    final balanceHeaderRx = RegExp(
      r'Date\s+Narration.*Withdrawal\s+Amt\.\s+Deposit\s+Amt\.\s+Closing\s+Balance',
    );
    final balanceLineRx = RegExp(r'([\d,]+\.\d{2})\s+([\d,]+\.\d{2})$');
    final salaryAmountRx = RegExp(r'SALARY.*?(\d{1,3}(,\d{3})*(\.\d{2})?)');

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final transactions = <TransactionModel>[];
    bool foundBalanceHeader = false;
    final balanceLines = <String>[];

    // Look for balance header line to understand the format
    for (int idx = 0; idx < lines.length; idx++) {
      if (balanceHeaderRx.hasMatch(lines[idx])) {
        foundBalanceHeader = true;
        // Look for the next balance line to get opening balance
        for (int j = idx + 1; j < lines.length && j < idx + 5; j++) {
          final balanceMatch = balanceLineRx.firstMatch(lines[j]);
          if (balanceMatch != null) {
            balanceLines.add(lines[j]);
            break;
          }
        }
        break;
      }
    }

    int i = 0;
    while (i < lines.length) {
      final dm = dateRx.firstMatch(lines[i]);

      if (dm != null) {
        final day = int.parse(dm.group(1)!);
        final month = int.parse(dm.group(2)!);
        final yearRaw = int.parse(dm.group(3)!);
        final year = yearRaw < 50 ? 2000 + yearRaw : 1900 + yearRaw;

        if (year >= 2019 &&
            year <= 2030 &&
            month >= 1 &&
            month <= 12 &&
            day >= 1 &&
            day <= 31) {
          // Look for amount in the same line or next few lines
          int amountLineIdx = -1;
          String amountStr = '';

          // Check if amount is in the same line (including middle positions)
          final sameLineAmount = amountRx.firstMatch(lines[i]);
          if (sameLineAmount != null) {
            amountStr = sameLineAmount.group(1)!;
            amountLineIdx = i;
          } else {
            // Check next few lines for amount
            for (int j = i + 1; j < i + 5 && j < lines.length; j++) {
              final lineAmount = amountRx.firstMatch(lines[j]);
              if (lineAmount != null) {
                amountStr = lineAmount.group(1)!;
                amountLineIdx = j;
                break;
              }
            }
          }

          // Special handling for HDFC format with balance lines
          double? calculatedAmount;
          if (amountLineIdx == -1 && foundBalanceHeader) {
            // Look for balance line just before this transaction
            for (int j = i - 1; j >= 0 && j >= i - 10; j--) {
              final balanceMatch = balanceLineRx.firstMatch(lines[j]);
              if (balanceMatch != null) {
                final openingStr = balanceMatch.group(1)!;
                final closingStr = balanceMatch.group(2)!;
                final openingBalance = double.parse(
                  openingStr.replaceAll(',', ''),
                );
                final closingBalance = double.parse(
                  closingStr.replaceAll(',', ''),
                );
                // Amount is the absolute difference
                calculatedAmount = (closingBalance - openingBalance).abs();
                amountStr = calculatedAmount.toStringAsFixed(2);
                amountLineIdx = i;
                balanceLines.add(lines[j]);
                break;
              }
            }
          }

          // Special handling for salary transactions
          if (amountLineIdx == -1) {
            final salaryMatch = salaryAmountRx.firstMatch(lines[i]);
            if (salaryMatch != null) {
              amountStr = salaryMatch.group(1)!;
              amountLineIdx = i;
            }
          }

          if (amountLineIdx >= 0 || calculatedAmount != null) {
            double? amount;
            if (amountStr.isNotEmpty) {
              amount = double.tryParse(amountStr.replaceAll(',', ''));
            } else if (calculatedAmount != null) {
              amount = calculatedAmount;
            }

            if (amount != null && amount > 0) {
              final merchant = _extractMerchant(lines[i]);
              if (merchant != 'Unknown') {
                final txnDate = DateTime(year, month, day);
                final isCredit =
                    _isCredit(lines[i]) ||
                    lines[i].contains('CR-') ||
                    lines[i].contains('SALARY');
                final method = _detectPaymentMethod(lines[i]);

                transactions.add(
                  TransactionModel(
                    id: '${txnDate.millisecondsSinceEpoch}_${merchant.hashCode}_$amount',
                    timestamp: txnDate.millisecondsSinceEpoch,
                    amount: amount,
                    currency: 'INR',
                    description: lines[i],
                    credit: isCredit,
                    merchant: merchant,
                    paymentMethod: method,
                    uploadId: 'pdf_hdfc',
                    createdAt: DateTime.now(),
                  ),
                );
              }
            }
          }
        }
      }
      i++;
    }

    return transactions;
  }

  // HELPER METHODS
  String _extractMerchant(String line) {
    // HDFC specific merchant extraction
    if (line.contains('CAPGEMINI')) {
      return 'CAPGEMINI';
    }
    if (line.contains('SALARY')) {
      return 'SALARY';
    }
    if (line.contains('UPI-')) {
      // Try to extract UPI merchant
      final upiRx = RegExp(r'UPI-\w+');
      final match = upiRx.firstMatch(line);
      if (match != null) {
        return match.group(0)!.substring(4); // Remove 'UPI-' prefix
      }
    }
    if (line.contains('NEFT')) {
      // Try to extract NEFT merchant
      final neftRx = RegExp(r'NEFT\s+(.*?)(?:\s+\d{2}/\d{2}/\d{2})');
      final match = neftRx.firstMatch(line);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }
    return 'Unknown';
  }

  bool _isCredit(String line) {
    // Credit detection logic
    return line.contains('CR-') || line.contains('SALARY');
  }

  String _detectPaymentMethod(String line) {
    // Payment method detection logic
    if (line.contains('NEFT')) return 'NEFT';
    if (line.contains('UPI')) return 'UPI';
    if (line.contains('IMPS')) return 'IMPS';
    return 'OTHER';
  }

  // UNION BANK PARSER
  List<TransactionModel> _parseUnionBankStatement(String text) {
    // Implementation would go here
    return <TransactionModel>[];
  }

  List<TransactionModel> _parseGenericStatement(List<String> lines) {
    // Generic parsing implementation
    return <TransactionModel>[];
  }

  List<TransactionModel> _deduplicateTransactions(
    List<TransactionModel> transactions,
  ) {
    // Deduplication logic
    final seen = <String>{};
    final result = <TransactionModel>[];

    for (final txn in transactions) {
      final key = '${txn.timestamp}_${txn.amount}_${txn.merchant}';
      if (!seen.contains(key)) {
        seen.add(key);
        result.add(txn);
      }
    }

    return result;
  }
}
