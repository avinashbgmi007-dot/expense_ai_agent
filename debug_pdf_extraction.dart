import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test HDFC PDF
  print('Debugging HDFC PDF extraction...');
  final hdfcFile = File('HDFC-till 24.pdf');
  if (hdfcFile.existsSync()) {
    print('HDFC PDF file exists: ${hdfcFile.path}');
    print('File size: ${hdfcFile.lengthSync()} bytes');

    // Read raw bytes
    final bytes = await hdfcFile.readAsBytes();
    print('Read ${bytes.length} bytes');

    // Try to extract text using the service's method
    try {
      final text = service.extractAllText(bytes);
      print('Extracted text length: ${text.length}');
      if (text.length > 1000) {
        print('First 1000 characters of extracted text:');
        print(text.substring(0, 1000));
      } else {
        print('Extracted text:');
        print(text);
      }
    } catch (e) {
      print('Error extracting text: $e');
    }
  } else {
    print('HDFC PDF file not found');
  }
}
