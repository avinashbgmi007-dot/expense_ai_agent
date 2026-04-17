import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test HDFC PDF
  print('Full debugging of HDFC PDF parsing...');
  final hdfcFile = File('HDFC-till 24.pdf');
  if (hdfcFile.existsSync()) {
    print('HDFC PDF file exists: ${hdfcFile.path}');

    // Read the file and extract text
    final contents = await hdfcFile.readAsBytes();
    final text = service.extractAllText(contents);
    print('Extracted text length: ${text.length}');

    // Split into lines and show some sample lines
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    print('Total lines: ${lines.length}');

    // Show lines around transaction area
    print('Lines around transaction area (lines 20-70):');
    for (int i = 20; i < 70 && i < lines.length; i++) {
      print('Line $i: ${lines[i]}');
    }

    // Try to parse all transactions
    print('\nTrying to parse all transactions...');
    try {
      final transactions = service.parseHDFCStatement(text);
      print('Found ${transactions.length} transactions');
      for (var t in transactions) {
        print(
          '  - ${t.merchant}: ₹${t.amount} on ${DateTime.fromMillisecondsSinceEpoch(t.timestamp).toString().split(' ')[0]} | ${t.description}',
        );
      }
    } catch (e) {
      print('Error parsing transactions: $e');
    }
  }
}
