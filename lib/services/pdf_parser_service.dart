import 'dart:io';
import 'dart:convert';
import '../models/transaction.dart';

/// Service to parse PDF bank statements and extract transactions
class PDFParserService {
  /// Parse PDF file and extract transactions
  /// Extracts text from PDF streams and identifies transaction patterns
  Future<List<TransactionModel>> parsePDF(File file) async {
    final transactions = <TransactionModel>[];

    try {
      final contents = await file.readAsBytes();

      // Extract text from PDF using stream extraction
      final text = _extractTextFromPDFStreams(contents);

      if (text.isEmpty) {
        throw Exception(
          'Could not extract text from PDF. Ensure it\'s a text-based statement.',
        );
      }

      // Clean and prepare text for parsing
      final cleanedText = _cleanExtractedText(text);
      final lines = cleanedText.split('\n');

      // Find transaction lines
      List<TransactionLine> transactionLines =
          _identifyTransactionLines(lines);

      if (transactionLines.isEmpty) {
        transactionLines = _identifyTransactionLinesLenient(lines);
      }

      if (transactionLines.isEmpty) {
        throw Exception(
          'No transactions found in PDF. Check if it\'s a valid statement.',
        );
      }

      // Parse each transaction line
      for (int i = 0; i < transactionLines.length; i++) {
        try {
          final transaction = _parseTransactionLine(transactionLines[i]);
          if (transaction != null) {
            transactions.add(transaction);
          }
        } catch (e) {
          continue;
        }
      }

      if (transactions.isEmpty) {
        throw Exception('Could not parse any transactions from PDF.');
      }
    } catch (e) {
      throw Exception('Failed to parse PDF: $e');
    }

    return transactions;
  }

  /// Extract text from PDF stream objects
  /// PDFs store text in "stream...endstream" sections
  String _extractTextFromPDFStreams(List<int> bytes) {
    try {
      // Decode PDF bytes to string with lenient error handling
      String pdfContent = utf8.decode(bytes, allowMalformed: true);

      // Step 1: Extract all text from PDF streams
      final StringBuffer extractedText = StringBuffer();

      // Pattern to find stream objects: look for "stream\n...endstream"
      final streamPattern = RegExp(
        r'stream\s*\n([\s\S]*?)\s*endstream',
        multiLine: true,
      );

      // Extract all streams
      for (final match in streamPattern.allMatches(pdfContent)) {
        final streamContent = match.group(1) ?? '';

        // Try to decode stream content
        try {
          // Stream might be compressed or encoded - try to extract visible text
          final visibleText = _extractVisibleTextFromStream(streamContent);
          if (visibleText.isNotEmpty) {
            extractedText.writeln(visibleText);
          }
        } catch (e) {
          // If stream processing fails, continue to next stream
          continue;
        }
      }

      // Step 2: If no text found in streams, try direct UTF-8 extraction
      if (extractedText.isEmpty) {
        return _extractTextFallback(pdfContent);
      }

      return extractedText.toString();
    } catch (e) {
      return '';
    }
  }

  /// Extract visible text from a PDF stream
  /// Looks for common PDF text operators: Tj, TJ, '
  String _extractVisibleTextFromStream(String stream) {
    final textBuffer = StringBuffer();

    // Look for text in parentheses (common PDF text format)
    // Pattern: (text) Tj or (text) '
    final textPattern = RegExp(r'\((.*?)\)\s*[Tj\'"]');

    for (final match in textPattern.allMatches(stream)) {
      var text = match.group(1) ?? '';

      // Decode PDF escape sequences
      text = text.replaceAll(r'\\n', '\n');
      text = text.replaceAll(r'\\t', '\t');
      text = text.replaceAll(r'\\\\', '\\');
      text = text.replaceAll(r'\(', '(');
      text = text.replaceAll(r'\)', ')');

      // Remove non-printable characters but keep numbers and common chars
      text = text
          .replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F-\x9F]'), '');

      if (text.isNotEmpty) {
        textBuffer.writeln(text);
      }
    }

