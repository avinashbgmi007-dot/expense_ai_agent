import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final service = PDFParserService();

  // Test with actual HDFC PDF to see if CAPGEMINI is parsed
  final file = File('HDFC-till 24.pdf');
  if (file.existsSync()) {
    print('Testing with actual HDFC PDF...');
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
      print(
        'ERROR: No CAPGEMINI transactions found! This confirms the parsing issue.',
      );
    } else {
      print('SUCCESS: Found $capgeminiCount CAPGEMINI transactions.');
    }

    // Show all merchants to see what we're missing
    print('\nAll transaction merchants found:');
    final merchants = <String>{};
    for (var t in transactions) {
      if (t.merchant != null) {
        merchants.add(t.merchant!);
      }
    }
    merchants.forEach((merchant) => print('  - $merchant'));
  }
}
