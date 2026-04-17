import 'package:expense_ai_agent/services/ai_categorization_service.dart';

void main() {
  final svc = AICategorizationService();

  // Test cases from the actual bank statements
  print('Testing categorization accuracy...');

  // Test some known cases to check accuracy
  final testCases = [
    // Format: [merchant, description, isCredit, amount, expectedCategory]
    ['pasanna pragada', 'UPI-PAYMENT', false, 2000.0, 'transfers'],
    ['swiggy', 'UPI-P2M payment', false, 350.0, 'food'],
    ['capgemini', 'salary credit', true, 85000.0, 'income'],
    ['siri vallabh hospital', 'UPI payment', false, 15000.0, 'healthcare'],
    ['jio', 'prepaid recharge', false, 299.0, 'mobile'],
    ['cash', '', false, 500.0, 'transfers'],
    ['netflix', 'autopay charge', false, 649.0, 'subscriptions'],
  ];

  int correct = 0;
  int total = testCases.length;

  for (final testCase in testCases) {
    final result = svc.categorizeWithDescription(
      testCase[0] as String, // merchant
      testCase[1] as String, // description
      testCase[2] as bool, // isCredit
      testCase[3] as double, // amount
    );

    final expected = testCase[4] as String;
    if (result == expected) {
      correct++;
    }
    print(
      '${testCase[0]}: expected=$expected, got=$result, match=${result == expected}',
    );
  }

  final accuracy = (correct / total) * 100;
  print('Accuracy: ${accuracy.toStringAsFixed(2)}% ($correct/$total correct)');
}
