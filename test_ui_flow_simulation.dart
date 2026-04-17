import 'dart:io';
import 'package:expense_ai_agent/services/file_upload_service.dart';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  print('=== UI FLOW SIMULATION ===\n');

  final fileUploadService = FileUploadService();
  final pdfParserService = PDFParserService();

  // Simulate what happens in HomeScreen._handleFileUpload
  print('Step 1: Pick file (simulating file picker)');
  // In real app, this would be from file picker. We'll use known file.
  final file = File('HDFC-till 24.pdf');

  if (!await file.exists()) {
    print('❌ File does not exist!');
    return;
  }

  print('✓ File exists: ${file.path}');

  // Get extension exactly like the UI does
  final ext = file.path.split('.').last.toLowerCase();
  print('✓ Detected extension: $ext');

  List transactions;

  try {
    print('Step 2: Calling parser...');
    if (ext == 'pdf') {
      transactions = await pdfParserService.parsePDF(file);
    } else {
      print('❌ Unsupported format');
      return;
    }

    print('Step 3: Checking if transactions empty');
    print('✓ Parsed ${transactions.length} transactions');

    if (transactions.isEmpty) {
      print('❌ ERROR FLOW: Would show "No valid transactions found"');
    } else {
      print('✓ SUCCESS: Would show ${transactions.length} transactions');
    }
  } catch (e) {
    print('❌ EXCEPTION CAUGHT: $e');
    print('   This would show "Error: $e" in UI');
  }
}
