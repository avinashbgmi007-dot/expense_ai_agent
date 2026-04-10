import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();
  final file = File('Union_Bank.pdf');
  final transactions = await service.parsePDF(file);
  
  // Show all dates we parsed
  final dates = transactions.map((t) {
    final d = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')} | ${t.merchant} | ${t.amount}';
  }).toList();
  
  // Expected transactions from Union Bank PDF:
  // 02-01-2022 - avinash (CR) 20000 ✅
  // 03-01-2022 - int pd (CR) 1079 ✅
  // 05-01-2022 - BY (CR) 6500 - MISSING?
  // 13-01-2022 - dummy na (DR) 100000 ✅
  // 17-01-2022 - BY CASH (CR) 45000 - MISSING?
  // 18-01-2022 - BY CASH (CR) 45000 - MISSING?
  // etc.
  
  print('Total parsed: ${dates.length}');
  for (final d in dates) {
    print(d);
  }
  
  // Check for "by" in descriptions
  final byTxns = transactions.where((t) => 
    t.description != null && 
    (t.description.toLowerCase().contains('by') || t.description.toLowerCase().contains('frm'))
  ).toList();
  print('\n=== BY/FRM transactions found: ${byTxns.length} ===');
  
  // Check: does the Union Bank parser skip "BY" and "BY CASH"?
}
