import '../models/transaction.dart';

/// Service to parse bank statements and extract transactions.
class ParserService {
  /// Parse raw text from bank statement and extract transaction data.
  Future<List<TransactionModel>> parseStatement(String rawText) async {
    final transactions = <TransactionModel>[];

    // Simple line-by-line parsing
    final lines = rawText.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Skip empty lines
      if (line.isEmpty) continue;

      try {
        // Try to parse as transaction (simple regex approach)
        final parsedTransaction = _parseTransactionLine(line);
        if (parsedTransaction != null) {
          transactions.add(parsedTransaction);
        }
      } catch (e) {
        // Skip lines that can't be parsed
        continue;
      }
    }

    return transactions;
  }

  /// Parse a single line to extract transaction data.
  TransactionModel? _parseTransactionLine(String line) {
    // Simple pattern: Date Amount Description
    // Example: 2024-01-15 100.50 Coffee Shop

    final parts = line.split(RegExp(r'\s+'));

    if (parts.length < 3) return null;

    try {
      // Try to parse date
      final dateStr = parts[0];
      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) return null;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final date = DateTime(year, month, day);
      final timestamp = date.millisecondsSinceEpoch;

      // Try to parse amount
      final amount = double.parse(parts[1]);

      // Rest is description
      final description = parts.sublist(2).join(' ');

      return TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: timestamp,
        amount: amount,
        currency: 'INR',
        description: description,
        credit: false,
        merchant: description,
        paymentMethod: 'Unknown',
      );
    } catch (e) {
      return null;
    }
  }

  /// Initialize parser (for future AI model integration).
  Future<void> initialize() async {
    // Placeholder for future AI model initialization
  }
}
