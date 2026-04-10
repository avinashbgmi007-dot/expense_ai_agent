import 'dart:io';
import 'package:test/test.dart';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() {
  test('parses Union Bank PDF', () async {
    final service = PDFParserService();
    final file = File('Union_Bank.pdf');
    expect(await file.exists(), isTrue, reason: 'Union Bank PDF must exist');

    final transactions = await service.parsePDF(file);
    print('Found ${transactions.length} transactions');
    for (var t in transactions) {
      print('  ${t.merchant}: ₹${t.amount} | ${t.description} | credit=${t.credit}');
    }

    // Union Bank PDF has ~58 transactions (based on visible rows)
    expect(transactions.length, greaterThanOrEqualTo(50),
        reason: 'Union Bank PDF should have ~58 transactions');
  });
}
