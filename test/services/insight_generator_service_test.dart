import 'package:test/test.dart';

import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/services/insight_generator_service.dart';

void main() {
  group('InsightGeneratorService', () {
    late InsightGeneratorService service;

    setUp(() {
      service = InsightGeneratorService();
    });

    test('returns no transaction message for empty list', () {
      final insights = service.generateInsights([]);
      expect(insights.length, 1);
      expect(insights[0], 'No transactions to analyze');
    });

    test('includes total spending insight', () {
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: 0,
          amount: 6000.0,
          currency: 'INR',
          description: 'Test',
          credit: false,
          merchant: 'Test',
        ),
      ];

      final insights = service.generateInsights(transactions);
      expect(insights.any((s) => s.contains('Total spending')), true);
    });

    test('includes top merchant insight', () {
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: 0,
          amount: 1000.0,
          currency: 'INR',
          description: 'Test1',
          credit: false,
          merchant: 'Netflix',
        ),
        TransactionModel(
          id: '2',
          timestamp: 0,
          amount: 500.0,
          currency: 'INR',
          description: 'Test2',
          credit: false,
          merchant: 'Swiggy',
        ),
      ];

      final insights = service.generateInsights(transactions);
      expect(
        insights.any(
          (s) => s.contains('Top merchant') && s.contains('Netflix'),
        ),
        true,
      );
    });

    test('detects spending trend increasing', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final transactions = [
        // First half - lower spending
        TransactionModel(
          id: '1',
          timestamp: now,
          amount: 100.0,
          currency: 'INR',
          description: 'Test1',
          credit: false,
          merchant: 'Test1',
        ),
        TransactionModel(
          id: '2',
          timestamp: now + 1000,
          amount: 100.0,
          currency: 'INR',
          description: 'Test2',
          credit: false,
          merchant: 'Test2',
        ),
        // Second half - higher spending
        TransactionModel(
          id: '3',
          timestamp: now + 2000,
          amount: 500.0,
          currency: 'INR',
          description: 'Test3',
          credit: false,
          merchant: 'Test3',
        ),
        TransactionModel(
          id: '4',
          timestamp: now + 3000,
          amount: 500.0,
          currency: 'INR',
          description: 'Test4',
          credit: false,
          merchant: 'Test4',
        ),
      ];

      final insights = service.generateInsights(transactions);
      expect(insights.any((s) => s.contains('Increasing')), true);
    });

    test('detects spending trend decreasing', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final transactions = [
        // First half - higher spending
        TransactionModel(
          id: '1',
          timestamp: now,
          amount: 500.0,
          currency: 'INR',
          description: 'Test1',
          credit: false,
          merchant: 'Test1',
        ),
        TransactionModel(
          id: '2',
          timestamp: now + 1000,
          amount: 500.0,
          currency: 'INR',
          description: 'Test2',
          credit: false,
          merchant: 'Test2',
        ),
        // Second half - lower spending
        TransactionModel(
          id: '3',
          timestamp: now + 2000,
          amount: 100.0,
          currency: 'INR',
          description: 'Test3',
          credit: false,
          merchant: 'Test3',
        ),
        TransactionModel(
          id: '4',
          timestamp: now + 3000,
          amount: 100.0,
          currency: 'INR',
          description: 'Test4',
          credit: false,
          merchant: 'Test4',
        ),
      ];

      final insights = service.generateInsights(transactions);
      expect(insights.any((s) => s.contains('Decreasing')), true);
    });

    test('identifies recurring transactions', () {
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: 0,
          amount: 99.0,
          currency: 'INR',
          description: 'Netflix1',
          credit: false,
          merchant: 'Netflix',
        ),
        TransactionModel(
          id: '2',
          timestamp: 1000,
          amount: 99.0,
          currency: 'INR',
          description: 'Netflix2',
          credit: false,
          merchant: 'Netflix',
        ),
        TransactionModel(
          id: '3',
          timestamp: 2000,
          amount: 99.0,
          currency: 'INR',
          description: 'Netflix3',
          credit: false,
          merchant: 'Netflix',
        ),
      ];

      final insights = service.generateInsights(transactions);
      expect(
        insights.any((s) => s.contains('Recurring transactions identified')),
        true,
      );
    });

    test('includes multiple insights when applicable', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: now,
          amount: 100.0,
          currency: 'INR',
          description: 'Test1',
          credit: false,
          merchant: 'Netflix',
        ),
        TransactionModel(
          id: '2',
          timestamp: now + 1000,
          amount: 100.0,
          currency: 'INR',
          description: 'Test2',
          credit: false,
          merchant: 'Netflix',
        ),
        TransactionModel(
          id: '3',
          timestamp: now + 2000,
          amount: 100.0,
          currency: 'INR',
          description: 'Test3',
          credit: false,
          merchant: 'Netflix',
        ),
      ];

      final insights = service.generateInsights(transactions);
      expect(insights.length, greaterThan(1));
    });

    test('handles transactions with null merchant', () {
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: 0,
          amount: 100.0,
          currency: 'INR',
          description: 'Test',
          credit: false,
          merchant: null,
        ),
      ];

      final insights = service.generateInsights(transactions);
      expect(insights.length, greaterThan(0));
    });

    test('correctly calculates total spending with decimals', () {
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: 0,
          amount: 99.99,
          currency: 'INR',
          description: 'Test1',
          credit: false,
          merchant: 'Test1',
        ),
        TransactionModel(
          id: '2',
          timestamp: 0,
          amount: 100.01,
          currency: 'INR',
          description: 'Test2',
          credit: false,
          merchant: 'Test2',
        ),
      ];

      final insights = service.generateInsights(transactions);
      expect(insights.any((s) => s.contains('200.00')), true);
    });

    test('handles single transaction correctly', () {
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: 0,
          amount: 500.0,
          currency: 'INR',
          description: 'Test',
          credit: false,
          merchant: 'TestMerchant',
        ),
      ];

      final insights = service.generateInsights(transactions);
      expect(insights.length, greaterThan(0));
      expect(insights.any((s) => s.contains('500.00')), true);
    });

    test('handles two transactions for trend detection', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: now,
          amount: 100.0,
          currency: 'INR',
          description: 'Test1',
          credit: false,
          merchant: 'Test1',
        ),
        TransactionModel(
          id: '2',
          timestamp: now + 1000,
          amount: 200.0,
          currency: 'INR',
          description: 'Test2',
          credit: false,
          merchant: 'Test2',
        ),
      ];

      final insights = service.generateInsights(transactions);
      expect(insights.length, greaterThan(0));
    });

    test('identifies dominant merchant from multiple merchants', () {
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: 0,
          amount: 1000.0,
          currency: 'INR',
          description: 'Test1',
          credit: false,
          merchant: 'Netflix',
        ),
        TransactionModel(
          id: '2',
          timestamp: 0,
          amount: 200.0,
          currency: 'INR',
          description: 'Test2',
          credit: false,
          merchant: 'Swiggy',
        ),
        TransactionModel(
          id: '3',
          timestamp: 0,
          amount: 50.0,
          currency: 'INR',
          description: 'Test3',
          credit: false,
          merchant: 'Cafe',
        ),
      ];

      final insights = service.generateInsights(transactions);
      expect(insights.any((s) => s.contains('Netflix')), true);
    });

    test('handles large amount transactions', () {
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: 0,
          amount: 999999.99,
          currency: 'INR',
          description: 'Test',
          credit: false,
          merchant: 'Test',
        ),
      ];

      final insights = service.generateInsights(transactions);
      expect(insights.any((s) => s.contains('999999.99')), true);
    });

    test('counts multiple recurring merchants', () {
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: 0,
          amount: 100.0,
          currency: 'INR',
          description: 'Netflix1',
          credit: false,
          merchant: 'Netflix',
        ),
        TransactionModel(
          id: '2',
          timestamp: 0,
          amount: 100.0,
          currency: 'INR',
          description: 'Netflix2',
          credit: false,
          merchant: 'Netflix',
        ),
        TransactionModel(
          id: '5',
          timestamp: 0,
          amount: 100.0,
          currency: 'INR',
          description: 'Netflix3',
          credit: false,
          merchant: 'Netflix',
        ),
        TransactionModel(
          id: '3',
          timestamp: 0,
          amount: 50.0,
          currency: 'INR',
          description: 'Spotify1',
          credit: false,
          merchant: 'Spotify',
        ),
        TransactionModel(
          id: '4',
          timestamp: 0,
          amount: 50.0,
          currency: 'INR',
          description: 'Spotify2',
          credit: false,
          merchant: 'Spotify',
        ),
      ];

      final insights = service.generateInsights(transactions);
      final recurringMessage = insights.firstWhere(
        (s) => s.contains('Recurring'),
        orElse: () => '',
      );
      expect(recurringMessage.isNotEmpty, true);
    });
  });
}
