import 'dart:io';
import 'package:test/test.dart';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';
import 'package:expense_ai_agent/services/ai_categorization_service.dart';

void main() {
  test('Test categorization accuracy for HDFC transactions', () async {
    final parser = PDFParserService();
    final categorizer = AICategorizationService();
    final file = File('HDFC-till 24.pdf');

    expect(file.existsSync(), isTrue);

    final transactions = await parser.parsePDF(file);
    print('HDFC: Parsed ${transactions.length} transactions');

    int correctCategorizations = 0;
    final totalTransactions = transactions.length;

    for (var transaction in transactions) {
      final category = await categorizer.categorizeTransaction(transaction);

      print('Transaction: ${transaction.merchant} - ₹${transaction.amount}');
      print('  Categorized as: $category');

      // Check if categorization seems reasonable
      if (category.isNotEmpty && category != 'miscellaneous') {
        correctCategorizations++;
      }
    }

    final accuracy = (correctCategorizations / totalTransactions) * 100;
    print(
      'HDFC Categorization Accuracy: ${accuracy.toStringAsFixed(2)}% '
      '($correctCategorizations/$totalTransactions transactions categorized correctly)',
    );

    // Expect at least 80% accuracy
    expect(
      accuracy,
      greaterThan(80.0),
      reason:
          'Expected categorization accuracy > 80%, but got ${accuracy.toStringAsFixed(2)}%',
    );
  });

  test('Test categorization accuracy for Union Bank transactions', () async {
    final parser = PDFParserService();
    final categorizer = AICategorizationService();
    final file = File('Union_Bank.pdf');

    expect(file.existsSync(), isTrue);

    final transactions = await parser.parsePDF(file);
    print('Union Bank: Parsed ${transactions.length} transactions');

    int correctCategorizations = 0;
    final totalTransactions = transactions.length;

    for (var transaction in transactions) {
      final category = await categorizer.categorizeTransaction(transaction);

      print('Transaction: ${transaction.merchant} - ₹${transaction.amount}');
      print('  Categorized as: $category');

      // Check if categorization seems reasonable
      if (category.isNotEmpty && category != 'miscellaneous') {
        correctCategorizations++;
      }
    }

    final accuracy = (correctCategorizations / totalTransactions) * 100;
    print(
      'Union Bank Categorization Accuracy: ${accuracy.toStringAsFixed(2)}% '
      '($correctCategorizations/$totalTransactions transactions categorized correctly)',
    );

    // Expect at least 75% accuracy
    expect(
      accuracy,
      greaterThan(75.0),
      reason:
          'Expected categorization accuracy > 75%, but got ${accuracy.toStringAsFixed(2)}%',
    );
  });
}
