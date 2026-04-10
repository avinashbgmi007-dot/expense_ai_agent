import 'dart:io';
import 'dart:convert';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();
  final file = File('Union_Bank.pdf');
  final txns = await service.parsePDF(file);
  
  print('Parsed ${txns.length} transactions');
  print('');
  for (int i = 0; i < txns.length; i++) {
    final t = txns[i];
    final d = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
    final dateStr = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    print('${i+1}. $dateStr | ${t.merchant!.padRight(25)} | Rs ${t.amount.toString().padLeft(10)} | ${(t.credit ? "CR" : "DR").padRight(3)} | ${t.description}');
  }
  
  // Check for missing transaction types
  print('\nMissing types check:');
  final cashTxns = txns.where((t) => 
    (t.description?.toLowerCase().contains('by') == true) ||
    (t.description?.toLowerCase().contains('frm') == true) ||
    t.description?.toLowerCase() == 'accidental ins ren prem'
  ).toList();
  print('  BY/FRM/ACCIDENTAL: ${cashTxns.length} found');
  for (final c in cashTxns) {
    print('    -> ${c.description} | ${c.merchant}');
  }
  
  // Count by date
  print('\nTransactions per day:');
  final dateCounts = <String, int>{};
  for (final t in txns) {
    final d = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
    final dateStr = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    dateCounts[dateStr] = (dateCounts[dateStr] ?? 0) + 1;
  }
  for (final entry in dateCounts.entries.toList()..sort((a,b) => a.key.compareTo(b.key))) {
    if (entry.value > 1) {
      print('  ${entry.key}: ${entry.value} txns');
    }
  }
}
