import 'dart:io';
import 'package:test/test.dart';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() {
  group('PDF Parser - Comprehensive Accuracy Tests', () {
    late PDFParserService service;

    setUp(() {
      service = PDFParserService();
    });

    // ========= HDFC PDF TESTS =========
    group('HDFC Bank Statement', () {
      test('should parse exactly 62 transactions from HDFC PDF', () async {
        final file = File('HDFC-till 24.pdf');
        expect(await file.exists(), isTrue);

        final transactions = await service.parsePDF(file);
        expect(transactions.length, 62,
            reason: 'HDFC statement has exactly 62 transactions');
      });

      test('should capture the salary credit correctly', () async {
        final file = File('HDFC-till 24.pdf');
        final transactions = await service.parsePDF(file);

        final credits = transactions.where((t) => t.credit).toList();
        expect(credits, isNotEmpty);

        final salaryTxn =
            credits.where((t) => t.merchant?.contains('capgemini') ?? false).toList();
        expect(salaryTxn, isNotEmpty);
        expect(salaryTxn[0].amount, closeTo(115929.00, 0.01));
        expect(salaryTxn[0].paymentMethod, 'NEFT');
      });

      test('all UPI transactions should have UPI as payment method', () async {
        final file = File('HDFC-till 24.pdf');
        final transactions = await service.parsePDF(file);

        final upiTxns =
            transactions.where((t) => t.paymentMethod == 'UPI').toList();
        expect(upiTxns.length, greaterThanOrEqualTo(50));
      });

      test('total debit amount should match statement total', () async {
        final file = File('HDFC-till 24.pdf');
        final transactions = await service.parsePDF(file);

        final totalDebit = transactions
            .where((t) => !t.credit)
            .fold<double>(0, (sum, t) => sum + t.amount);

        // From HDFC statement summary: Debits = 131,692.37
        expect(totalDebit, closeTo(131692.37, 1.00),
            reason: 'Total debits should match statement');
      });

      test('all merchants should be identifiable, not Unknown', () async {
        final file = File('HDFC-till 24.pdf');
        final transactions = await service.parsePDF(file);

        for (final txn in transactions) {
          expect(txn.merchant, isNot(equals('Unknown')),
              reason: 'Transaction should have merchant: ${txn.description}');
          expect(txn.merchant?.isNotEmpty, isTrue);
        }
      });

      test('all transactions should have valid dates', () async {
        final file = File('HDFC-till 24.pdf');
        final transactions = await service.parsePDF(file);

        for (final txn in transactions) {
          final date = DateTime.fromMillisecondsSinceEpoch(txn.timestamp);
          expect(date.year, inInclusiveRange(2024, 2030),
              reason: 'Date year should be reasonable');
          expect(date.month, inInclusiveRange(1, 12));
          expect(date.day, inInclusiveRange(1, 31));
        }
      });

      test('all amounts should be positive', () async {
        final file = File('HDFC-till 24.pdf');
        final transactions = await service.parsePDF(file);

        for (final txn in transactions) {
          expect(txn.amount, greaterThan(0),
              reason: 'Amount must be positive');
        }
      });

      test('should detect multiple merchants in statement', () async {
        final file = File('HDFC-till 24.pdf');
        final transactions = await service.parsePDF(file);

        final merchants = transactions.map((t) => t.merchant).toSet();
        expect(merchants.length, greaterThanOrEqualTo(15),
            reason: 'Should have diverse merchants');
      });

      test('should correctly identify known merchants', () async {
        final file = File('HDFC-till 24.pdf');
        final transactions = await service.parsePDF(file);
        final merchants =
            transactions.map((t) => t.merchant?.toLowerCase()).toList();

        expect(merchants.any((m) => m != null && m.contains('google')), isTrue,
            reason: 'Should find Google payments');
        expect(merchants.any((m) => m != null && m.contains('mamu s food')), isTrue,
            reason: 'Should find food merchants');
        expect(merchants.any((m) => m != null && m.contains('paytm')), isTrue,
            reason: 'Should find Paytm');
        expect(merchants.any((m) => m != null && m.contains('npci')), isTrue,
            reason: 'Should find NPCI/BHIM');
      });

      test('should detect small UPI transactions (< ₹100)', () async {
        final file = File('HDFC-till 24.pdf');
        final transactions = await service.parsePDF(file);

        final smallUpi =
            transactions.where((t) => t.amount < 100 && t.paymentMethod == 'UPI');
        expect(smallUpi, isNotEmpty);
      });

      test('deduplication should not lose unique transactions', () async {
        final file = File('HDFC-till 24.pdf');
        final transactions = await service.parsePDF(file);

        final keys =
            transactions.map((t) => '${t.merchant}|${t.amount}|${t.timestamp}').toSet();
        expect(keys.length, equals(transactions.length),
            reason: 'No duplicate transactions');
      });
    });

    // ========= TEST_BANK_STATEMENT TESTS =========
    group('Test Bank Statement PDF', () {
      test('should parse all 5 transactions', () async {
        final file = File('test_bank_statement.pdf');
        final transactions = await service.parsePDF(file);

        expect(transactions.length, 5);
        expect(transactions[0].merchant, 'Swiggy Food Order');
        expect(transactions[0].amount, 500.00);
        expect(transactions[1].merchant, 'Uber Cab');
        expect(transactions[1].amount, 1000.00);
        expect(transactions[2].merchant, 'Netflix Subscription');
        expect(transactions[2].amount, 300.00);
      });

      test('all 5 transactions should have unique dates', () async {
        final file = File('test_bank_statement.pdf');
        final transactions = await service.parsePDF(file);

        final dates = transactions.map((t) => t.timestamp).toSet();
        expect(dates.length, 5, reason: 'Each transaction has a unique date');
      });
    });

    // ========= Union Bank PDF =========
    group('Union Bank (image-based PDF)', () {
      test('should provide helpful error for image-based PDFs', () async {
        final file = File('Union_Bank.pdf');
        if (!await file.exists()) return;

        try {
          await service.parsePDF(file);
          fail('Should throw for image-based PDF');
        } catch (e) {
          expect(e.toString().toLowerCase(), anyOf(
            contains('no transactions'),
            contains('could not extract'),
            contains('image'),
            contains('scanned'),
          ));
        }
      });
    });

    // ========= EDGE CASES =========
    group('Error Handling', () {
      test('should throw for non-existent file', () async {
        expect(service.parsePDF(File('nonexistent.pdf')), throwsA(isA<Exception>()));
      });

      test('should throw for empty binary data', () async {
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
        final file = File('${tempDir.path}/binary.pdf');
        await file.writeAsBytes(List<int>.generate(100, (i) => i % 256));

        try {
          await service.parsePDF(file);
          fail('Should throw for non-PDF binary data');
        } catch (e) {
          expect(e.toString(), contains('PDF'));
        } finally {
          await tempDir.delete(recursive: true);
        }
      });
    });
  });
}
