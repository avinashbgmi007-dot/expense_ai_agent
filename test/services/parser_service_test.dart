import 'package:test/test.dart';

import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/services/parser_service.dart';

void main() {
  group('ParserService', () {
    late ParserService service;

    setUp(() {
      service = ParserService();
    });

    test('initializes successfully', () async {
      await service.initialize();
      // Should not throw
    });

    test('parses single transaction line correctly', () async {
      final rawText = '2024-01-15 100.50 Coffee Shop';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 1);
      expect(transactions[0].amount, 100.50);
      expect(transactions[0].description, 'Coffee Shop');
      expect(transactions[0].merchant, 'Coffee Shop');
      expect(transactions[0].currency, 'INR');
      expect(transactions[0].credit, false);
    });

    test('parses multiple transaction lines', () async {
      final rawText = '''
2024-01-15 100.50 Coffee Shop
2024-01-16 250.00 Swiggy Food
2024-01-17 45.75 Uber Ride
''';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 3);
      expect(transactions[0].amount, 100.50);
      expect(transactions[1].amount, 250.00);
      expect(transactions[2].amount, 45.75);
    });

    test('skips empty lines', () async {
      final rawText = '''
2024-01-15 100.50 Coffee Shop

2024-01-16 250.00 Swiggy Food

''';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 2);
    });

    test('ignores malformed lines', () async {
      final rawText = '''
2024-01-15 100.50 Coffee Shop
invalid line without proper format
2024-01-16 250.00 Swiggy Food
no amount here
''';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 2);
    });

    test('handles multi-word merchant names', () async {
      final rawText = '2024-01-15 150.00 Coffee House Downtown';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 1);
      expect(transactions[0].merchant, 'Coffee House Downtown');
      expect(transactions[0].description, 'Coffee House Downtown');
    });

    test('parses dates correctly', () async {
      final rawText = '2024-03-28 100.00 Test Merchant';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 1);
      final expectedDate = DateTime(2024, 3, 28);
      expect(transactions[0].timestamp, expectedDate.millisecondsSinceEpoch);
    });

    test('handles decimal amounts', () async {
      final rawText = '2024-01-15 99.99 Test';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 1);
      expect(transactions[0].amount, 99.99);
    });

    test('handles whole number amounts', () async {
      final rawText = '2024-01-15 500 Test';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 1);
      expect(transactions[0].amount, 500.0);
    });

    test('handles very small amounts', () async {
      final rawText = '2024-01-15 0.50 Test';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 1);
      expect(transactions[0].amount, 0.50);
    });

    test('handles large amounts', () async {
      final rawText = '2024-01-15 999999.99 Flight Booking';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 1);
      expect(transactions[0].amount, 999999.99);
    });

    test('rejects invalid date formats', () async {
      final rawText = '''
2024/01/15 100.50 Invalid Date Format
2024-01-15 100.50 Valid Date Format
invalid-date 100.50 Another Invalid
''';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 1);
      expect(transactions[0].merchant, 'Valid Date Format');
    });

    test('handles transactions with special characters in merchant', () async {
      final rawText = '2024-01-15 100.50 Café Costa & Co.';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 1);
      expect(transactions[0].merchant, 'Café Costa & Co.');
    });

    test('generates IDs for transactions', () async {
      final rawText = '''
2024-01-15 100.50 Coffee Shop
2024-01-16 250.00 Swiggy Food
''';

      final transactions = await service.parseStatement(rawText);

      expect(transactions[0].id, isNotEmpty);
      expect(transactions[1].id, isNotEmpty);
      // Note: IDs may be identical if parsed very quickly (same millisecond)
    });

    test('sets credit flag to false for parsed transactions', () async {
      final rawText = '2024-01-15 100.50 Coffee Shop';

      final transactions = await service.parseStatement(rawText);

      expect(transactions[0].credit, false);
    });

    test('sets currency to INR for all transactions', () async {
      final rawText = '2024-01-15 100.50 Coffee Shop';

      final transactions = await service.parseStatement(rawText);

      expect(transactions[0].currency, 'INR');
    });

    test('handles empty input', () async {
      final rawText = '';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 0);
    });

    test('handles whitespace-only input', () async {
      final rawText = '   \n   \n   ';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 0);
    });

    test('correctly parses transaction with extra whitespace', () async {
      final rawText = '  2024-01-15    100.50    Coffee Shop  ';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 1);
      expect(transactions[0].amount, 100.50);
    });

    test('batch process multiple statements', () async {
      final statements = [
        '2024-01-15 100.50 Coffee Shop',
        '2024-01-16 250.00 Swiggy Food',
        '2024-01-17 45.75 Uber Ride',
      ];

      final allTransactions = <TransactionModel>[];
      for (final statement in statements) {
        final transactions = await service.parseStatement(statement);
        allTransactions.addAll(transactions);
      }

      expect(allTransactions.length, 3);
    });

    test('parses statement with mixed valid and invalid entries', () async {
      final rawText = '''
2024-01-15 100.50 Coffee Shop
bad line
2024-01-16 250.00 Swiggy Food
another bad line
incomplete
2024-01-17 45.75 Uber Ride
''';

      final transactions = await service.parseStatement(rawText);

      expect(transactions.length, 3);
      expect(transactions[0].merchant, 'Coffee Shop');
      expect(transactions[1].merchant, 'Swiggy Food');
      expect(transactions[2].merchant, 'Uber Ride');
    });
  });
}
