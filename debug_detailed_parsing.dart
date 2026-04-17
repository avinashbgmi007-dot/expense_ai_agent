import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test HDFC PDF
  print('Detailed debugging of HDFC PDF parsing...');
  final hdfcFile = File('HDFC-till 24.pdf');
  if (hdfcFile.existsSync()) {
    print('HDFC PDF file exists: ${hdfcFile.path}');

    // Read the file and extract text
    final contents = await hdfcFile.readAsBytes();
    final text = service.extractAllText(contents);
    print('Extracted text length: ${text.length}');
    print('First 2000 characters:');
    print(text.substring(0, 2000));

    // Try to determine which format it is
    print('\nChecking format detection...');
    if (service.isUnionBankFormat(text)) {
      print('Detected as Union Bank format');
    } else if (service.isHDFCFormat(text)) {
      print('Detected as HDFC format');
    } else {
      print('No format detected');
    }
  }
}
