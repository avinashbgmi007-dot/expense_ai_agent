import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test Union Bank PDF
  print('Debugging Union Bank detailed parsing...');
  final unionFile = File('Union_Bank.pdf');
  if (unionFile.existsSync()) {
    print('Union Bank PDF file exists: ${unionFile.path}');

    // Read the file and extract text
    final contents = await unionFile.readAsBytes();
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
    print('Lines around transaction area (lines 0-50):');
    for (int i = 0; i < 50 && i < lines.length; i++) {
      print('Line $i: ${lines[i]}');
    }

    // Try to parse the PDF
    try {
      final transactions = await service.parsePDF(unionFile);
      print(
        'Successfully parsed ${transactions.length} transactions from Union Bank PDF',
      );
    } catch (e) {
      print('Error parsing Union Bank PDF: $e');
    }
  } else {
    print('Union Bank PDF file not found');
  }
}
