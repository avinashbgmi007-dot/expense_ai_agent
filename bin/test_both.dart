import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // ======== HDFC PDF ========
  print('========= HDFC PDF =========');
  try {
    final hdfcFile = File('HDFC-till 24.pdf');
    final hdfcTxns = await service.parsePDF(hdfcFile);
    print('Transactions: ${hdfcTxns.length}');
    final totalDebit = hdfcTxns.where((t) => !t.credit)
        .fold<double>(0, (s, t) => s + t.amount);
    final totalCredit = hdfcTxns.where((t) => t.credit)
        .fold<double>(0, (s, t) => s + t.amount);
    print('  Total Debits: ₹${totalDebit.toStringAsFixed(2)}');
    print('  Total Credits: ₹${totalCredit.toStringAsFixed(2)}');
    final merchants = hdfcTxns.map((t) => t.merchant).toSet();
    print('  Unique merchants: ${merchants.length}');
    final unknowns = hdfcTxns.where((t) => t.merchant == 'Unknown').toList();
    print('  Unknown merchants: ${unknowns.length}');
    for (final t in hdfcTxns) {
      print('  ${t.date} | ${t.credit ? "Cr" : "Dr"} ₹${t.amount} | ${t.merchant} | ${t.paymentMethod}');
    }
  } catch (e) {
    print('ERROR: $e');
  }

  // ======== Union Bank PDF ========
  print('\n========= UNION BANK PDF =========');
  try {
    final unionFile = File('Union_Bank.pdf');
    final unionTxns = await service.parsePDF(unionFile);
    print('Transactions: ${unionTxns.length}');
    final totalDebit = unionTxns.where((t) => !t.credit)
        .fold<double>(0, (s, t) => s + t.amount);
    final totalCredit = unionTxns.where((t) => t.credit)
        .fold<double>(0, (s, t) => s + t.amount);
    print('  Total Debits: ₹${totalDebit.toStringAsFixed(2)}');
    print('  Total Credits: ₹${totalCredit.toStringAsFixed(2)}');
    final merchants = unionTxns.map((t) => t.merchant).toSet();
    print('  Unique merchants: ${merchants.length}');
    final unknowns = unionTxns.where((t) => t.merchant == 'Unknown').toList();
    print('  Unknown merchants: ${unknowns.length}');
    if (unknowns.isNotEmpty) {
      for (final t in unknowns) {
        print('    ${t.date} | ${t.credit ? "Cr" : "Dr"} ₹${t.amount} | DESC: ${t.description}');
      }
    }
    for (final t in unionTxns) {
      print('  ${t.date} | ${t.credit ? "Cr" : "Dr"} ₹${t.amount} | ${t.merchant} | ${t.paymentMethod}');
    }
  } catch (e) {
    print('ERROR: $e');
  }

  // ======== Test Bank Statement ========
  print('\n========= TEST_BANK_STATEMENT PDF =========');
  try {
    final testFile = File('test_bank_statement.pdf');
    final testTxns = await service.parsePDF(testFile);
    for (final t in testTxns) {
      print('  ${t.date} | ${t.credit ? "Cr" : "Dr"} ₹${t.amount} | ${t.merchant}');
    }
  } catch (e) {
    print('ERROR: $e');
  }
}

extension on DateTime {
  String get short => '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

extension on dynamic {
  String get date {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
  }
}
