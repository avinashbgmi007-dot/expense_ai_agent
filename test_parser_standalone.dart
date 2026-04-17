import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  print('=== STANDALONE PARSER TEST (No file_picker) ===\n');

  final parser = PDFParserService();

  // Test HDFC
  final hdfcFile = File('HDFC-till 24.pdf');
  if (await hdfcFile.exists()) {
    print('Testing HDFC file...');
    print('Path: ${hdfcFile.path}');
    print('Absolute: ${hdfcFile.absolute.path}');
    print('Size: ${hdfcFile.lengthSync()} bytes');

    try {
      final txns = await parser.parsePDF(hdfcFile);
      print('✓ SUCCESS: ${txns.length} transactions parsed from HDFC\n');

      if (txns.isNotEmpty) {
        print('Sample HDFC transactions:');
        for (var i = 0; i < 3 && i < txns.length; i++) {
          final t = txns[i];
          print('  - ${t.merchant}: ₹${t.amount} (${t.credit ? "Cr" : "Dr"})');
        }
      }
    } catch (e) {
      print('✗ FAILED: $e\n');
    }
  } else {
    print('HDFC file not found\n');
  }

  // Test Union Bank
  final unionFile = File('Union_Bank.pdf');
  if (await unionFile.exists()) {
    print('Testing Union Bank file...');
    print('Path: ${unionFile.path}');
    print('Absolute: ${unionFile.absolute.path}');
    print('Size: ${unionFile.lengthSync()} bytes');

    try {
      final txns = await parser.parsePDF(unionFile);
      print('✓ SUCCESS: ${txns.length} transactions parsed from Union Bank\n');

      if (txns.isNotEmpty) {
        print('Sample Union Bank transactions:');
        for (var i = 0; i < 3 && i < txns.length; i++) {
          final t = txns[i];
          print('  - ${t.merchant}: ₹${t.amount} (${t.credit ? "Cr" : "Dr"})');
        }
      }
    } catch (e) {
      print('✗ FAILED: $e\n');
    }
  } else {
    print('Union Bank file not found\n');
  }

  print('=== TEST COMPLETE ===');
}
