
import 'dart:io';
import 'package:test/test.dart';
import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() {
  test('PDFParserService should parse test bank statement PDF', () async {
    final service = PDFParserService();
    final file = File('test_bank_statement.pdf');
    
    // Verify the file exists and has content
    expect(file.existsSync(), isTrue);
    print('PDF file exists: ${file.existsSync()}');
    print('PDF file size: ${file.lengthSync()} bytes');
    
    try {
      final transactions = await service.parsePDF(file);
      print('Parsed ${transactions.length} transactions');
      
      for (var t in transactions) {
        print('  - ${t.merchant}: \u20B9${t.amount} on ${t.formattedDateTime}');
      }
      
      expect(transactions, isNotEmpty);
    } catch (e, st) {
      print('PDF parsing error: $e');
      print('Stack: $st');
      fail('PDF parsing failed: $e');
    }
  });
}
