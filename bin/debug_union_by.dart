import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();
  final file = File('Union_Bank.pdf');
  final txns = await service.parsePDF(file);

  print('Total: ${txns.length} transactions');
  
  // Check for the 05-01-2022 BY transaction
  final byTxns = txns.where((t) {
    final d = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
    return d.year == 2022 && d.month == 1 && d.day == 5;
  }).toList();
  
  if (byTxns.isEmpty) {
    print('MISSING: 05-01-2022 BY 142110027040124 (6500 CR)');
  } else {
    for (final t in byTxns) {
      print('Found 05-01-2022: ${t.merchant} | ${t.amount} | ${t.credit ? "CR" : "DR"} | ${t.description}');
    }
  }
  
  // Verify 01-05-2022 date is not accidentally parsed
  final jan5 = txns.where((t) {
    final d = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
    return d.month == 1 && d.day == 5;
  }).toList();
  print('Jan 5 transactions: ${jan5.length}');
}
