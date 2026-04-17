import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  print('Testing HDFC PDF parser...');

  final parser = PDFParserService();
  final file = File('HDFC-till 24.pdf');

  if (await file.exists()) {
    print('HDFC PDF file found, parsing transactions...');
    try {
      final transactions = await parser.parsePDF(file);
      print('Successfully parsed ${transactions.length} transactions');

      // Print first few transactions for verification
      for (int i = 0; i < transactions.length && i < 10; i++) {
        final txn = transactions[i];
        print(
          'Transaction ${i + 1}: ${txn.merchant} - ${txn.amount} - ${txn.description}',
        );
      }
    } catch (e) {
      print('Error parsing HDFC PDF: $e');
    }
  } else {
    print('HDFC PDF file not found');
  }
}
