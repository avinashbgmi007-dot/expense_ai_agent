import 'package:test/test.dart';

import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/services/analyzer_service.dart';

void main() {
  group('AnalyzerService', () {
    late AnalyzerService service;

    setUp(() {
      service = AnalyzerService();
    });

    group('calculateTotalSpend', () {
      test('returns 0 for empty list', () {
        expect(service.calculateTotalSpend([]), 0);
      });

      test('calculates total for single transaction', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test',
            credit: false,
            merchant: 'Test',
          ),
        ];
        expect(service.calculateTotalSpend(transactions), 100.0);
      });

      test('calculates total for multiple transactions', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test1',
            credit: false,
            merchant: 'Merchant1',
          ),
          TransactionModel(
            id: '2',
            timestamp: 0,
            amount: 250.0,
            currency: 'INR',
            description: 'Test2',
            credit: false,
            merchant: 'Merchant2',
          ),
          TransactionModel(
            id: '3',
            timestamp: 0,
            amount: 150.0,
            currency: 'INR',
            description: 'Test3',
            credit: false,
            merchant: 'Merchant3',
          ),
        ];
        expect(service.calculateTotalSpend(transactions), 500.0);
      });

      test('handles decimal amounts correctly', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 99.99,
            currency: 'INR',
            description: 'Test1',
            credit: false,
            merchant: 'Merchant1',
          ),
          TransactionModel(
            id: '2',
            timestamp: 0,
            amount: 0.01,
            currency: 'INR',
            description: 'Test2',
            credit: false,
            merchant: 'Merchant2',
          ),
        ];
        expect(service.calculateTotalSpend(transactions), 100.0);
      });

      test('handles large amounts', () {
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
        expect(service.calculateTotalSpend(transactions), 999999.99);
      });
    });

    group('spendByMerchant', () {
      test('returns empty map for empty list', () {
        expect(service.spendByMerchant([]), isEmpty);
      });

      test('groups single merchant correctly', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test1',
            credit: false,
            merchant: 'Netflix',
          ),
          TransactionModel(
            id: '2',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test2',
            credit: false,
            merchant: 'Netflix',
          ),
        ];
        final result = service.spendByMerchant(transactions);
        expect(result['Netflix'], 200.0);
        expect(result.length, 1);
      });

      test('groups multiple merchants correctly', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test1',
            credit: false,
            merchant: 'Netflix',
          ),
          TransactionModel(
            id: '2',
            timestamp: 0,
            amount: 250.0,
            currency: 'INR',
            description: 'Test2',
            credit: false,
            merchant: 'Swiggy',
          ),
          TransactionModel(
            id: '3',
            timestamp: 0,
            amount: 150.0,
            currency: 'INR',
            description: 'Test3',
            credit: false,
            merchant: 'Netflix',
          ),
        ];
        final result = service.spendByMerchant(transactions);
        expect(result['Netflix'], 250.0);
        expect(result['Swiggy'], 250.0);
        expect(result.length, 2);
      });

      test('handles null merchants as Unknown', () {
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
        final result = service.spendByMerchant(transactions);
        expect(result['Unknown'], 100.0);
      });

      test(
        'accumulates amounts for same merchant across multiple transactions',
        () {
          final transactions = [
            TransactionModel(
              id: '1',
              timestamp: 0,
              amount: 50.0,
              currency: 'INR',
              description: 'Test1',
              credit: false,
              merchant: 'Cafe',
            ),
            TransactionModel(
              id: '2',
              timestamp: 0,
              amount: 30.0,
              currency: 'INR',
              description: 'Test2',
              credit: false,
              merchant: 'Cafe',
            ),
            TransactionModel(
              id: '3',
              timestamp: 0,
              amount: 20.0,
              currency: 'INR',
              description: 'Test3',
              credit: false,
              merchant: 'Cafe',
            ),
          ];
          final result = service.spendByMerchant(transactions);
          expect(result['Cafe'], 100.0);
        },
      );
    });

    group('detectRepeats', () {
      test('returns empty for no repeats', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test',
            credit: false,
            merchant: 'Netflix',
          ),
        ];
        expect(service.detectRepeats(transactions), isEmpty);
      });

      test('returns empty for exactly 2 repeats', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test1',
            credit: false,
            merchant: 'Netflix',
          ),
          TransactionModel(
            id: '2',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test2',
            credit: false,
            merchant: 'Netflix',
          ),
        ];
        expect(service.detectRepeats(transactions), isEmpty);
      });

      test('detects repeats occurring 3+ times', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 99.0,
            currency: 'INR',
            description: 'Test1',
            credit: false,
            merchant: 'Netflix',
          ),
          TransactionModel(
            id: '2',
            timestamp: 0,
            amount: 99.0,
            currency: 'INR',
            description: 'Test2',
            credit: false,
            merchant: 'Netflix',
          ),
          TransactionModel(
            id: '3',
            timestamp: 0,
            amount: 99.0,
            currency: 'INR',
            description: 'Test3',
            credit: false,
            merchant: 'Netflix',
          ),
        ];
        final result = service.detectRepeats(transactions);
        expect(result.length, 3);
      });

      test('matches both merchant and amount', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
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
            merchant: 'Netflix',
          ),
          TransactionModel(
            id: '3',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test3',
            credit: false,
            merchant: 'Netflix',
          ),
          TransactionModel(
            id: '4',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test4',
            credit: false,
            merchant: 'Netflix',
          ),
        ];
        final result = service.detectRepeats(transactions);
        expect(result.length, 3); // 3 x 100.0 transactions
      });
    });

    group('upiUsagePercentage', () {
      test('returns 0 for empty list', () {
        expect(service.upiUsagePercentage([]), 0);
      });

      test('returns 0 when no UPI transactions', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test',
            credit: false,
            merchant: 'Test',
            paymentMethod: 'Card',
          ),
        ];
        expect(service.upiUsagePercentage(transactions), 0);
      });

      test('returns 100 when all UPI transactions', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test1',
            credit: false,
            merchant: 'Test1',
            paymentMethod: 'UPI',
          ),
          TransactionModel(
            id: '2',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test2',
            credit: false,
            merchant: 'Test2',
            paymentMethod: 'UPI',
          ),
        ];
        expect(service.upiUsagePercentage(transactions), 100);
      });

      test('calculates percentage correctly for mixed payments', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test1',
            credit: false,
            merchant: 'Test1',
            paymentMethod: 'UPI',
          ),
          TransactionModel(
            id: '2',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test2',
            credit: false,
            merchant: 'Test2',
            paymentMethod: 'Card',
          ),
        ];
        expect(service.upiUsagePercentage(transactions), 50);
      });

      test('handles case-insensitive UPI check', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test1',
            credit: false,
            merchant: 'Test1',
            paymentMethod: 'upi',
          ),
          TransactionModel(
            id: '2',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test2',
            credit: false,
            merchant: 'Test2',
            paymentMethod: 'UPI',
          ),
        ];
        expect(service.upiUsagePercentage(transactions), 100);
      });
    });

    group('detectSmallLeaks', () {
      test('returns empty for no small transactions', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test',
            credit: false,
            merchant: 'Test',
          ),
        ];
        expect(service.detectSmallLeaks(transactions), isEmpty);
      });

      test('detects transactions below 50', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 49.0,
            currency: 'INR',
            description: 'Test',
            credit: false,
            merchant: 'Test',
          ),
        ];
        expect(service.detectSmallLeaks(transactions).length, 1);
      });

      test('excludes transactions at and above 50', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 50.0,
            currency: 'INR',
            description: 'Test1',
            credit: false,
            merchant: 'Test1',
          ),
          TransactionModel(
            id: '2',
            timestamp: 0,
            amount: 51.0,
            currency: 'INR',
            description: 'Test2',
            credit: false,
            merchant: 'Test2',
          ),
        ];
        expect(service.detectSmallLeaks(transactions), isEmpty);
      });

      test('identifies multiple small transactions', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 10.0,
            currency: 'INR',
            description: 'Test1',
            credit: false,
            merchant: 'Cafe',
          ),
          TransactionModel(
            id: '2',
            timestamp: 0,
            amount: 20.0,
            currency: 'INR',
            description: 'Test2',
            credit: false,
            merchant: 'Shop',
          ),
          TransactionModel(
            id: '3',
            timestamp: 0,
            amount: 30.0,
            currency: 'INR',
            description: 'Test3',
            credit: false,
            merchant: 'Store',
          ),
        ];
        expect(service.detectSmallLeaks(transactions).length, 3);
      });
    });

    group('calculateAverageDailySpend', () {
      test('returns 0 for empty list', () {
        expect(service.calculateAverageDailySpend([]), 0);
      });

      test('calculates average for single transaction', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test',
            credit: false,
            merchant: 'Test',
          ),
        ];
        expect(service.calculateAverageDailySpend(transactions), 100.0);
      });

      test('calculates average for multiple transactions', () {
        final transactions = [
          TransactionModel(
            id: '1',
            timestamp: 0,
            amount: 100.0,
            currency: 'INR',
            description: 'Test1',
            credit: false,
            merchant: 'Test1',
          ),
          TransactionModel(
            id: '2',
            timestamp: 0,
            amount: 200.0,
            currency: 'INR',
            description: 'Test2',
            credit: false,
            merchant: 'Test2',
          ),
          TransactionModel(
            id: '3',
            timestamp: 0,
            amount: 300.0,
            currency: 'INR',
            description: 'Test3',
            credit: false,
            merchant: 'Test3',
          ),
        ];
        expect(service.calculateAverageDailySpend(transactions), 200.0);
      });
    });

    group('calculateRunway', () {
      test('returns N/A for zero average', () {
        expect(service.calculateRunway(1000, 0), 'N/A');
      });

      test('calculates runway for valid inputs', () {
        final result = service.calculateRunway(3000, 100);
        expect(result, '30.0 months');
      });

      test('calculates runway with decimal result', () {
        final result = service.calculateRunway(1000, 333.33);
        final expected = '3.0 months';
        expect(result, expected);
      });

      test('handles large values', () {
        final result = service.calculateRunway(1000000, 1000);
        expect(result, '1000.0 months');
      });

      test('handles small runway', () {
        final result = service.calculateRunway(100, 1000);
        expect(result, '0.1 months');
      });
    });
  });
}
