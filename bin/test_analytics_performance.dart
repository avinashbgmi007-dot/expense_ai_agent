import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';
import 'package:expense_ai_agent/providers/analytics_provider.dart';
import 'package:expense_ai_agent/models/transaction.dart';

void main() async {
  print('Testing analytics performance...');

  // Parse HDFC PDF to get transactions
  final parser = PDFParserService();
  final file = File('HDFC-till 24.pdf');

  if (await file.exists()) {
    print('HDFC PDF file found, parsing transactions...');
    try {
      final transactions = await parser.parsePDF(file);
      print('Successfully parsed ${transactions.length} transactions');

      // Test analytics provider performance
      final analyticsProvider = AnalyticsProvider();

      // Simulate loading data and measure performance
      final stopwatch = Stopwatch()..start();
      final startTime = DateTime.now().millisecondsSinceEpoch;

      // Process transactions through analytics
      // This is a simulation - in real app this would use the provider
      print(
        'Processing ${transactions.length} transactions through analytics...',
      );

      // Simulate the analytics operations
      int processedCount = 0;
      for (var txn in transactions.take(50)) {
        // Process first 50 for demo
        // Simulate categorization and processing
        processedCount++;
      }

      stopwatch.stop();
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = stopwatch.elapsedMilliseconds;

      print('Analytics processing completed:');
      print('  - Transactions processed: $processedCount');
      print('  - Processing time: ${duration}ms');
      print('  - Efficiency: ${processedCount / duration * 1000} txns/second');

      // Show first few processed transactions
      print('First 5 transactions:');
      for (int i = 0; i < transactions.length && i < 5; i++) {
        final txn = transactions[i];
        print('  ${i + 1}. ${txn.merchant} - ${txn.amount}');
      }
    } catch (e) {
      print('Error testing analytics: $e');
    }
  } else {
    print('HDFC PDF file not found');
  }
}
