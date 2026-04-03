import 'package:test/test.dart';
import 'package:expense_ai_agent/services/local_ai_service.dart';
import 'package:expense_ai_agent/models/transaction.dart';

void main() {
  group('LocalAIService', () {
    late LocalAIService service;

    setUp(() {
      service = LocalAIService();
    });

    test('should return message for empty transactions', () {
      final insights = service.generateLocalInsights([]);

      expect(insights.length, greaterThan(0));
      expect(insights.first, contains('No transactions'));
    });

    test('should calculate daily average spending', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: now,
          amount: 500,
          currency: 'INR',
          description: 'Test 1',
          credit: false,
          merchant: 'Test Merchant 1',
          paymentMethod: 'Card',
        ),
        TransactionModel(
          id: '2',
          timestamp: now + (24 * 60 * 60 * 1000),
          amount: 600,
          currency: 'INR',
          description: 'Test 2',
          credit: false,
          merchant: 'Test Merchant 2',
          paymentMethod: 'Card',
        ),
      ];

      final insights = service.generateLocalInsights(transactions);
      expect(insights.length, greaterThan(0));
    });

    test('should generate spending insights', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: now,
          amount: 50,
          currency: 'INR',
          description: 'Coffee',
          credit: false,
          merchant: 'Cafe',
          paymentMethod: 'Card',
        ),
      ];

      final insights = service.generateLocalInsights(transactions);

      // Should contain daily spending insight
      expect(insights.first, contains('daily'));
    });

    test('should detect peak spending time', () {
      final baseTime = DateTime(2024, 1, 15, 10, 0, 0);
      final morningTx = TransactionModel(
        id: '1',
        timestamp: baseTime.millisecondsSinceEpoch,
        amount: 500,
        currency: 'INR',
        description: 'Morning',
        credit: false,
        merchant: 'Merchant',
        paymentMethod: 'Card',
      );

      final afternoonTx = TransactionModel(
        id: '2',
        timestamp: baseTime.add(Duration(hours: 6)).millisecondsSinceEpoch,
        amount: 1000,
        currency: 'INR',
        description: 'Afternoon',
        credit: false,
        merchant: 'Merchant',
        paymentMethod: 'Card',
      );

      final insights = service.generateLocalInsights([morningTx, afternoonTx]);

      // Should mention peak spending time
      expect(
        insights.any(
          (insight) => insight.contains('Peak') || insight.contains('spending'),
        ),
        isTrue,
      );
    });

    test('should detect merchant concentration', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final transactions = [
        // High concentration on Amazon
        for (int i = 0; i < 5; i++)
          TransactionModel(
            id: '$i',
            timestamp: now + (i * Duration(hours: 1).inMilliseconds),
            amount: 100,
            currency: 'INR',
            description: 'Amazon purchase $i',
            credit: false,
            merchant: 'Amazon',
            paymentMethod: 'Card',
          ),
        TransactionModel(
          id: '10',
          timestamp: now,
          amount: 50,
          currency: 'INR',
          description: 'Other',
          credit: false,
          merchant: 'Other Merchant',
          paymentMethod: 'Card',
        ),
      ];

      final insights = service.generateLocalInsights(transactions);

      // Should mention concentration
      expect(
        insights.any(
          (insight) =>
              insight.contains('concentration') || insight.contains('Amazon'),
        ),
        isTrue,
      );
    });

    test('should detect transaction anomalies', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final transactions = [
        TransactionModel(
          id: '1',
          timestamp: now,
          amount: 50,
          currency: 'INR',
          description: 'Normal',
          credit: false,
          merchant: 'Store',
          paymentMethod: 'Card',
        ),
        TransactionModel(
          id: '2',
          timestamp: now + Duration(hours: 1).inMilliseconds,
          amount: 100,
          currency: 'INR',
          description: 'Normal',
          credit: false,
          merchant: 'Store',
          paymentMethod: 'Card',
        ),
        TransactionModel(
          id: '3',
          timestamp: now + Duration(hours: 2).inMilliseconds,
          amount: 10000,
          currency: 'INR',
          description: 'Unusual large transaction',
          credit: false,
          merchant: 'Store',
          paymentMethod: 'Card',
        ),
      ];

      final insights = service.generateLocalInsights(transactions);

      // Should detect the anomaly
      expect(
        insights.any(
          (insight) => insight.contains('Unusual') || insight.contains('large'),
        ),
        isTrue,
      );
    });

    test('should detect savings opportunities', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final transactions = [
        // Multiple small transactions at same merchant
        for (int i = 0; i < 4; i++)
          TransactionModel(
            id: '$i',
            timestamp: now + (i * Duration(days: 1).inMilliseconds),
            amount: 50,
            currency: 'INR',
            description: 'Coffee',
            credit: false,
            merchant: 'Cafe',
            paymentMethod: 'Card',
          ),
      ];

      final insights = service.generateLocalInsights(transactions);

      // Should suggest savings opportunity
      expect(
        insights.any(
          (insight) =>
              insight.contains('Save') || insight.contains('opportunity'),
        ),
        isTrue,
      );
    });

    test('should generate multiple insights for complex spending', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final transactions = <TransactionModel>[];

      // Create diverse transactions
      for (int i = 0; i < 10; i++) {
        transactions.add(
          TransactionModel(
            id: '$i',
            timestamp: now + (i * Duration(hours: 2).inMilliseconds),
            amount: (i + 1) * 100,
            currency: 'INR',
            description: 'Transaction $i',
            credit: false,
            merchant: i % 2 == 0 ? 'Amazon' : 'Swiggy',
            paymentMethod: 'Card',
          ),
        );
      }

      final insights = service.generateLocalInsights(transactions);

      // Should generate multiple insights
      expect(insights.length, greaterThan(1));
    });
  });
}
