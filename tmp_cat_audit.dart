import 'package:expense_ai_agent/services/ai_categorization_service.dart';

// All Union Bank merchants with their descriptions from the PDF
void main() {
  final svc = AICategorizationService();

  final transactions = [
    // merchant, description, isCredit, amount
    ('avinash', 'UPIAB/200226300109/CR/ANNAPRAG/HDFC/avinashavi360@', true, 20000.0),
    ('interest paid', '142110025030301:Int.Pd:01-10-2021 to 31-12-2021', true, 1079.0),
    ('bank transfer', 'BY 142110027040124', true, 6500.0),
    ('PUNB transfer', 'UPIAR/201361111390/DR/DUMMY NA/punb/15642191018000', false, 100000.0),
    ('cash deposit', 'BY CASH', true, 45000.0),
    ('cash deposit', 'BY CASH', true, 45000.0),
    ('avinash', 'UPIAB/201828001515/CR/ANNAPRAG/UBIN/avinashavi360-', true, 10000.0),
    ('debit card charges', 'DEBIT CARD CHARGES', false, 118.0),
    ('avinash', 'UPIAB/203241464259/CR/ANNAPRAG/HDFC/avinashavi360@', true, 20000.0),
    ('bank transfer', 'FRM 142110027040124', true, 6500.0),
    ('pasanna pragada', 'UPIAR/204050262640/DR/ANNAPRAG/UBIN/pasannapragada', false, 16500.0),
    ('avinash', 'UPIAB/206056758510/CR/ANNAPRAG/HDFC/avinashavi360@', true, 20000.0),
    ('SBIN transfer', 'UPIAR/206912718801/DR/DUMMY NA/sbin/11901122312@sb', false, 40000.0),
    ('sms charges', 'SMS Charges for March,2022 Quarter', false, 17.7),
    ('pasanna pragada', 'UPIAR/207215123543/DR/ANNAPRAG/UBIN/pasannapragada', false, 16500.0),
    ('pasanna pragada', 'UPIAB/207536660865/CR/ANNAPRAG/ANDB/pasannapragada', true, 40000.0),
    ('interest paid', '142110025030301:Int.Pd:01-01-2022 to 31-03-2022', true, 1356.0),
    ('pasanna pragada', 'UPIAR/210069204306/DR/ANNAPRAG/UBIN/pasannapragada', false, 16500.0),
    ('avinash', 'UPIAR/211286045831/DR/ANNAPRAG/HDFC/avinashavi360@', false, 3000.0),
    ('avinash', 'UPIAB/211415470815/CR/ANNAPRAG/HDFC/avinashavi360@', true, 50000.0),
    ('avinash', 'UPIAR/211803382212/DR/ANNAPRAG/HDFC/avinashavi360@', false, 5000.0),
    ('pasanna pragada', 'UPIAR/213097053853/DR/ANNAPRAG/UBIN/pasannapragada', false, 16500.0),
    ('pmsby insurance', '5172404PMSBY- 00071836- 01-06-2022 to 31-05-2023', false, 12.0),
    ('avinash', 'UPIAB/215100813568/CR/ANNAPRAG/HDFC/avinashavi360@', true, 90000.0),
    ('avinash', 'UPIAB/215328723985/CR/ANNAPRAG/HDFC/avinashavi360@', true, 25000.0),
    ('pasanna pragada', 'UPIAR/216206776955/DR/ANNAPRAG/UBIN/pasannapragada', false, 16500.0),
    ('sms charges', 'SMS Charges for June,2022 Quarter', false, 17.7),
    ('pmsby insurance', '5172404PMSBY- 00071836- 01-06-2022 to 31-05-2023', false, 8.0),
    ('avinash', 'UPIAB/218202600831/CR/ANNAPRAG/HDFC/avinashavi360@', true, 70000.0),
    ('interest paid', '142110025030301:Int.Pd:01-04-2022 to 30-06-2022', true, 1724.0),
    ('pasanna pragada', 'UPIAR/218868099254/DR/ANNAPRAG/UBIN/pasannapragada', false, 16500.0),
    ('hmwssb bill', 'UPIAR/220940879706/DR/HMWSSB B/HDFC/hmwssb.billdes', false, 8725.0),
    ('avinash', 'UPIAB/221163856504/CR/ANNAPRAG/HDFC/avinashavi360@', true, 70000.0),
    ('accidental insurance', 'ACCIDENTAL INS REN PREM', false, 39.5),
    ('pasanna pragada', 'UPIAR/222353884105/DR/ANNAPRAG/UBIN/pasannapragada', false, 16500.0),
    ('google pay', 'UPIAB/222364596113/CR/GOOGLEPA/UTIB/goog-payment@o', true, 10.0),
    ('avinash', 'UPIAR/222497307783/DR/ANNAPRAG/HDFC/avinashavi360@', false, 14000.0),
    ('g sravan', 'UPIAR/224140037620/DR/G SRAVAN/BARB/godesravanthi@', false, 50000.0),
    ('avinash', 'UPIAB/224342820531/CR/ANNAPRAG/HDFC/avinashavi360@', true, 80000.0),
    ('g sravan', 'UPIAB/224455058890/CR/G SRAVAN/BARB/godesravanthi@', true, 50000.0),
    ('pasanna pragada', 'UPIAR/225459904801/DR/ANNAPRAG/UBIN/pasannapragada', false, 16500.0),
    ('sms charges', 'SMS Charges for September,2022 Quarter', false, 17.7),
    ('select cars', 'UPIAR/227104094703/DR/SELECT C/SBIN/selectcars@sbi', false, 21000.0),
    ('interest paid', '142110025030301:Int.Pd:01-07-2022 to 30-09-2022', true, 2851.0),
    ('avinash', 'UPIAB/228232247195/CR/ANNAPRAG/HDFC/avinashavi360@', true, 45500.0),
    ('pasanna pragada', 'UPIAR/228297117481/DR/ANNAPRAG/UBIN/pasannapragada', false, 16500.0),
    ('g sravan', 'UPIAR/228511610184/DR/G SRAVAN/BARB/godesravanthi@', false, 45500.0),
    ('pasanna pragada', 'UPIAR/229315251615/DR/ANNAPRAG/UBIN/pasannapragada', false, 32000.0),
    ('pasanna pragada', 'UPIAR/231940528196/DR/ANNAPRAG/UBIN/pasannapragada', false, 5000.0),
    ('pasanna pragada', 'UPIAR/232003875844/DR/ANNAPRAG/UBIN/pasannapragada', false, 11500.0),
    ('avinash', 'UPIAR/232213541276/DR/ANNAPRAG/HDFC/avinashavi360@', false, 2000.0),
    ('chavidi balaiah', 'UPIAR/232505921662/DR/CHAVIDIB/UBIN/malyadrich470@', false, 1000.0),
    ('avinash', 'UPIAR/232582226584/DR/avinasha/HDFC/avinashavi360-', false, 1500.0),
    ('avinash', 'UPIAR/232577133817/DR/ANNAPRAG/HDFC/avinashavi360@', false, 2000.0),
    ('avinash', 'UPIAR/233144621045/DR/ANNAPRAG/SBIN/avinashavi360-', false, 500.0),
    ('pasanna pragada', 'UPIAR/234505494541/DR/ANNAPRAG/UBIN/pasannapragada', false, 16500.0),
    ('sms charges', 'SMS Charges for December,2022 Quarter', false, 17.7),
    ('pasanna pragada', 'UPIAR/236551798118/DR/ANNAPRAG/UBIN/pasannapragada', false, 100000.0),
  ];

  int correct = 0;
  int total = transactions.length;

  print('=== Categorization Audit ===\n');

  for (final t in transactions) {
    final category = svc.categorizeWithDescription(t.$1, t.$2, t.$3, t.$4);
    final confidence = svc.getConfidence(category, t.$1, t.$2, t.$3);
    final icon = confidence >= 0.90 ? '✓' : confidence >= 0.70 ? '~' : '?';
    if (confidence >= 0.80) correct++;

    print('$icon ${t.$1.padRight(25)} | ${category.padRight(16)} | ₹${t.$4} | conf=${(confidence * 100).toInt()}%');
  }

  print('\nAccuracy: $correct/$total (${(correct / total * 100).toStringAsFixed(1)}%)');

  // Show category breakdown
  final byCategory = <String, int>{};
  for (final t in transactions) {
    final cat = svc.categorizeWithDescription(t.$1, t.$2, t.$3, t.$4);
    byCategory[cat] = (byCategory[cat] ?? 0) + 1;
  }
  print('\nCategory breakdown:');
  byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in byCategory.entries) {
    print('  ${entry.key}: ${entry.value}');
  }
}
