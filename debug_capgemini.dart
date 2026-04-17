import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test HDFC PDF
  print('Debugging CAPGEMINI transaction specifically...');
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

    // Look for CAPGEMINI specifically
    print('\nLooking for CAPGEMINI transactions...');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains('capgemini')) {
        print('Found CAPGEMINI at line $i: ${lines[i]}');
        // Show context around this line
        for (int j = i - 2; j <= i + 2 && j < lines.length; j++) {
          if (j >= 0) {
            print('  Line $j: ${lines[j]}');
          }
        }
      }
    }

    // Try to parse the specific CAPGEMINI transaction
    print('\nTrying to parse CAPGEMINI transaction...');
    final dateRx = RegExp(r'(\d{2})/(\d{2})/(\d{2})');
    final amountRx = RegExp(r'([\d,]+\.\d{2})$');

    // Look for the specific lines with CAPGEMINI
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains('capgemini')) {
        print('Processing CAPGEMINI line $i: ${lines[i]}');

        // Check if it matches date pattern
        final dm = dateRx.firstMatch(lines[i]);
        if (dm != null) {
          print('  Date match found: ${dm.group(0)}');
          final day = int.parse(dm.group(1)!);
          final month = int.parse(dm.group(2)!);
          final yearRaw = int.parse(dm.group(3)!);
          final year = yearRaw < 50 ? 2000 + yearRaw : 1900 + yearRaw;
          print('  Parsed date: $year-$month-$day');

          // Look for amount in the same line or next few lines
          if (amountRx.hasMatch(lines[i])) {
            print('  Amount found in same line');
          } else {
            print('  Looking for amount in next lines...');
            for (int j = i + 1; j < i + 5 && j < lines.length; j++) {
              if (amountRx.hasMatch(lines[j])) {
                print('  Amount found at line $j: ${lines[j]}');
                break;
              }
            }
          }
        } else {
          print('  No date match found in line');
        }
      }
    }
  }
}
