import 'dart:io';
import 'package:expense_ai_agent/services/file_upload_service.dart';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  print('=== WINDOWS PATH HANDLING TEST ===\n');

  final fileUploadService = FileUploadService();
  final pdfParserService = PDFParserService();

  // Test with explicit file path (like what file picker might return)
  final testPaths = [
    'HDFC-till 24.pdf', // Current directory
    './HDFC-till 24.pdf',
    '.\\HDFC-till 24.pdf',
    'C:\\Users\\Avinash-Pro\\Documents\\work_space\\expense_ai_agent\\HDFC-till 24.pdf',
  ];

  for (final path in testPaths) {
    print('Testing path: $path');
    final file = File(path);

    if (await file.exists()) {
      print('✓ File exists');
      print('✓ Size: ${file.lengthSync()} bytes');

      try {
        final transactions = await pdfParserService.parsePDF(file);
        print('✓ SUCCESS: Parsed ${transactions.length} transactions\n');
      } catch (e) {
        print('✗ ERROR: $e\n');
      }
    } else {
      print('✗ File not found\n');
    }
  }

  // Also test reading the file as bytes directly to ensure it's readable
  print('\n=== DIRECT BYTES READ TEST ===');
  final directFile = File('HDFC-till 24.pdf');
  if (await directFile.exists()) {
    print('Reading file directly...');
    try {
      final bytes = await directFile.readAsBytes();
      print('Read ${bytes.length} bytes successfully');

      // Test text extraction
      final parser = PDFParserService();
      // Can't call private method, but we can verify the parser works
      final txns = await parser.parsePDF(directFile);
      print('Parser returned ${txns.length} transactions');
    } catch (e) {
      print('Error: $e');
    }
  }
}
