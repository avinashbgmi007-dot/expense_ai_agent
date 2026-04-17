import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';
import 'package:expense_ai_agent/models/transaction.dart';

void main() async {
  final service = PDFParserService();

  print('Debugging Union Bank single-line parsing...');

  final unionFile = File('Union_Bank.pdf');
  if (unionFile.existsSync()) {
    final contents = await unionFile.readAsBytes();
    final text = service.extractAllText(contents);
    print('Union Bank PDF text length: ${text.length}');

    // Try to parse with the PDF parser service
    try {
      final transactions = await service.parsePDF(unionFile);
      print('Parsed ${transactions.length} transactions');

      // Print first few transactions for debugging
      for (int i = 0; i < transactions.length && i < 5; i++) {
        print(
          'Transaction $i: ${transactions[i].description} - ${transactions[i].amount} - ${transactions[i].merchant}',
        );
      }
    } catch (e) {
      print('Error parsing Union Bank statement: $e');
    }
  } else {
    print('Union Bank PDF not found');
  }
}
