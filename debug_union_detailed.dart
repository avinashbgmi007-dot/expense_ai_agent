import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';
import 'package:expense_ai_agent/models/transaction.dart';

void main() async {
  final service = PDFParserService();

  // Test Union Bank PDF
  print('Debugging Union Bank detailed parsing...');
  final unionFile = File('Union_Bank.pdf');
  if (unionFile.existsSync()) {
    print('Union Bank PDF file exists: ${unionFile.path}');

    // Parse the PDF
    try {
      final transactions = await service.parsePDF(unionFile);
      print(
        'Successfully parsed ${transactions.length} transactions from Union Bank PDF',
      );

      // Print details of each transaction
      for (int i = 0; i < transactions.length; i++) {
        final txn = transactions[i];
        print('Transaction ${i + 1}:');
        print('  ID: ${txn.id}');
        print('  Amount: ₹${txn.amount}');
        print('  Merchant: ${txn.merchant}');
        print('  Description: ${txn.description}');
        print('  Credit: ${txn.credit}');
        print('  Payment Method: ${txn.paymentMethod}');
        print('  Upload ID: ${txn.uploadId}');
        print('');
      }
    } catch (e) {
      print('Error parsing Union Bank PDF: $e');
    }
  } else {
    print('Union Bank PDF file not found');
  }
}
