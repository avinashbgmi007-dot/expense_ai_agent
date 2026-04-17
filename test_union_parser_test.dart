import 'dart:io';
import 'package:test/test.dart';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() {
  test('PDFParserService should parse Union Bank real statement', () async {
    final service = PDFParserService();
    final file = File('Union_Bank.pdf');

    expect(file.existsSync(), isTrue);
    print('Union Bank PDF file exists: ${file.existsSync()}');
    print('Union Bank PDF file size: ${file.lengthSync()} bytes');

    final transactions = await service.parsePDF(file);
    print('Parsed ${transactions.length} transactions from Union Bank');

    for (var t in transactions) {
      print(
        '  - ${t.merchant}: ₹${t.amount} on ${t.formattedDateTime} | ${t.description}',
      );
    }

    expect(
      transactions.length,
      greaterThanOrEqualTo(5),
      reason: 'At least 5 transactions should parse from Union Bank statement',
    );

    // Should have some transactions
    expect(transactions.length, greaterThan(0));
  });
}
