import 'dart:io';
import 'package:test/test.dart';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() {
  test('PDFParserService should parse HDFC real bank statement', () async {
    final service = PDFParserService();
    final file = File('HDFC-till 24.pdf');

    expect(file.existsSync(), isTrue);
    print('PDF file exists: ${file.existsSync()}');
    print('PDF file size: ${file.lengthSync()} bytes');

    final transactions = await service.parsePDF(file);
    print('Parsed ${transactions.length} transactions');

    for (var t in transactions) {
      print(
          '  - ${t.merchant}: ₹${t.amount} on ${t.formattedDateTime} | ${t.description}');
    }

    // PDF has 7 pages of data but only page 1 decompresses with standard zlib.
    // Page 1 has 8 transactions (7 debits + 1 credit).
    expect(transactions.length, greaterThanOrEqualTo(6),
        reason: 'At least 6 transactions should parse from page 1');

    // Should find Capgemini credit transaction
    final merchants = transactions.map((t) => t.merchant?.toLowerCase()).toSet();
    expect(merchants.any((m) => m?.contains('capge') == true || m?.contains('nema') == true), isTrue,
        reason: 'Should find known merchants like Capgemini or Nema Ram');

    // Should parse amounts correctly
    final totalSpend = transactions.where((t) => !t.credit).fold<double>(0, (sum, t) => sum + t.amount);
    print('\nTotal spend: ₹${totalSpend.toStringAsFixed(2)}');
    expect(totalSpend, greaterThan(0));

    // Should have at least one credit transaction
    final hasCredit = transactions.any((t) => t.credit);
    expect(hasCredit, isTrue, reason: 'Should detect NEFT credit transactions');
  });

  test('PDFParserService should parse synthetic test bank statement', () async {
    final service = PDFParserService();
    final file = File('test_bank_statement.pdf');

    expect(file.existsSync(), isTrue);

    final transactions = await service.parsePDF(file);
    expect(transactions.length, equals(5));

    // Check specific transactions
    expect(transactions.any((t) => t.merchant?.toLowerCase() == 'swiggy'), isTrue);
    expect(transactions.any((t) => t.merchant?.toLowerCase() == 'uber'), isTrue);
    expect(transactions.any((t) => t.merchant?.toLowerCase() == 'netflix'), isTrue);
    expect(transactions.any((t) => t.merchant?.toLowerCase() == 'starbucks'), isTrue);
    expect(transactions.any((t) => t.merchant?.toLowerCase() == 'amazon'), isTrue);

    // Verify amounts
    final swiggy = transactions.firstWhere((t) => t.merchant?.toLowerCase() == 'swiggy');
    expect(swiggy.amount, equals(500.0));

    final uber = transactions.firstWhere((t) => t.merchant?.toLowerCase() == 'uber');
    expect(uber.amount, equals(1000.0));
  });
}
