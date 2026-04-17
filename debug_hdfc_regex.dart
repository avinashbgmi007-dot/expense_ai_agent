import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test HDFC PDF
  print('Debugging HDFC regex patterns...');
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

    // Test different regex patterns
    print('\nTesting regex patterns:');

    // Current pattern (looks for dates at beginning of lines)
    final currentPattern = RegExp(r'^(\d{2})/(\d{2})/(\d{2})$');
    print('Current pattern (beginning of line):');
    for (int i = 25; i < 50 && i < lines.length; i++) {
      if (currentPattern.hasMatch(lines[i])) {
        print('  Match at line $i: ${lines[i]}');
      }
    }

    // New pattern (looks for dates anywhere in lines)
    final newPattern = RegExp(r'(\d{2})/(\d{2})/(\d{2})');
    print('\nNew pattern (anywhere in line):');
    for (int i = 25; i < 50 && i < lines.length; i++) {
      if (newPattern.hasMatch(lines[i])) {
        print('  Match at line $i: ${lines[i]}');
      }
    }
  }
}
