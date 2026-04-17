import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final parser = PDFParserService();
  final testFile = File('HDFC-till 24.pdf');

  print(
    '\\n================================================================================',
  );
  print('REAL-TIME UPLOAD SIMULATION - Testing PDF parsing');
  print(
    '================================================================================\\n',
  );

  if (await testFile.exists()) {
    print('Test file exists: ${testFile.path}');
    print('File size: ${await testFile.length()} bytes\\n');

    try {
      print('[TEST] Calling parsePDF...\\n');
      final transactions = await parser.parsePDF(testFile);

      print(
        '\\n================================================================================',
      );
      print('SUCCESS: Parsed ${transactions.length} transactions!');
      print(
        '================================================================================',
      );

      if (transactions.isNotEmpty) {
        print('\\nFirst 5 transactions:');
        for (var i = 0; i < transactions.length && i < 5; i++) {
          final txn = transactions[i];
          print(
            '${i + 1}. ${txn.merchant} | Amount: ₹${txn.amount} | ${DateTime.fromMillisecondsSinceEpoch(txn.timestamp).toLocal().toString().split(' ')[0]}',
          );
        }
        if (transactions.length > 5) {
          print('... and ${transactions.length - 5} more transactions');
        }
      }
    } catch (e) {
      print('\\nERROR: $e');
    }
  } else {
    print('Test file NOT found at: ${testFile.path}');
  }
}
