import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test HDFC PDF
  print('Debugging HDFC dates...');
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

    // Check for dates in the middle of lines
    print('\nChecking for dates in the middle of lines:');
    final dateRx = RegExp(r'(\d{2})/(\d{2})/(\d{2})');
    for (int i = 25; i < 50 && i < lines.length; i++) {
      final matches = dateRx.allMatches(lines[i]);
      for (final match in matches) {
        print('  Date found at line $i: ${lines[i]}');
        print('    Match: ${match.group(0)}');
      }
    }
  }
}
