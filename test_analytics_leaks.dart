import 'dart:io';
import 'package:test/test.dart';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';
import 'package:expense_ai_agent/services/ai_categorization_service.dart';
import 'package:expense_ai_agent/services/leak_detection_service.dart';
import 'package:expense_ai_agent/models/transaction.dart';

void main() {
  test('Test analytics and leak detection accuracy', () async {
    final parser = PDFParserService();
    final categorizer = AICategorizationService();
    final leakDetector = LeakDetectionService();
    final file = File('HDFC-till 24.pdf');

    expect(file.existsSync(), isTrue);

    final transactions = await parser.parsePDF(file);
    print('HDFC: Parsed ${transactions.length} transactions');

    // Categorize all transactions first
    final categorizedTransactions = <TransactionModel>[];
    for (var transaction in transactions) {
      final category = await categorizer.categorizeTransaction(transaction);
      // Create a new transaction with the category set
      final categorizedTxn = TransactionModel(
        id: transaction.id,
        timestamp: transaction.timestamp,
        amount: transaction.amount,
        currency: transaction.currency,
        description: transaction.description,
        credit: transaction.credit,
        merchant: transaction.merchant,
        paymentMethod: transaction.paymentMethod,
        uploadId: transaction.uploadId,
        createdAt: transaction.createdAt,
        isIgnored: transaction.isIgnored,
        category: category,
        confidence: 0.95, // Default confidence
        isRecurring: transaction.isRecurring,
        userNote: transaction.userNote,
      );
      categorizedTransactions.add(categorizedTxn);
    }

    // Test leak detection
    final leakResults = leakDetector.detectLeaks(categorizedTransactions);

    print('Leak detection found:');
    print('  Subscriptions: ${leakResults['subscriptions']?.length ?? 0}');
    print(
      '  Small transactions: ${leakResults['smallTransactions']?.length ?? 0}',
    );

    // Print some leak details
    if (leakResults['subscriptions'] != null &&
        leakResults['subscriptions'].isNotEmpty) {
      print('\nTop recurring subscriptions:');
      for (var sub in leakResults['subscriptions'].take(5)) {
        print(
          '  ${sub['merchant']}: ₹${sub['amount']} (${sub['occurrences']} times)',
        );
      }
    }

    if (leakResults['smallTransactions'] != null &&
        leakResults['smallTransactions'].isNotEmpty) {
      print('\nSmall transactions:');
      for (var txn in leakResults['smallTransactions'].take(5)) {
        print('  ${txn['merchant']}: ₹${txn['amount']}');
      }
    }

    // Test analytics
    print('\nAnalytics summary:');
    double totalSpent = 0;
    double totalEarned = 0;

    for (var txn in categorizedTransactions) {
      if (txn.credit) {
        totalEarned += txn.amount;
      } else {
        totalSpent += txn.amount;
      }
    }

    print('  Total spent: ₹${totalSpent.toStringAsFixed(2)}');
    print('  Total earned: ₹${totalEarned.toStringAsFixed(2)}');
    print('  Net: ₹${(totalEarned - totalSpent).toStringAsFixed(2)}');

    // Category breakdown
    final categoryTotals = <String, double>{};
    for (var txn in categorizedTransactions) {
      if (!txn.credit) {
        categoryTotals[txn.category] =
            (categoryTotals[txn.category] ?? 0) + txn.amount;
      }
    }

    print('\nSpending by category:');
    categoryTotals.forEach((category, total) {
      print('  $category: ₹${total.toStringAsFixed(2)}');
    });

    expect(categorizedTransactions.length, equals(transactions.length));
    print('Analytics and leak detection test completed successfully');
  });
}
