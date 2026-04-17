import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test format detection for both PDFs
  print('Debugging format detection...');

  // Test HDFC PDF
  print('\n=== HDFC PDF Format Detection ===');
  final hdfcFile = File('HDFC-till 24.pdf');
  if (hdfcFile.existsSync()) {
    final contents = await hdfcFile.readAsBytes();
    final text = service.extractAllText(contents);
    print('HDFC PDF text length: ${text.length}');

    // Test format detection
    final indicators = [
      'Statement of account',
      'Narration',
      'Withdrawal',
      'Deposit',
      'Closing',
      'Balance',
      'UPI-',
      'NEFT',
      'CR-',
    ];
    int hits = 0;
    for (final ind in indicators) {
      if (text.contains(ind)) hits++;
      print('HDFC contains "$ind": ${text.contains(ind)}');
    }
    print('HDFC format hits: $hits');

    // Count date patterns
    int ddMmYyCount = RegExp(r'\d{2}/\d{2}/\d{2}').allMatches(text).length;
    print('HDFC DD/MM/YY pattern count: $ddMmYyCount');
  }

  // Test Union Bank PDF
  print('\n=== Union Bank PDF Format Detection ===');
  final unionFile = File('Union_Bank.pdf');
  if (unionFile.existsSync()) {
    final contents = await unionFile.readAsBytes();
    final text = service.extractAllText(contents);
    print('Union Bank PDF text length: ${text.length}');

    // Test format detection
    int ddmmmyyyyCount = RegExp(r'\d{2}-\d{2}-\d{4}').allMatches(text).length;
    int upiAbArCount = RegExp(r'UPI[AB]R/').allMatches(text).length;
    print('Union Bank DD-MM-YYYY pattern count: $ddmmmyyyyCount');
    print('Union Bank UPI[AB]R pattern count: $upiAbArCount');
  }
}
