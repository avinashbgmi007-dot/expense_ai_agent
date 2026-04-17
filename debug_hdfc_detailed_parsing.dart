import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';
import 'package:expense_ai_agent/models/transaction.dart';

void main() async {
  final service = PDFParserService();

  // Test HDFC PDF
  print('Debugging HDFC detailed parsing...');
  final hdfcFile = File('HDFC-till 24.pdf');
  if (hdfcFile.existsSync()) {
    print('HDFC PDF file exists: ${hdfcFile.path}');

    // Parse the PDF
    try {
      final transactions = await service.parsePDF(hdfcFile);
      print(
        'Successfully parsed ${transactions.length} transactions from HDFC PDF',
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
      print('Error parsing HDFC PDF: $e');
    }
  } else {
    print('HDFC PDF file not found');
  }
}
