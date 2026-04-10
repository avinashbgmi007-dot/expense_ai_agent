import 'dart:io';
import 'package:excel/excel.dart';
import '../models/transaction.dart';

/// Service to parse XLSX bank statements and extract transactions.
class XLSXParserService {

  /// Parse an XLSX file and return a list of transactions.
  Future<List<TransactionModel>> parseXLSX(File file) async {
    final transactions = <TransactionModel>[];

    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Iterate through all sheets in the excel file
      for (final table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null) continue;

        // Extract header and rows
        if (sheet.maxRows > 0) {
          final rows = sheet.rows;
          // Use common column headers to identify data
          int dateIdx = -1;
          int amountIdx = -1;
          int merchantIdx = -1;
          int descriptionIdx = -1;

          // Attempt to find headers in the first few rows
          int headerRowIdx = -1;
          for (int i = 0; i < (rows.length < 5 ? rows.length : 5); i++) {
            final row = rows[i];
            for (int j = 0; j < row.length; j++) {
              final cell = row[j];
              if (cell == null) continue;
              final val = cell.value.toString().toLowerCase();

              if (val.contains('date')) dateIdx = j;
              if (val.contains('amount')) amountIdx = j;
              if (val.contains('merchant') || val.contains('payee')) {
                merchantIdx = j;
              }
              if (val.contains('desc')) descriptionIdx = j;
            }
            if (dateIdx != -1 && amountIdx != -1) {
              headerRowIdx = i;
              break;
            }
          }

          // If no headers found, we might need a more fallback approach or skip
          if (headerRowIdx == -1) {
            // Fallback: try to find any row that looks like transaction data
            // but for now, we'll skip sheets that don't have clear headers
            continue;
          }

          // Process rows after the header
          for (int i = headerRowIdx + 1; i < rows.length; i++) {
            final row = rows[i];
            if (row.length <= dateIdx || row.length <= amountIdx) continue;

            final dateVal = row[dateIdx]?.value?.toString() ?? '';
            final amountVal = row[amountIdx]?.value?.toString() ?? '';
            final merchantVal = merchantIdx != -1
                ? (row[merchantIdx]?.value?.toString() ?? '')
                : '';
            final descriptionVal = descriptionIdx != -1
                ? (row[descriptionIdx]?.value?.toString() ?? '')
                : '';

            if (dateVal.isEmpty || amountVal.isEmpty) continue;

            // Use internal parsing helpers from PDF/CSV logic if possible
            // but for XLSX we can be more direct with types if they exist
            final date = _parseDate(dateVal);
            final amount = _parseAmount(amountVal);

            if (date != null && amount != null) {
              transactions.add(
                TransactionModel(
                  id:
                      DateTime.now().millisecondsSinceEpoch.toString() +
                      i.toString(),
                  timestamp: date.millisecondsSinceEpoch,
                  amount: amount,
                  currency: 'INR',
                  description: descriptionVal.isNotEmpty
                      ? descriptionVal
                      : (merchantVal.isNotEmpty ? merchantVal : 'Unknown'),
                  credit:
                      amount >
                      0,
                  merchant: merchantVal.isNotEmpty ? merchantVal : 'Unknown',
                  paymentMethod: 'Unknown',
                  uploadId: 'xlsx_unknown',
                  createdAt: DateTime.now(),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to parse XLSX: $e');
    }

    return transactions;
  }

  /// Internal helper to parse date strings
  DateTime? _parseDate(String dateStr) {
    // Try to use CSV parser's logic for date formats
    // Or implement basic parsing here
    try {
      final cleaned = dateStr.replaceAll(RegExp(r'[^\d/\-.]'), '');

      final formats = [
        RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$'), // DD/MM/YYYY
        RegExp(r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})$'), // YYYY-MM-DD
        RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2})$'), // DD/MM/YY
      ];

      for (final format in formats) {
        final match = format.firstMatch(cleaned);
        if (match != null) {
          final g1 = int.parse(match.group(1)!);
          final g2 = int.parse(match.group(2)!);
          final g3 = int.parse(match.group(3)!);

          if (cleaned.startsWith(match.group(1)!)) {
            if (match.group(1)!.length == 4) {
              return DateTime(g1, g2, g3);
            } else {
              int year = g3;
              if (year < 100) year += 2000;
              return DateTime(year, g2, g1);
            }
          }
        }
      }
      return DateTime.tryParse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Internal helper to parse amount strings
  double? _parseAmount(String amountStr) {
    try {
      var cleaned = amountStr.replaceAll(RegExp(r'[₹$\s,]'), '');
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }
}
