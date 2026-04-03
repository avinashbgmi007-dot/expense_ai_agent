import '../models/transaction.dart';

class AnalyzerService {
  // 1. Total spend
  double calculateTotalSpend(List<TransactionModel> transactions) {
    double total = 0;

    for (var t in transactions) {
      total += t.amount;
    }

    return total;
  }

  // 2. Merchant-wise spend
  Map<String, double> spendByMerchant(List<TransactionModel> transactions) {
    Map<String, double> data = {};

    for (var t in transactions) {
      final merchant = t.merchant ?? 'Unknown';
      data[merchant] = (data[merchant] ?? 0) + t.amount;
    }

    return data;
  }

  // 3. Detect repeated transactions (subscriptions)
  List<TransactionModel> detectRepeats(List<TransactionModel> transactions) {
    Map<String, int> count = {};

    for (var t in transactions) {
      String key = "${t.merchant}_${t.amount}";
      count[key] = (count[key] ?? 0) + 1;
    }

    return transactions.where((t) {
      String key = "${t.merchant}_${t.amount}";
      return count[key]! > 2;
    }).toList();
  }

  // 4. Detect UPI heavy usage
  double upiUsagePercentage(List<TransactionModel> transactions) {
    double total = 0;
    double upi = 0;

    for (var t in transactions) {
      total += t.amount;

      // Check if paymentMethod is UPI
      if ((t.paymentMethod?.toLowerCase() ?? '').contains('upi')) {
        upi += t.amount;
      }
    }

    if (total == 0) return 0;

    return (upi / total) * 100;
  }

  // 5. Detect small frequent spends (leak)
  List<TransactionModel> detectSmallLeaks(List<TransactionModel> transactions) {
    final List<TransactionModel> leaks = [];
    final Map<String, int> merchantCounts = {};

    for (final transaction in transactions) {
      if (transaction.amount < 50) {
        // Add to leaks
        leaks.add(transaction);
      }

      // Track merchant frequency
      final merchant = transaction.merchant ?? 'Unknown';
      merchantCounts[merchant] = (merchantCounts[merchant] ?? 0) + 1;
    }

    return leaks;
  }

  double calculateAverageDailySpend(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return 0;
    final total = calculateTotalSpend(transactions);
    return total / transactions.length;
  }

  String calculateRunway(double totalSpend, double averageDaily) {
    if (averageDaily == 0) {
      return "N/A";
    }
    return "${(totalSpend / averageDaily).toStringAsFixed(1)} months";
  }
}
