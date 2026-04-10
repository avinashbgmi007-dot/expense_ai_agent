import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';
import 'package:expense_ai_agent/services/ai_categorization_service.dart';

void main() async {
  final pdfParser = PDFParserService();
  final categorizer = AICategorizationService();

  group('HDFC Bank PDF', () {
    test('Parse and categorize all transactions', () async {
      final file = File('HDFC-till 24.pdf');
      if (!await file.exists()) {
        print('SKIP: HDFC PDF not found');
        return;
      }

      final transactions = await pdfParser.parsePDF(file);
      print('\n=== HDFC Bank Statement ===');
      print('Total transactions parsed: ${transactions.length}');

      int miscCount = 0;
      final categories = <String, int>{};
      final issues = <String>[];

      for (final txn in transactions) {
        final cat = categorizer.categorizeWithDescription(
          txn.merchant ?? '',
          txn.description ?? '',
          txn.credit,
          txn.amount,
        );
        categories[cat] = (categories[cat] ?? 0) + 1;
        if (cat == 'miscellaneous') {
          miscCount++;
          issues.add('misc: ${txn.merchant} | desc: ${txn.description} | ₹${txn.amount}');
        }
      }

      print('\nCategory breakdown:');
      categories.entries.toList().sort((a, b) => b.value.compareTo(a.value));
      for (final e in categories.entries) {
        print('  ${e.key}: ${e.value}');
      }

      if (miscCount > 0) {
        print('\n⚠️  $miscCount transactions categorized as miscellaneous:');
        for (final issue in issues) print('  $issue');
      }

      expect(miscCount <= 5, true, reason: 'Too many miscategorized: $miscCount');
    });
  });

  group('Union Bank PDF', () {
    test('Parse and categorize all transactions', () async {
      final file = File('Union_Bank.pdf');
      if (!await file.exists()) {
        print('SKIP: Union Bank PDF not found');
        return;
      }

      final transactions = await pdfParser.parsePDF(file);
      print('\n=== Union Bank Statement ===');
      print('Total transactions parsed: ${transactions.length}');

      int miscCount = 0;
      final categories = <String, int>{};
      final issues = <String>[];

      for (final txn in transactions) {
        final cat = categorizer.categorizeWithDescription(
          txn.merchant ?? '',
          txn.description ?? '',
          txn.credit,
          txn.amount,
        );
        categories[cat] = (categories[cat] ?? 0) + 1;
        if (cat == 'miscellaneous') {
          miscCount++;
          issues.add('misc: ${txn.merchant} | desc: ${txn.description} | ₹${txn.amount}');
        }
      }

      print('\nCategory breakdown:');
      categories.entries.toList().sort((a, b) => b.value.compareTo(a.value));
      for (final e in categories.entries) {
        print('  ${e.key}: ${e.value}');
      }

      if (miscCount > 0) {
        print('\n⚠️  $miscCount transactions categorized as miscellaneous:');
        for (final issue in issues) print('  $issue');
      }

      expect(miscCount <= 10, true, reason: 'Too many miscategorized: $miscCount');
    });
  });
}
