import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  print('=== REAL-TIME UPLOAD DEBUG ===\n');

  final pdfParserService = PDFParserService();
  final file = File('HDFC-till 24.pdf');

  try {
    print('1. Checking file existence...');
    if (!file.existsSync()) {
      print('ERROR: HDFC PDF file not found!');
      return;
    }
    print('   ✓ File exists: ${file.path}');
    print('   ✓ File size: ${file.lengthSync()} bytes\n');

    print('2. Calling parsePDF (this is what the app does)...');
    final transactions = await pdfParserService.parsePDF(file);
    print('   ✓ Parsed ${transactions.length} transactions\n');

    if (transactions.isEmpty) {
      print('ERROR: No transactions were parsed!');
      print('   This is where the "no transactions found" error occurs.\n');
    } else {
      print('3. SUCCESS: Transactions parsed successfully!');
      print('   First few transactions:');
      for (
        var i = 0;
        i < (transactions.length > 3 ? 3 : transactions.length);
        i++
      ) {
        final txn = transactions[i];
        print(
          '   - ${txn.merchant}: ₹${txn.amount} on ${DateTime.fromMillisecondsSinceEpoch(txn.timestamp)}',
        );
      }
    }
  } catch (e) {
    print('ERROR: Exception occurred during parsePDF:');
    print('   $e\n');
    print('   This is the error that would be shown to the user!');
  }
}
