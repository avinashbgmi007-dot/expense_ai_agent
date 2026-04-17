import 'dart:io';
import 'package:pdf/pdf.dart';

void main() async {
  // Test the actual file that's failing
  final file = File('HDFC-till 24.pdf');
  if (await file.exists()) {
    print('Debug: Reading HDFC file...');
    final bytes = await file.readAsBytes();
    print('Debug: File size: ${bytes.length} bytes');

    // Try to parse the PDF directly
    try {
      final pdf = PdfDocument.openData(bytes);
      print('Debug: PDF parsed successfully');
      print('Debug: PDF has ${pdf.pagesCount} pages');

      // Extract text from first page
      final page = pdf.pages[0];
      final text = await page.text;
      print('Debug: First page text length: ${text.length}');
      print('Debug: First 500 chars: ${text.substring(0, 500)}');

      // Check if it's detected as HDFC format
      final isHDFC =
          text.toLowerCase().contains('hdfc bank') ||
          text.toLowerCase().contains('statement of account') ||
          text.toLowerCase().contains('narration') ||
          text.toLowerCase().contains('chq./ref.no.');
      print('Debug: Detected as HDFC format: $isHDFC');

      // Count transactions that would be parsed
      // This is a simplified version of the actual parsing logic
      final dateRx = RegExp(r'(\d{2})/(\d{2})/(\d{2})');
      final matches = dateRx.allMatches(text);
      print('Debug: Found ${matches.length} date patterns in text');
    } catch (e) {
      print('Debug: Error parsing PDF: $e');
    }
  } else {
    print('Debug: HDFC file not found');
  }
}
