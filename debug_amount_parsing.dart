import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test HDFC PDF
  print('Debugging amount parsing for CAPGEMINI transaction...');
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

    // Look for the specific CAPGEMINI line
    print('\nLooking for CAPGEMINI transaction line...');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains('capgemini')) {
        print('Found CAPGEMINI at line $i: ${lines[i]}');

        // Test different regex patterns for amount extraction
        final amountAtEndRx = RegExp(r'([\d,]+\.\d{2})$');
        final amountAnywhereRx = RegExp(r'([\d,]+\.\d{2})');

        print('  Testing amount regex patterns:');
        print('    Amount at end pattern: ${amountAtEndRx.hasMatch(lines[i])}');
        print(
          '    Amount anywhere pattern: ${amountAnywhereRx.hasMatch(lines[i])}',
        );

        if (amountAtEndRx.hasMatch(lines[i])) {
          final match = amountAtEndRx.firstMatch(lines[i]);
          print('    Amount at end match: ${match?.group(1)}');
        }

        if (amountAnywhereRx.hasMatch(lines[i])) {
          final match = amountAnywhereRx.firstMatch(lines[i]);
          print('    Amount anywhere match: ${match?.group(1)}');
        }

        // Show context around this line
        print('  Context around line $i:');
        for (int j = i - 1; j <= i + 1 && j < lines.length; j++) {
          if (j >= 0) {
            print('    Line $j: ${lines[j]}');
          }
        }
        break;
      }
    }
  }
}
