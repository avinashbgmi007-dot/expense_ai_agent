import 'dart:io';
import 'dart:typed_data';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test HDFC PDF
  print('Testing HDFC PDF...');
  final hdfcFile = File('HDFC-till 24.pdf');
  if (hdfcFile.existsSync()) {
    print('HDFC PDF file exists: ${hdfcFile.path}');
    print('File size: ${hdfcFile.lengthSync()} bytes');

    try {
      final transactions = await service.parsePDF(hdfcFile);
      print('Parsed ${transactions.length} transactions from HDFC PDF');
      for (var t in transactions) {
        print(
          '  - ${t.merchant}: ₹${t.amount} on ${DateTime.fromMillisecondsSinceEpoch(t.timestamp).toString().split(' ')[0]} | ${t.description}',
        );
      }
    } catch (e) {
      print('Error parsing HDFC PDF: $e');
    }
  } else {
    print('HDFC PDF file not found');
  }

  print('\nTesting Union Bank PDF...');
  final unionFile = File('Union_Bank.pdf');
  if (unionFile.existsSync()) {
    print('Union Bank PDF file exists: ${unionFile.path}');
    print('File size: ${unionFile.lengthSync()} bytes');

    try {
      final transactions = await service.parsePDF(unionFile);
      print('Parsed ${transactions.length} transactions from Union Bank PDF');
      for (var t in transactions) {
        print(
          '  - ${t.merchant}: ₹${t.amount} on ${DateTime.fromMillisecondsSinceEpoch(t.timestamp).toString().split(' ')[0]} | ${t.description}',
        );
      }
    } catch (e) {
      print('Error parsing Union Bank PDF: $e');
    }
  } else {
    print('Union Bank PDF file not found');
  }
}
