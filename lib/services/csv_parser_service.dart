import 'dart:io';
import 'dart:convert';
import '../models/transaction.dart';

/// Service to parse CSV and Excel files
class CSVParserService {
  /// Parse CSV file and extract transactions
  Future<List<TransactionModel>> parseCSV(File file) async {
    final transactions = <TransactionModel>[];

    try {
      final contents = await file.readAsString(encoding: utf8);
      final lines = contents.split('\n');

      // Skip header row if present
      final startIndex = hasHeader(lines) ? 1 : 0;

      for (int i = startIndex; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          final transaction = _parseCSVLine(line, i);
          if (transaction != null) {
            transactions.add(transaction);
          }
        } catch (e) {
          // Skip malformed lines
          continue;
        }
      }
    } catch (e) {
      throw Exception('Failed to parse CSV: $e');
    }

    return transactions;
  }

  /// Parse a single CSV line
  TransactionModel? _parseCSVLine(String line, int lineNumber) {
    final fields = parseCSVFields(line);

    if (fields.length < 3) return null;

    try {
      // Try to parse with flexible column detection
      final dateStr = fields[0].trim();
      final amountStr = fields[1].trim();
      final merchantStr = fields[2].trim();
      final descriptionStr = fields.length > 3 ? fields[3].trim() : '';

      // Parse date
      final date = parseDate(dateStr);
      if (date == null) return null;

      // Parse amount
      final amount = parseAmount(amountStr);
      if (amount == null) return null;

      return TransactionModel(
        id:
            DateTime.now().millisecondsSinceEpoch.toString() +
            lineNumber.toString(),
        timestamp: date.millisecondsSinceEpoch,
        amount: amount,
        currency: 'INR',
        description: descriptionStr.isNotEmpty ? descriptionStr : merchantStr,
        credit: false,
        merchant: merchantStr,
        paymentMethod: 'Unknown',
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse CSV fields handling quoted values
  List<String> parseCSVFields(String line) {
    final fields = <String>[];
    var currentField = StringBuffer();
    var insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if (char == ',' && !insideQuotes) {
        fields.add(currentField.toString());
        currentField.clear();
      } else {
        currentField.write(char);
      }
    }

    fields.add(currentField.toString());
    return fields;
  }

  /// Check if CSV has header row
  bool hasHeader(List<String> lines) {
    if (lines.isEmpty) return false;

    final firstLine = lines[0].toLowerCase();
    final headerKeywords = [
      'date',
      'time',
      'amount',
      'merchant',
      'description',
      'category',
      'type',
    ];

    return headerKeywords.any((keyword) => firstLine.contains(keyword));
  }

  /// Parse date from various formats
  DateTime? parseDate(String dateStr) {
    // Try common formats
    final formats = [
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'), // 2024-01-15
      RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'), // 15-01-2024
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'), // 15/01/2024
      RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})'), // 2024/01/15
    ];

    for (var format in formats) {
      final match = format.firstMatch(dateStr);
      if (match != null && match.groupCount >= 3) {
        try {
          final groups = match.groups([1, 2, 3]);
          if (groups.length == 3) {
            final first = int.parse(groups[0]!);
            final second = int.parse(groups[1]!);
            final third = int.parse(groups[2]!);

            // Detect format based on ranges
            if (first > 31) {
              // first is year (YYYY-MM-DD or YYYY/MM/DD)
              return DateTime(first, second, third);
            } else if (third > 31) {
              // third is year (DD-MM-YYYY or MM/DD/YYYY)
              return DateTime(third, first, second);
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  /// Parse amount from various formats
  double? parseAmount(String amountStr) {
    // Remove common currency symbols and whitespace
    var cleaned = amountStr
        .replaceAll(RegExp(r'[₹$€£]'), '')
        .replaceAll(',', '')
        .trim();

    try {
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }
}
