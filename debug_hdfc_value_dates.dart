import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test HDFC PDF
  print('Debugging HDFC value dates...');
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

    // Check for value dates manually
    print('\nChecking for value dates manually:');
    final dateRx = RegExp(r'^(\d{2})/(\d{2})/(\d{2})$');
    final amountRx = RegExp(r'[\d,]+\.\d{2}');

    for (int i = 25; i < 50 && i < lines.length; i++) {
      // Check if this line has a date at the beginning
      final dateMatch = dateRx.firstMatch(lines[i]);
      if (dateMatch != null) {
        print('Found date at line $i: ${lines[i]}');

        // Look for amount on same line or next few lines
        bool foundAmount = false;
        for (int j = i; j < i + 5 && j < lines.length; j++) {
          if (amountRx.hasMatch(lines[j])) {
            print('  Amount found at line $j: ${lines[j]}');
            foundAmount = true;
            break;
          }
        }

        if (!foundAmount) {
          print('  No amount found near line $i');
        }
      }
    }
  }
}