    return textBuffer.toString();
  }

  /// Fallback text extraction if streams don't work
  /// Extracts all printable ASCII text from PDF
  String _extractTextFallback(String pdfContent) {
    final buffer = StringBuffer();

    // Extract sequences of printable characters
    for (int i = 0; i < pdfContent.length; i++) {
      final char = pdfContent[i];
      final code = char.codeUnitAt(0);

      // Keep: letters, numbers, spaces, common punctuation
      if ((code >= 32 && code <= 126) || code == 10 || code == 13) {
        buffer.write(char);
      } else if (code > 127 && code < 256) {
        // Keep extended ASCII for non-English text
        buffer.write(char);
      } else {
        // Replace non-printable with space
        buffer.write(' ');
      }
    }

    return buffer.toString();
  }

  /// Clean extracted text for parsing
  String _cleanExtractedText(String text) {
    // Remove control characters
    var cleaned = text.replaceAll(
      RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]'),
      '',
    );

    // Normalize whitespace
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n'), '\n');

    return cleaned;
  }

  /// Identify transaction lines by pattern matching
  /// Looks for patterns like: [DATE] [AMOUNT] [MERCHANT]
  List<TransactionLine> _identifyTransactionLines(List<String> lines) {
    final transactionLines = <TransactionLine>[];

    // Look for lines with date pattern
    final datePattern = RegExp(
      r'(\d{1,2}[-/\.]\d{1,2}[-/\.]\d{2,4})',
      caseSensitive: false,
    );
    final amountPattern = RegExp(
      r'([\d,]+\.\d{2}|[\d,]+)',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Look for date at start of line
      final dateMatch = datePattern.firstMatch(line);
      if (dateMatch == null) continue;

      // Look for amount anywhere in line (after the date)
      final amountMatch = amountPattern.firstMatch(
        line.substring(dateMatch.end),
      );
      if (amountMatch == null) continue;

      // Looks like a transaction line - extract info
      transactionLines.add(
        TransactionLine(
          fullLine: line,
          dateStr: dateMatch.group(1) ?? '',
          amountStr: amountMatch.group(1) ?? '',
        ),
      );
    }

    return transactionLines;
  }

  /// Parse a transaction line extracted from PDF
  TransactionModel? _parseTransactionLine(TransactionLine txnLine) {
    try {
      // Extract date
      final dateStr = txnLine.dateStr;
      final date = _parseDate(dateStr);
      if (date == null) return null;

      // Extract amount
      final amountStr = txnLine.amountStr;
      final amount = _parseAmount(amountStr);
      if (amount == null || amount <= 0) return null;

      // Extract merchant (usually significant text in line, not date/amount)
      String merchant = _extractMerchant(txnLine.fullLine);
      if (merchant.isEmpty) return null;

      // Extract description (remaining text after merchant)
      final description = _extractDescription(txnLine.fullLine, merchant);

      return TransactionModel(
        id:
            DateTime.now().millisecondsSinceEpoch.toString() +
            merchant.hashCode.toString(),
        timestamp: date.millisecondsSinceEpoch,
        amount: amount,
        currency: 'INR',
        description: description.isNotEmpty ? description : merchant,
        credit: false,
        merchant: merchant,
        paymentMethod: _detectPaymentMethod(txnLine.fullLine),
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse date from various formats found in PDFs
  DateTime? _parseDate(String dateStr) {
    try {
      // Clean the date string
      final cleaned = dateStr.replaceAll(RegExp(r'[^\d/\-.]'), '');

      // Try different formats: DD/MM/YYYY, DD/MM/YY, YYYY-MM-DD
      final formatPatterns = [
        (r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$', 'dmy'), // DD/MM/YYYY
        (r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2})$', 'dmy2'), // DD/MM/YY
        (r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})$', 'ymd'), // YYYY-MM-DD
        (r'^(\d{1,2})[.-](\d{1,2})[.-](\d{4})$', 'dmy'), // DD.MM.YYYY
      ];

      for (var (pattern, format) in formatPatterns) {
        final regex = RegExp(pattern);
        final match = regex.firstMatch(cleaned);
        if (match != null) {
          try {
            final groups = match.groups([1, 2, 3]);
            final g1 = int.parse(groups[0] ?? '0');
            final g2 = int.parse(groups[1] ?? '0');
            final g3 = int.parse(groups[2] ?? '0');

            int day, month, year;
            if (format == 'dmy') {
              day = g1;
              month = g2;
              year = g3;
            } else if (format == 'dmy2') {
              day = g1;
              month = g2;
              year = g3 < 50 ? 2000 + g3 : 1900 + g3;
            } else {
              year = g1;
              month = g2;
              day = g3;
            }

            return DateTime(year, month, day);
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      // Silently fail and return null
    }

    return null;
  }

  /// Parse amount from various formats
  double? _parseAmount(String amountStr) {
    try {
      // Remove currency symbols and whitespace
      var cleaned = amountStr.replaceAll(RegExp(r'[₹$\s]'), '');

      // Handle thousand separators (,)
      cleaned = cleaned.replaceAll(',', '');

      // Parse as double
      return double.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// Extract merchant name from transaction line
  String _extractMerchant(String line) {
    // Common merchants that appear in bank statements
    final commonMerchants = [
      'swiggy',
      'zomato',
      'uber',
      'ola',
      'netflix',
      'amazon',
      'dominos',
      'starbucks',
      'flipkart',
      'spotify',
      'hotstar',
      'amazon prime',
      'youtube',
      'apple music',
      'bookmyshow',
      'walmart',
      'reliance',
      'big basket',
      'instamart',
      'delhivery',
      'goibibo',
      'makemytrip',
      'redbus',
      'paytm',
      'phonepe',
      'google play',
      'airbnb',
      'agoda',
      'oyo',
      'dunzo',
    ];

    final lowerLine = line.toLowerCase();

    // Look for exact merchant matches first
    for (final merchant in commonMerchants) {
      if (lowerLine.contains(merchant)) {
        return merchant;
      }
    }

    // If no exact match, extract first non-date/non-amount token
    final tokens = line.split(RegExp(r'\s+'));
    for (final token in tokens) {
      final cleaned = token.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();

      // Skip very short tokens
      if (cleaned.length < 3) continue;

      // Skip if it looks like a date
      if (_isDateLike(cleaned)) continue;

      // Skip if it looks like an amount
      if (_isAmountLike(cleaned)) continue;

      // Skip payment method indicators
      if ([
        'credit',
        'debit',
        'upi',
        'wallet',
        'card',
        'bank',
        'payment',
        'inr',
        'transfer',
      ].any((word) => cleaned.contains(word))) {
        continue;
      }

      // Use this token as merchant
      if (cleaned.length <= 30) {
        return cleaned;
      }
    }

    return 'Unknown';
  }

  /// Extract description from transaction line
  String _extractDescription(String line, String merchant) {
    // Remove merchant from line to get description
    var description = line
        .replaceAll(RegExp(merchant, caseSensitive: false), '')
        .trim();

    // Remove date and amount patterns
    description = description.replaceAll(
      RegExp(r'\d{1,2}[-/\.]\d{1,2}[-/\.]\d{2,4}'),
      '',
    );
    description = description.replaceAll(RegExp(r'₹?\s?[\d,]+\.?\d*'), '');

    return description.trim();
  }

  /// Detect payment method from transaction description
  String _detectPaymentMethod(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('debit') || lower.contains('debit card')) {
      return 'Debit Card';
    }
    if (lower.contains('credit') || lower.contains('credit card')) {
      return 'Credit Card';
    }
    if (lower.contains('upi')) {
      return 'UPI';
    }
    if (lower.contains('netbanking') || lower.contains('net banking')) {
      return 'Net Banking';
    }
    if (lower.contains('cash')) {
      return 'Cash';
    }
    if (lower.contains('wallet')) {
      return 'Wallet';
    }
    return 'Unknown';
  }

  /// Helper: Check if string looks like a date
  bool _isDateLike(String str) {
    return RegExp(r'\d{1,2}[-/\.]\d{1,2}[-/\.]\d{2,4}').hasMatch(str);
  }

  /// Helper: Check if string looks like an amount
  bool _isAmountLike(String str) {
    return RegExp(r'₹?\d+[.,]?\d*').hasMatch(str);
  }

  /// Identify transaction lines with lenient matching
  /// Falls back to simpler heuristics if strict matching fails
  List<TransactionLine> _identifyTransactionLinesLenient(List<String> lines) {
    final transactionLines = <TransactionLine>[];
    final datePattern = RegExp(r'(\d{1,2}[-/\.]\d{1,2}[-/\.]\d{2,4})');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.length < 5) continue;

      // Look for any line with a date in it
      final dateMatch = datePattern.firstMatch(line);
      if (dateMatch == null) continue;

      // Look for any amount pattern (very loose)
      if (!RegExp(r'\d+').hasMatch(line)) continue;

      // This might be a transaction
      final amountPattern = RegExp(r'[\d,]+\.?\d*');
      final amountMatch = amountPattern.firstMatch(
        line.substring(dateMatch.end),
      );

      if (amountMatch != null) {
        transactionLines.add(
          TransactionLine(
            fullLine: line,
            dateStr: dateMatch.group(1) ?? '',
            amountStr: amountMatch.group(0) ?? '',
          ),
        );
      }
    }

    return transactionLines;
  }
}

/// Helper class to hold transaction line information
class TransactionLine {
  final String fullLine;
  final String dateStr;
  final String amountStr;

  TransactionLine({
    required this.fullLine,
    required this.dateStr,
    required this.amountStr,
  });
}
