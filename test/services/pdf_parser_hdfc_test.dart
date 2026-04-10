import 'dart:io';
import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';
import 'package:test/test.dart';

void main() {
  group('PDF Parser - HDFC Bank Statement', () {
    test('parses HDFC PDF and finds 62 transactions', () async {
      final service = PDFParserService();
      final file = File('HDFC-till 24.pdf');
      expect(await file.exists(), isTrue, reason: 'HDFC PDF file must exist');

      final transactions = await service.parsePDF(file);

      // HDFC statement should have exactly 62 transactions
      expect(transactions.length, 62,
          reason: 'Expected 62 transactions from HDFC statement');
    });

    test('parses test_bank_statement.pdf generic format', () async {
      final service = PDFParserService();
      final file = File('test_bank_statement.pdf');
      expect(await file.exists(), isTrue);

      final transactions = await service.parsePDF(file);
      // The uncompressed PDF has raw bytes + Tj operator text, but
      // we deduplicate by timestamp+amount+merchant, so expect ~5 unique
      expect(transactions.length, 5);

      expect(transactions[0].amount, 500.00);
      expect(transactions[0].merchant, 'Swiggy Food Order');
      expect(transactions[1].amount, 1000.00);
      expect(transactions[1].merchant, 'Uber Cab');
    });

    test('HDFC transactions have valid dates and amounts', () async {
      final service = PDFParserService();
      final file = File('HDFC-till 24.pdf');

      final transactions = await service.parsePDF(file);
      expect(transactions.length, greaterThanOrEqualTo(55));

      for (final txn in transactions) {
        expect(txn.amount, greaterThan(0),
            reason: 'Amount must be positive: ${txn.merchant}');
        expect(txn.currency, 'INR');
        expect(txn.merchant, isNot('Unknown'),
            reason: 'All transactions should have merchant names');
        expect(txn.merchant, isNotEmpty);
      }
    });

    test('HDFC credit transaction (salary) detected correctly', () async {
      final service = PDFParserService();
      final file = File('HDFC-till 24.pdf');

      final transactions = await service.parsePDF(file);

      final credits = transactions.where((t) => t.credit).toList();
      expect(credits, isNotEmpty, reason: 'Should find the NEFT salary credit');

      final salaryTxn =
          credits.where((t) => t.merchant?.contains('capgemini') ?? false).toList();
      expect(salaryTxn, isNotEmpty, reason: 'Salary from Capgemini should be found');
      expect(salaryTxn[0].amount, closeTo(115929.00, 0.01));
    });

    test('HDFC UPI transactions detected as UPI payment method', () async {
      final service = PDFParserService();
      final file = File('HDFC-till 24.pdf');

      final transactions = await service.parsePDF(file);
      final upiTxns =
          transactions.where((t) => t.paymentMethod == 'UPI').toList();
      expect(upiTxns.length, greaterThanOrEqualTo(50),
          reason: 'Most transactions should be UPI');
    });

    test('total debit amount is reasonable', () async {
      final service = PDFParserService();
      final file = File('HDFC-till 24.pdf');

      final transactions = await service.parsePDF(file);
      final totalDebit = transactions
          .where((t) => !t.credit)
          .fold<double>(0, (sum, t) => sum + t.amount);

      // From the HDFC PDF summary: Debits = 131,692.37
      expect(totalDebit, closeTo(131692.37, 1.00),
          reason: 'Total debits should match statement total of 131,692.37');
    });
  });
}
