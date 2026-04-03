import 'package:test/test.dart';

import 'package:expense_ai_agent/services/chat_service.dart';

void main() {
  group('ChatService', () {
    late ChatService service;

    setUp(() {
      service = ChatService();
    });

    test('generates insight for high total spend', () {
      final messages = service.generateInsights(
        totalSpend: 6000,
        upiPercent: 30,
        repeatCount: 0,
        smallSpendCount: 0,
      );

      expect(messages.any((m) => m.contains('spent quite a bit')), true);
    });

    test('generates insight for low total spend', () {
      final messages = service.generateInsights(
        totalSpend: 2000,
        upiPercent: 30,
        repeatCount: 0,
        smallSpendCount: 0,
      );

      expect(messages.any((m) => m.contains('relatively controlled')), true);
    });

    test('generates insight for high UPI usage', () {
      final messages = service.generateInsights(
        totalSpend: 3000,
        upiPercent: 80,
        repeatCount: 0,
        smallSpendCount: 0,
      );

      expect(
        messages.any((m) => m.contains('Most of your spending is through UPI')),
        true,
      );
    });

    test('does not generate UPI insight for low usage', () {
      final messages = service.generateInsights(
        totalSpend: 3000,
        upiPercent: 50,
        repeatCount: 0,
        smallSpendCount: 0,
      );

      expect(
        messages.any((m) => m.contains('Most of your spending is through UPI')),
        false,
      );
    });

    test('generates insight for repeated transactions', () {
      final messages = service.generateInsights(
        totalSpend: 3000,
        upiPercent: 30,
        repeatCount: 5,
        smallSpendCount: 0,
      );

      expect(messages.any((m) => m.contains('repeated transactions')), true);
    });

    test('does not generate repeat insight for low count', () {
      final messages = service.generateInsights(
        totalSpend: 3000,
        upiPercent: 30,
        repeatCount: 1,
        smallSpendCount: 0,
      );

      expect(messages.any((m) => m.contains('repeated transactions')), false);
    });

    test('generates insight for high small spend count', () {
      final messages = service.generateInsights(
        totalSpend: 3000,
        upiPercent: 30,
        repeatCount: 0,
        smallSpendCount: 15,
      );

      expect(
        messages.any((m) => m.contains('Many small expenses are adding up')),
        true,
      );
    });

    test('does not generate small spend insight for low count', () {
      final messages = service.generateInsights(
        totalSpend: 3000,
        upiPercent: 30,
        repeatCount: 0,
        smallSpendCount: 5,
      );

      expect(
        messages.any((m) => m.contains('Many small expenses are adding up')),
        false,
      );
    });

    test('generates multiple insights simultaneously', () {
      final messages = service.generateInsights(
        totalSpend: 6000,
        upiPercent: 80,
        repeatCount: 5,
        smallSpendCount: 15,
      );

      expect(messages.length, greaterThan(1));
      expect(messages.any((m) => m.contains('spent quite a bit')), true);
      expect(
        messages.any((m) => m.contains('Most of your spending is through UPI')),
        true,
      );
      expect(messages.any((m) => m.contains('repeated transactions')), true);
      expect(
        messages.any((m) => m.contains('Many small expenses are adding up')),
        true,
      );
    });

    test('generates only spending insight for minimal metrics', () {
      final messages = service.generateInsights(
        totalSpend: 1000,
        upiPercent: 30,
        repeatCount: 0,
        smallSpendCount: 0,
      );

      expect(messages.any((m) => m.contains('relatively controlled')), true);
    });

    test('handles zero total spend', () {
      final messages = service.generateInsights(
        totalSpend: 0,
        upiPercent: 0,
        repeatCount: 0,
        smallSpendCount: 0,
      );

      expect(messages.isNotEmpty, true);
    });

    test('handles 100% UPI usage', () {
      final messages = service.generateInsights(
        totalSpend: 3000,
        upiPercent: 100,
        repeatCount: 0,
        smallSpendCount: 0,
      );

      expect(
        messages.any((m) => m.contains('Most of your spending is through UPI')),
        true,
      );
    });

    test('handles exactly threshold values', () {
      final messages = service.generateInsights(
        totalSpend: 5000,
        upiPercent: 70,
        repeatCount: 2,
        smallSpendCount: 10,
      );

      expect(messages.isNotEmpty, true);
    });

    test('handles high spend with single repeat', () {
      final messages = service.generateInsights(
        totalSpend: 6000,
        upiPercent: 30,
        repeatCount: 1,
        smallSpendCount: 0,
      );

      expect(messages.any((m) => m.contains('spent quite a bit')), true);
      expect(messages.any((m) => m.contains('repeated transactions')), false);
    });

    test('handles all metrics at boundary', () {
      final messages = service.generateInsights(
        totalSpend: 5001,
        upiPercent: 71,
        repeatCount: 3,
        smallSpendCount: 11,
      );

      // Should have multiple insights triggered
      expect(messages.length, greaterThan(1));
    });

    test('generates insights independently', () {
      final messages1 = service.generateInsights(
        totalSpend: 10000,
        upiPercent: 30,
        repeatCount: 0,
        smallSpendCount: 0,
      );

      final messages2 = service.generateInsights(
        totalSpend: 1000,
        upiPercent: 30,
        repeatCount: 0,
        smallSpendCount: 0,
      );

      // Both should have at least the spending message but different content
      expect(messages1.isNotEmpty, true);
      expect(messages2.isNotEmpty, true);
      expect(messages1[0], isNot(messages2[0]));
    });

    test('handles edge case with max values', () {
      final messages = service.generateInsights(
        totalSpend: 999999999,
        upiPercent: 100,
        repeatCount: 999,
        smallSpendCount: 999,
      );

      expect(messages.length, greaterThan(1));
    });

    test('combined high metrics generate comprehensive insights', () {
      final messages = service.generateInsights(
        totalSpend: 10000,
        upiPercent: 95,
        repeatCount: 10,
        smallSpendCount: 50,
      );

      final messageString = messages.join(' ');
      expect(messageString.contains('spent quite a bit'), true);
      expect(
        messageString.contains('Most of your spending is through UPI'),
        true,
      );
      expect(messageString.contains('repeated transactions'), true);
      expect(messageString.contains('Many small expenses'), true);
    });
  });
}
