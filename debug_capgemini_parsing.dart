import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test with the specific CAPGEMINI line
  final testText = '''
27/02/26 NEFT CR-SCBL0036001-CAPGEMINI SCBLH05801105085 27/02/26
TECHNOLOGY
SERVICES INDIA-AVINASH
''';

  print('Testing CAPGEMINI parsing...');
  print('Test text: $testText');

  final transactions = service.parseHDFCStatement(testText);
  print('Found ${transactions.length} transactions');

  for (var t in transactions) {
    print(
      '  - ${t.merchant}: ₹${t.amount} on ${t.formattedDateTime} | ${t.description}',
    );
  }

  // Also test the full HDFC parsing
  print('\nTesting full HDFC PDF...');
  final file = File('HDFC-till 24.pdf');
  if (file.existsSync()) {
    final transactions2 = await service.parsePDF(file);
    print('Parsed ${transactions2.length} transactions from PDF');

    // Look for CAPGEMINI specifically
    bool foundCapgemini = false;
    for (var t in transactions2) {
      if (t.merchant?.toLowerCase().contains('capge') == true) {
        print(
          'Found CAPGEMINI: ${t.merchant} - ₹${t.amount} - ${t.description}',
        );
        foundCapgemini = true;
      }
    }

    if (!foundCapgemini) {
      print('CAPGEMINI transaction NOT FOUND!');
    }
  }
}
