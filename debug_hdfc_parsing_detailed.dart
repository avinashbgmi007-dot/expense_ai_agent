import 'dart:io';
import 'dart:math';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test with actual HDFC PDF to debug parsing

  print('=== STARTING HDFC PDF DEBUG TEST ===');

  try {
    final file = File('HDFC-till 24.pdf');
    if (!file.existsSync()) {
      print('ERROR: HDFC-till 24.pdf file not found!');
      return;
    }

    print('✓ File exists: ${file.path}');

    // Try parsing first
    final transactions = await service.parsePDF(file);
    print('✓ Parsed ${transactions.length} transactions');

    if (transactions.isEmpty) {
      print('ERROR: No transactions found!');
      print('🔍 Basic debugging: file with transactions should work');
      print('🔍 SUGGESTION: The PDF may be image-based, not text-based');
      print('🔍 Try using a different PDF with selectable text');
      return;
    }

    // Look specifically for CAPGEMINI transactions
    int capgeminiCount = 0;
    for (var t in transactions) {
      if (t.merchant != null && t.merchant!.toLowerCase().contains('capge')) {
        print('🎯 Found CAPGEMINI transaction: ${t.merchant} - ₹${t.amount}');
        capgeminiCount++;
      }
    }

    if (capgeminiCount == 0) {
      print('❌ No CAPGEMINI transactions found!');
      print('🔍 Merchant found:');
      transactions.take(5).forEach((t) {
        print('  - ${t.merchant}: ₹${t.amount}');
      });
    } else {
      print('✅ SUCCESS: Found $capgeminiCount CAPGEMINI transactions.');
    }

    print('=== TEST COMPLETE ===');
  } catch (e, stackTrace) {
    print('🔴 EXCEPTION OCCURRED: $e');
    print('Stack trace: $stackTrace');
  }
}
