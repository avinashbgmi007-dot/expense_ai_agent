import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/services/database_service.dart';

void main() {
  group('DatabaseService', () {
    late DatabaseService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = DatabaseService();
      await service.initialize();
    });

    test('initializes successfully', () async {
      final newService = DatabaseService();
      await newService.initialize();
      // Should not throw
    });

    test('getTransactions returns empty list initially', () {
      final transactions = service.getTransactions();
      expect(transactions, isEmpty);
    });

    test('insertTransaction adds a transaction', () async {
      final transaction = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 100.0,
        currency: 'INR',
        description: 'Test',
        credit: false,
        merchant: 'Test',
      );

      await service.insertTransaction(transaction);
      final transactions = service.getTransactions();

      expect(transactions.length, 1);
      expect(transactions[0].id, '1');
      expect(transactions[0].amount, 100.0);
    });

    test('insertTransaction adds multiple transactions', () async {
      final t1 = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 100.0,
        currency: 'INR',
        description: 'Test1',
        credit: false,
        merchant: 'Test1',
      );

      final t2 = TransactionModel(
        id: '2',
        timestamp: 2000,
        amount: 200.0,
        currency: 'INR',
        description: 'Test2',
        credit: false,
        merchant: 'Test2',
      );

      await service.insertTransaction(t1);
      await service.insertTransaction(t2);
      final transactions = service.getTransactions();

      expect(transactions.length, 2);
      expect(transactions[0].id, '1');
      expect(transactions[1].id, '2');
    });

    test('updateTransaction modifies existing transaction', () async {
      final t1 = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 100.0,
        currency: 'INR',
        description: 'Original',
        credit: false,
        merchant: 'Test',
      );

      await service.insertTransaction(t1);

      final updated = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 150.0,
        currency: 'INR',
        description: 'Updated',
        credit: false,
        merchant: 'Test',
      );

      await service.updateTransaction(updated);
      final transactions = service.getTransactions();

      expect(transactions.length, 1);
      expect(transactions[0].amount, 150.0);
      expect(transactions[0].description, 'Updated');
    });

    test('updateTransaction preserves order', () async {
      final t1 = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 100.0,
        currency: 'INR',
        description: 'Test1',
        credit: false,
        merchant: 'Test1',
      );

      final t2 = TransactionModel(
        id: '2',
        timestamp: 2000,
        amount: 200.0,
        currency: 'INR',
        description: 'Test2',
        credit: false,
        merchant: 'Test2',
      );

      await service.insertTransaction(t1);
      await service.insertTransaction(t2);

      final updated = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 150.0,
        currency: 'INR',
        description: 'Updated',
        credit: false,
        merchant: 'Test1',
      );

      await service.updateTransaction(updated);
      final transactions = service.getTransactions();

      expect(transactions[0].id, '1');
      expect(transactions[1].id, '2');
    });

    test('updateTransaction does nothing for non-existent id', () async {
      final t1 = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 100.0,
        currency: 'INR',
        description: 'Test',
        credit: false,
        merchant: 'Test',
      );

      await service.insertTransaction(t1);

      final nonExistent = TransactionModel(
        id: '999',
        timestamp: 1000,
        amount: 150.0,
        currency: 'INR',
        description: 'Updated',
        credit: false,
        merchant: 'Test',
      );

      await service.updateTransaction(nonExistent);
      final transactions = service.getTransactions();

      expect(transactions.length, 1);
      expect(transactions[0].id, '1');
      expect(transactions[0].amount, 100.0);
    });

    test('deleteTransaction removes transaction', () async {
      final t1 = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 100.0,
        currency: 'INR',
        description: 'Test',
        credit: false,
        merchant: 'Test',
      );

      await service.insertTransaction(t1);
      await service.deleteTransaction('1');

      final transactions = service.getTransactions();
      expect(transactions, isEmpty);
    });

    test('deleteTransaction preserves other transactions', () async {
      final t1 = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 100.0,
        currency: 'INR',
        description: 'Test1',
        credit: false,
        merchant: 'Test1',
      );

      final t2 = TransactionModel(
        id: '2',
        timestamp: 2000,
        amount: 200.0,
        currency: 'INR',
        description: 'Test2',
        credit: false,
        merchant: 'Test2',
      );

      await service.insertTransaction(t1);
      await service.insertTransaction(t2);
      await service.deleteTransaction('1');

      final transactions = service.getTransactions();
      expect(transactions.length, 1);
      expect(transactions[0].id, '2');
    });

    test('deleteTransaction does nothing for non-existent id', () async {
      final t1 = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 100.0,
        currency: 'INR',
        description: 'Test',
        credit: false,
        merchant: 'Test',
      );

      await service.insertTransaction(t1);
      await service.deleteTransaction('999');

      final transactions = service.getTransactions();
      expect(transactions.length, 1);
      expect(transactions[0].id, '1');
    });

    test('persists transactions across service instances', () async {
      final t1 = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 100.0,
        currency: 'INR',
        description: 'Test',
        credit: false,
        merchant: 'Test',
      );

      await service.insertTransaction(t1);

      // Create new service instance
      final service2 = DatabaseService();
      await service2.initialize();

      final transactions = service2.getTransactions();
      expect(transactions.length, 1);
      expect(transactions[0].id, '1');
    });

    test('handles transaction with all fields', () async {
      final transaction = TransactionModel(
        id: '1',
        timestamp: 1234567890,
        amount: 999.99,
        currency: 'INR',
        description: 'Full test transaction',
        credit: true,
        merchant: 'Premium Merchant',
        paymentMethod: 'UPI',
      );

      await service.insertTransaction(transaction);
      final transactions = service.getTransactions();

      expect(transactions[0].id, '1');
      expect(transactions[0].timestamp, 1234567890);
      expect(transactions[0].amount, 999.99);
      expect(transactions[0].currency, 'INR');
      expect(transactions[0].description, 'Full test transaction');
      expect(transactions[0].credit, true);
      expect(transactions[0].merchant, 'Premium Merchant');
      expect(transactions[0].paymentMethod, 'UPI');
    });

    test('handles transaction with null optional fields', () async {
      final transaction = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 100.0,
        currency: 'INR',
        description: 'Test',
        credit: false,
        merchant: null,
        paymentMethod: null,
      );

      await service.insertTransaction(transaction);
      final transactions = service.getTransactions();

      expect(transactions[0].merchant, isNull);
      expect(transactions[0].paymentMethod, isNull);
    });

    test('handles special characters in description', () async {
      final transaction = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 100.0,
        currency: 'INR',
        description: 'Test@#\$%^&*()',
        credit: false,
        merchant: 'Test_Brand',
      );

      await service.insertTransaction(transaction);
      final transactions = service.getTransactions();

      expect(transactions[0].description, 'Test@#\$%^&*()');
      expect(transactions[0].merchant, 'Test_Brand');
    });

    test('handles unicode characters', () async {
      final transaction = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 100.0,
        currency: 'INR',
        description: 'रेस्टोरेंट',
        credit: false,
        merchant: '北京',
      );

      await service.insertTransaction(transaction);
      final transactions = service.getTransactions();

      expect(transactions[0].description, 'रेस्टोरेंट');
      expect(transactions[0].merchant, '北京');
    });

    test('handles large bulk of transactions', () async {
      for (int i = 0; i < 100; i++) {
        final transaction = TransactionModel(
          id: '$i',
          timestamp: 1000 + i,
          amount: (i + 1).toDouble(),
          currency: 'INR',
          description: 'Transaction $i',
          credit: i % 2 == 0,
          merchant: 'Merchant ${i % 5}',
        );
        await service.insertTransaction(transaction);
      }

      final transactions = service.getTransactions();
      expect(transactions.length, 100);
    });

    test('handles zero amount transactions', () async {
      final transaction = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: 0.0,
        currency: 'INR',
        description: 'Test',
        credit: false,
        merchant: 'Test',
      );

      await service.insertTransaction(transaction);
      final transactions = service.getTransactions();

      expect(transactions[0].amount, 0.0);
    });

    test('handles negative amounts', () async {
      final transaction = TransactionModel(
        id: '1',
        timestamp: 1000,
        amount: -100.0,
        currency: 'INR',
        description: 'Refund',
        credit: false,
        merchant: 'Test',
      );

      await service.insertTransaction(transaction);
      final transactions = service.getTransactions();

      expect(transactions[0].amount, -100.0);
    });
  });
}
