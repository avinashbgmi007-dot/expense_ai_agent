import 'package:expense_ai_agent/models/transaction.dart';
import 'dart:io';

class HDFCParserFix {
  static List<TransactionModel> parseHDFCStatementWithBalances(String text) {
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
    double lastClosingBalance = 0.0;
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
            final openingStr = balanceMatch.group(1)!;
            lastClosingBalance = double.parse(openingStr.replaceAll(',', ''));
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

  static String _extractMerchant(String line) {
    // Extract merchant logic here
    // This is a simplified version - implement based on actual needs
    if (line.contains('CAPGEMINI')) {
      return 'CAPGEMINI';
    }
    return 'Unknown';
  }

  static bool _isCredit(String line) {
    // Credit detection logic
    return line.contains('CR-') || line.contains('SALARY');
  }

  static String _detectPaymentMethod(String line) {
    // Payment method detection logic
    if (line.contains('NEFT')) return 'NEFT';
    if (line.contains('UPI')) return 'UPI';
    if (line.contains('IMPS')) return 'IMPS';
    return 'OTHER';
  }
}
