import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';
import 'package:expense_ai_agent/services/database_service.dart';

void main() async {
  print('=== FULL UPLOAD SIMULATION DEBUG ===\n');

  final pdfParser = PDFParserService();
  final dbService = DatabaseService();
  final file = File('HDFC-till 24.pdf');

  try {
    print('STEP 1: File Check');
    if (!file.existsSync()) {
      print('❌ File does not exist');
      return;
    }
    print('✓ File exists: ${file.path}');
    print('✓ Size: ${file.lengthSync()} bytes\n');

    print('STEP 2: Initialize Database');
    await dbService.initialize();
    print('✓ Database initialized\n');

    print('STEP 3: Parse PDF (exactly like app does)');
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

      print('STEP 4: Debug - Let\'s check the text extraction');
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

      print('STEP 4: Insert into database (like app does)');
      int inserted = 0;
      for (var txn in transactions) {
        try {
          await dbService.insertTransaction(txn);
          inserted++;
        } catch (e) {
          print('❌ Error inserting transaction: $e');
          break;
        }
      }
      print('✓ Inserted $inserted/${transactions.length} transactions\n');

      print('STEP 5: Verify database');
      final allTxns = dbService.getTransactions();
      print('✓ Total transactions in database: ${allTxns.length}\n');

      if (allTxns.isNotEmpty) {
        print('Sample from database:');
        for (var i = 0; i < (allTxns.length > 3 ? 3 : allTxns.length); i++) {
          final txn = allTxns[i];
          print(' - ${txn.merchant}: ₹${txn.amount}');
        }
      }
    }

    print('\n=== SIMULATION COMPLETE ===');
    print(
      'If this script shows success but the app shows error, the issue is:',
    );
    print('1. App is using a different PDF file');
    print('2. App hasn\'t been rebuilt with the latest code');
    print('3. There\'s a different code path in the actual Flutter app');
  } catch (e, stackTrace) {
    print('\n❌ FATAL ERROR:');
    print('   $e');
    print('   Stack trace:\n$stackTrace');
  }
}
