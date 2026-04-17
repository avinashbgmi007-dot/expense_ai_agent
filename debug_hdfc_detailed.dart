import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() {
  // Let's look at the actual HDFC statement format
  final file = File('HDFC-till 24.pdf');
  if (file.existsSync()) {
    print('PDF file exists: ${file.path}');
    print('File size: ${file.lengthSync()} bytes');
  } else {
    print('PDF file not found');
    return;
  }

  // Read the actual PDF content to understand the format
  final service = PDFParserService();
  final contents = file.readAsBytesSync();
  final text = service.extractAllText(contents);

  // Let's find the CAPGEMINI transaction in the text
  final lines = text.split('\n');
  print('Total lines in PDF: ${lines.length}');

  // Look for CAPGEMINI lines
  bool foundCapgeminiSection = false;
  for (int i = 0; i < lines.length && i < 100; i++) {
    if (lines[i].contains('CAPGEMINI') || lines[i].contains('capge')) {
      print('Found CAPGEMINI line $i: ${lines[i]}');
      foundCapgeminiSection = true;
      // Show context around this line
      int start = i > 5 ? i - 5 : 0;
      int end = i + 10 < lines.length ? i + 10 : lines.length;
      for (int j = start; j < end; j++) {
        if (j == i) {
          print('>>> ${j + 1} | ${lines[j]} <<<');
        } else {
          print('${j + 1} | ${lines[j]}');
        }
      }
      break;
    }
  }

  if (!foundCapgeminiSection) {
    // Look for the first few lines that contain transaction-like data
    print('Looking for transaction patterns...');
    for (int i = 0; i < lines.length && i < 50; i++) {
      if (lines[i].contains(RegExp(r'\d{2}/\d{2}/\d{2}'))) {
        print('Date line found: $i | ${lines[i]}');
      }
    }
  }
}
