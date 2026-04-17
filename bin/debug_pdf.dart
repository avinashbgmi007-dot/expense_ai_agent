import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test HDFC PDF
  try {
    print('Testing HDFC PDF parsing...');
    final hdfcFile = File('HDFC-till 24.pdf');
    if (await hdfcFile.exists()) {
      final transactions = await service.parsePDF(hdfcFile);
      print(
        'HDFC PDF parsed successfully: ${transactions.length} transactions',
      );
      for (var i = 0; i < transactions.length && i < 10; i++) {
        print(
          '  ${i + 1}. ${transactions[i].merchant}: ₹${transactions[i].amount} (${transactions[i].description})',
        );
      }
    } else {
      print('HDFC PDF file not found');
    }
  } catch (e) {
    print('Error parsing HDFC PDF: $e');
  }

  // Test Union Bank PDF
  try {
    print('\nTesting Union Bank PDF parsing...');
    final unionFile = File('Union_Bank.pdf');
    if (await unionFile.exists()) {
      final transactions = await service.parsePDF(unionFile);
      print(
        'Union Bank PDF parsed successfully: ${transactions.length} transactions',
      );
      for (var i = 0; i < transactions.length && i < 10; i++) {
        print(
          '  ${i + 1}. ${transactions[i].merchant}: ₹${transactions[i].amount} (${transactions[i].description})',
        );
      }
    } else {
      print('Union Bank PDF file not found');
    }
  } catch (e) {
    print('Error parsing Union Bank PDF: $e');
  }
}
