import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test HDFC PDF
  print('Debugging HDFC parsing logic...');
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

    // Let's manually parse some transactions
    print('\nManual parsing of first few transactions:');

    // Look for transaction start dates (at beginning of lines)
    final dateRx = RegExp(r'^(\d{2})/(\d{2})/(\d{2})');
    for (int i = 25; i < 50 && i < lines.length; i++) {
      final match = dateRx.firstMatch(lines[i]);
      if (match != null) {
        print('Found date at line $i: ${lines[i]}');
        // Look for amount on same line or next few lines
        for (int j = i; j < i + 5 && j < lines.length; j++) {
          // Check if this line has amount pattern
          final amountRx = RegExp(r'[\d,]+\.\d{2}');
          if (amountRx.hasMatch(lines[j])) {
            print('  Amount pattern found at line $j: ${lines[j]}');
          }
        }
      }
    }
  }
}
