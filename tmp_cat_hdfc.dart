import 'package:expense_ai_agent/services/ai_categorization_service.dart';

void main() {
  final svc = AICategorizationService();

  // HDFC transactions (merchants from the HDFC statement)
  final transactions = [
    ('Swiggy', 'UPI-Swiggy Instamart UPI', false, 250.0),
    ('Swiggy', 'UPI-Swiggy Food UPI', false, 380.0),
    ('Uber', 'UPI-UBER TRIP UPI', false, 450.0),
    ('Zomato', 'UPI-Zomato Order UPI', false, 520.0),
    ('Nema Ram Chaudhary', 'upi-nema ram chaudhary', false, 300.0),
    ('Korra Sunitha', 'upi-korra sunitha', false, 800.0),
    ('Anipindi Durgaprasad', 'upi-anipindi durgaprasad', false, 1200.0),
    ('Seethala Manasa', 'upi-seethala manasa', false, 400.0),
    ('Siri Vallabh Hospital', 'upi-siri vallabh hospital', false, 1500.0),
    ('Siri Vallabh Pharmacy', 'upi-siri vallabh pharmacy', false, 800.0),
    ('Madani Hemanth Kumar', 'upi-madani hemanth kumar', false, 1000.0),
    ('Manchala Sravanthi', 'upi-manchala sravanthi', false, 3000.0),
    ('Kandala Mane Esha Bal', 'upi-kandala mane esha bal', false, 500.0),
    ('Mamu S Food', 'upi-mamu s food', false, 200.0),
    ('Raksh Medical', 'upi-rakesh medical', false, 350.0),
    ('Bathula Naveen Kumar', 'upi-bathula naveen kumar', false, 800.0),
    ('Kondapalli Deepthika', 'upi-kondapalli deepthika', false, 500.0),
    ('Pasanna Pragada', 'upi-pasanna pragada', false, 16500.0),
    ('Karamtothu Ravi', 'upi-nagati bhiksha', false, 400.0),
    ('Oruganti Yadaiah', 'upi-oruganti yadaiah', false, 500.0),
    ('Shiva Shankar Vegetables', 'upi-shiva shankar vegetables', false, 600.0),
    ('Jakkula Bhaskar', 'upi-jakkula bhaskar', false, 1000.0),
    ('Aleti Shekar Reddy', 'upi-aleti shekar reddy', false, 800.0),
    ('Sher Khan Mohammed', 'upi-sher khan mohammed', false, 400.0),
    ('Om Desserts', 'upi-om desserts', false, 200.0),
    ('Manne Sai Vardhan', 'upi-manne sai vardhan', false, 300.0),
    ('Samruddhi Amrutulya', 'upi-samruddhi amrutulya', false, 500.0),
    ('Bachalakuri Purnaiah', 'upi-bachalakuri purnaiah', false, 200.0),
    ('Cityflo', 'UPI-Cityflo', false, 5000.0),
    ('Dumpa Rambabu', 'UPI-dumpa rambabu', false, 300.0),
    ('Sampradaya Tiffins', 'UPI-sampradaya tiffins', false, 150.0),
    ('Sri Vekateshwara Kirana', 'UPI-sri vekateshwara kirana', false, 500.0),
    ('Murugan Kanniyapp', 'UPI-murugan kanniyapp', false, 400.0),
    ('Ambey Kirana General', 'UPI-ambey kirana', false, 300.0),
    ('UIDAI', 'UPI-uidai', false, 100.0),
    ('Ch V K Subramanyam', 'UPI-ch v k subramanyam', false, 2000.0),
    ('Kolluru Sai Ram', 'UPI-kolluru sai ram', false, 1000.0),
    ('Bharatpe', 'UPI-bharatpe', false, 500.0),
    ('Paytm', 'UPI-paytm', false, 300.0),
    ('NPCI BHIM', 'UPI-NPCI BHIM', false, 200.0),
    ('Google India', 'NEFT-CAPGEMINI', true, 115929.0),
    ('Capgemini', 'NEFT-SALARY', true, 115929.0),
    ('Google Pay', 'UPI-GooglePay', false, 50000.0),
    ('PZ HDFC CC', 'UPI-HDFC Credit Card', false, 25000.0),
    ('HDFC Credit Card', 'UPI-HDFC CC Bill', false, 12000.0),
    ('Raksh Medical', 'UPI-raksh medical', false, 250.0),
    ('PMSBY Insurance', 'PMSBY-00071836', false, 12.0),
    ('SMS Charges', 'SMS Charges', false, 17.7),
  ];

  int correct = 0;
  print('=== HDFC Categorization Audit ===\n');

  for (final t in transactions) {
    final cat = svc.categorizeWithDescription(t.$1, t.$2, t.$3, t.$4);
    final conf = svc.getConfidence(cat, t.$1, t.$2, t.$3);
    final icon = conf >= 0.90 ? '✓' : conf >= 0.70 ? '~' : '?';
    if (conf >= 0.80) correct++;
    final marker = t.$3 ? '(Cr)' : '(Dr)';
    print('$icon ${t.$1.padRight(30)} | ${cat.padRight(16)} | ₹${t.$4} $marker | ${conf.toStringAsFixed(0)}%');
  }
  print('\nAccuracy: $correct/${transactions.length} (${(correct / transactions.length * 100).toStringAsFixed(1)}%)');

  final byCat = <String, int>{};
  for (final t in transactions) {
    final cat = svc.categorizeWithDescription(t.$1, t.$2, t.$3, t.$4);
    byCat[cat] = (byCat[cat] ?? 0) + 1;
  }
  print('\nCategory breakdown:');
  byCat.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in byCat.entries) {
    print('  ${e.key}: ${e.value}');
  }

  final miscCount = byCat['miscellaneous'] ?? 0;
  print('\nMiscellaneous count: $miscCount (should be 0)');
}
