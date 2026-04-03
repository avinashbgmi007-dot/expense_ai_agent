import 'package:test/test.dart';

import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/services/leak_detection_service.dart';

void main() {
  group('LeakDetectionService', () {
    late LeakDetectionService service;

    setUp(() {
      service = LeakDetectionService();
    });

    test('detects recurring transactions', () {
      final now = DateTime.now();
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: now.millisecondsSinceEpoch,
          amount: 99,
          currency: 'INR',
          description: 'Netflix subscription',
          credit: false,
          merchant: 'Netflix',
        ),
        TransactionModel(
          id: '2',
          timestamp: now.add(const Duration(days: 30)).millisecondsSinceEpoch,
          amount: 99,
          currency: 'INR',
          description: 'Netflix subscription',
          credit: false,
          merchant: 'Netflix',
        ),
        TransactionModel(
          id: '3',
          timestamp: now.add(const Duration(days: 60)).millisecondsSinceEpoch,
          amount: 99,
          currency: 'INR',
          description: 'Netflix subscription',
          credit: false,
          merchant: 'Netflix',
        ),
      ];

      final recurring = service.detectRecurringTransactions(transactions);
      expect(recurring.length, greaterThanOrEqualTo(2));
    });

    test('detects small drain transactions', () {
      final now = DateTime.now();
      final transactions = [
        // Small transactions
        TransactionModel(
          id: '1',
          timestamp: now.millisecondsSinceEpoch,
          amount: 45,
          currency: 'INR',
          description: 'Coffee',
          credit: false,
          merchant: 'Cafe',
        ),
        TransactionModel(
          id: '2',
          timestamp: now.add(const Duration(days: 1)).millisecondsSinceEpoch,
          amount: 50,
          currency: 'INR',
          description: 'Snacks',
          credit: false,
          merchant: 'Shop',
        ),
        // Large transaction (should not be included)
        TransactionModel(
          id: '3',
          timestamp: now.add(const Duration(days: 2)).millisecondsSinceEpoch,
          amount: 1000,
          currency: 'INR',
          description: 'Flight',
          credit: false,
          merchant: 'Airlines',
        ),
      ];

      final small = service.detectSmallDrains(transactions, threshold: 100);
      expect(small.length, 2);
    });

    test('calculates monthly leak potential', () {
      final now = DateTime.now();
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: now.millisecondsSinceEpoch,
          amount: 299,
          currency: 'INR',
          description: 'Web hosting',
          credit: false,
          merchant: 'Bluehost',
        ),
        TransactionModel(
          id: '2',
          timestamp: now.add(const Duration(days: 30)).millisecondsSinceEpoch,
          amount: 299,
          currency: 'INR',
          description: 'Web hosting',
          credit: false,
          merchant: 'Bluehost',
        ),
      ];

      final leaks = service.calculateMonthlyLeakPotential(transactions);
      expect(leaks['total'], greaterThan(0));
      expect(leaks['subscriptions'], isNotNull);
    });

    test('suggests leak reduction actions', () {
      final now = DateTime.now();
      final transactions = [
        // High recurring charge
        TransactionModel(
          id: '1',
          timestamp: now.millisecondsSinceEpoch,
          amount: 500,
          currency: 'INR',
          description: 'Premium subscription',
          credit: false,
          merchant: 'Prime Video',
        ),
        TransactionModel(
          id: '2',
          timestamp: now.add(const Duration(days: 30)).millisecondsSinceEpoch,
          amount: 500,
          currency: 'INR',
          description: 'Premium subscription',
          credit: false,
          merchant: 'Prime Video',
        ),
        // Small drain transactions
        TransactionModel(
          id: '3',
          timestamp: now.millisecondsSinceEpoch,
          amount: 30,
          currency: 'INR',
          description: 'Coffee',
          credit: false,
          merchant: 'Cafe',
        ),
        TransactionModel(
          id: '4',
          timestamp: now.add(const Duration(days: 1)).millisecondsSinceEpoch,
          amount: 35,
          currency: 'INR',
          description: 'Snack',
          credit: false,
          merchant: 'Shop',
        ),
      ];

      final suggestions = service.suggestLeakReductionActions(transactions);
      expect(suggestions.isNotEmpty, true);
    });

    test('infers frequency from timestamps', () {
      final now = DateTime.now();

      // Daily pattern
      final dailyTimestamps = [
        now.millisecondsSinceEpoch,
        now.add(const Duration(days: 1)).millisecondsSinceEpoch,
        now.add(const Duration(days: 2)).millisecondsSinceEpoch,
      ];
      final dailyFreq = service.inferFrequency(dailyTimestamps);
      expect(dailyFreq, 'daily');

      // Monthly pattern
      final monthlyTimestamps = [
        now.millisecondsSinceEpoch,
        now.add(const Duration(days: 30)).millisecondsSinceEpoch,
        now.add(const Duration(days: 60)).millisecondsSinceEpoch,
      ];
      final monthlyFreq = service.inferFrequency(monthlyTimestamps);
      expect(monthlyFreq, 'monthly');
    });
  });
}
