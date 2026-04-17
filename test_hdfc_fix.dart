import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test the specific CAPGEMINI case
  final testText = '''
Date Narration Chq./Ref.No. Value Dt Withdrawal Amt. Deposit Amt. Closing Balance
115,929.00 132,541.89
27/02/26 NEFT CR-SCBL0036001-CAPGEMINI SCBLH05801105085 27/02/26
TECHNOLOGY
SERVICES INDIA-AVINASH
''';

  print('Testing HDFC parsing with balance format...');
  final transactions = service.parseHDFCStatement(testText);
  print('Found ${transactions.length} transactions');

  for (var t in transactions) {
    print('  - ${t.merchant}: ₹${t.amount} | ${t.description}');
  }

  if (transactions.isEmpty) {
    print('No transactions found - this confirms the issue!');
  }
}
