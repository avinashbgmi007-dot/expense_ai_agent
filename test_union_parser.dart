import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final file = File('Union_Bank.pdf');
  if (file.existsSync()) {
    print('Testing with Union Bank PDF using main parser...');
    final service = PDFParserService();
    final transactions = await service.parsePDF(file);
    print('Parsed ${transactions.length} total transactions');

    // Show some sample transactions
    print('\nFirst 10 transactions:');
    for (int i = 0; i < transactions.length && i < 10; i++) {
      print(
        '  ${transactions[i].merchant}: ₹${transactions[i].amount} (${transactions[i].credit ? 'Credit' : 'Debit'})',
      );
    }
  }
}
