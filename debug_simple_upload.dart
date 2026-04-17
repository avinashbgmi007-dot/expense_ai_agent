import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  print('=== SIMPLE UPLOAD FLOW DEBUG ===\n');

  final pdfParser = PDFParserService();
  final file = File('HDFC-till 24.pdf');

  try {
    print('STEP 1: File Check');
    if (!file.existsSync()) {
      print('❌ File does not exist');
      return;
    }
    print('✓ File exists: ${file.path}');
    print('✓ Size: ${file.lengthSync()} bytes\n');

    print('STEP 2: Parse PDF (exactly like app does)');
    List transactions;
    try {
      transactions = await pdfParser.parsePDF(file);
      print('✓ parsePDF() completed without exception');
      print('✓ Returned ${transactions.length} transactions\n');
    } catch (e) {
      print('❌ parsePDF() threw exception: $e');
      print('   This would be caught in home_screen.dart line 99\n');
      rethrow;
    }

    if (transactions.isEmpty) {
      print('❌ Transactions list is EMPTY');
      print('   This triggers the error at home_screen.dart line 70\n');

      print('STEP 3: Debug - Let\'s check the text extraction');
      final bytes = await file.readAsBytes();
      final text = pdfParser.extractAllText(bytes);
      print('   Extracted text length: ${text.length}');
      if (text.isNotEmpty) {
        print('   First 500 chars:');
        print(
          '   ${text.substring(0, text.length > 500 ? 500 : text.length)}\n',
        );

        print('   Format detection:');
        print('   - isHDFCFormat: ${pdfParser.isHDFCFormat(text)}');
        print('   - isUnionBankFormat: ${pdfParser.isUnionBankFormat(text)}\n');

        print('   Testing individual parsers directly:');
        final hdfcTxns = pdfParser.parseHDFCStatement(text);
        print('   - parseHDFCStatement returned: ${hdfcTxns.length}');
      }
    } else {
      print('✓ Transactions found: ${transactions.length}\n');
      print('First few transactions:');
      for (
        var i = 0;
        i < (transactions.length > 3 ? 3 : transactions.length);
        i++
      ) {
        final txn = transactions[i];
        print(' - ${txn.merchant}: ₹${txn.amount}');
      }
    }

    print('\n=== DEBUG COMPLETE ===');
  } catch (e, stackTrace) {
    print('\n❌ FATAL ERROR:');
    print('   $e');
    print('   Stack trace:\n$stackTrace');
  }
}
