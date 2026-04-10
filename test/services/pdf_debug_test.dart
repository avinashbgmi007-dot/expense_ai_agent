import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() {
  test('debug test_bank_statement', () async {
    final service = PDFParserService();
    final file = File('test_bank_statement.pdf');
    final transactions = await service.parsePDF(file);
    print('Total txns: ${transactions.length}');
    for (final txn in transactions) {
      print('  ${txn.merchant} | ${txn.amount} | ${txn.timestamp} | id=${txn.id}');
    }
    // Check for duplicates
    final ids = transactions.map((t) => t.id).toSet();
    print('Unique ids: ${ids.length}');
    final dates = transactions.map((t) => t.timestamp).toList();
    final dateSets = dates.toSet();
    print('Unique dates: ${dateSets.length}');
  });

  test('check Union Bank PDF', () async {
    final service = PDFParserService();
    final file = File('Union_Bank.pdf');
    print('\nUnion Bank file exists: ${await file.exists()}');
    if (await file.exists()) {
      try {
        final transactions = await service.parsePDF(file);
        print('Transactions: ${transactions.length}');
        for (final txn in transactions.take(10)) {
          print('  ${txn.merchant} | ${txn.amount} | ${txn.credit} | ${txn.paymentMethod}');
        }
        if (transactions.length > 10) print('... and ${transactions.length - 10} more');
      } catch (e) {
        print('Error: $e');
      }
    }
  });
}
