import 'dart:io';
import 'package:expense_ai_agent/services/ai_categorization_service.dart';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final svc = AICategorizationService();
  final parser = PDFParserService();

  print('Running comprehensive categorization test...');

  // Parse the actual PDF files to get real transactions
  try {
    // Test HDFC PDF
    final hdfcFile = File('HDFC-till 24.pdf');
    if (await hdfcFile.exists()) {
      print('Testing HDFC PDF transactions...');
      final transactions = await parser.parsePDF(hdfcFile);
      print('Found ${transactions.length} transactions in HDFC PDF');

      int correct = 0;
      int total = transactions.length;

      for (int i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final category = await svc.categorizeTransaction(transaction);
        print(
          'Transaction ${i + 1}: ${transaction.merchant} - Category: $category',
        );
      }
    } else {
      print('HDFC PDF file not found');
    }

    // Test Union Bank PDF
    final unionFile = File('Union_Bank.pdf');
    if (await unionFile.exists()) {
      print('Testing Union Bank PDF transactions...');
      final transactions = await parser.parsePDF(unionFile);
      print('Found ${transactions.length} transactions in Union Bank PDF');

      int correct = 0;
      int total = transactions.length;

      for (int i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final category = await svc.categorizeTransaction(transaction);
        print(
          'Transaction ${i + 1}: ${transaction.merchant} - Category: $category',
        );
      }
    } else {
      print('Union Bank PDF file not found');
    }
  } catch (e) {
    print('Error: $e');
  }
}
