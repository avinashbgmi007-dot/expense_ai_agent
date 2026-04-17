import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service_fixed.dart';

void main() async {
  final file = File('HDFC-till 24.pdf');
  if (file.existsSync()) {
    print('Testing with actual HDFC PDF...');
    final service = PDFParserService();
    final transactions = await service.parsePDF(file);
    print('Parsed ${transactions.length} total transactions');

    // Look specifically for CAPGEMINI transactions
    int capgeminiCount = 0;
    for (var t in transactions) {
      if (t.merchant != null && t.merchant!.toLowerCase().contains('capge')) {
        print('Found CAPGEMINI transaction: ${t.merchant} - ₹${t.amount}');
        capgeminiCount++;
      }
    }

    if (capgeminiCount == 0) {
      print('ERROR: No CAPGEMINI transactions found!');
    } else {
      print('SUCCESS: Found $capgeminiCount CAPGEMINI transactions.');
    }
  }
}
