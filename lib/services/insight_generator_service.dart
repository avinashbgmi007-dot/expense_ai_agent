import '../models/transaction.dart';

/// Service to generate AI-powered insights about spending patterns.
class InsightGeneratorService {
  /// Generate insights based on spending data.
  List<String> generateInsights(List<TransactionModel> transactions) {
    final insights = <String>[];

    if (transactions.isEmpty) {
      return ['No transactions to analyze'];
    }

    // Calculate total spending
    double totalSpend = 0;
    for (final t in transactions) {
      totalSpend += t.amount;
    }
    insights.add('Total spending: ₹${totalSpend.toStringAsFixed(2)}');

    // Detect high spending category
    final topMerchant = _findTopMerchant(transactions);
    if (topMerchant != null) {
      insights.add('Top merchant: $topMerchant');
    }

    // Detect trending upward
    final trend = _detectSpendingTrend(transactions);
    if (trend > 0) {
      insights.add(
        'Spending trend: Increasing (+${trend.toStringAsFixed(1)}%)',
      );
    } else if (trend < 0) {
      insights.add('Spending trend: Decreasing (${trend.toStringAsFixed(1)}%)');
    }

    // Identify recurring patterns
    final recurringCount = _countRecurringTransactions(transactions);
    if (recurringCount > 0) {
      insights.add('Recurring transactions identified: $recurringCount');
    }

    return insights;
  }

  /// Find the top merchant by spending.
  String? _findTopMerchant(List<TransactionModel> transactions) {
    final merchantMap = <String, double>{};
    for (final t in transactions) {
      final merchant = t.merchant ?? 'Unknown';
      merchantMap[merchant] = (merchantMap[merchant] ?? 0) + t.amount;
    }

    if (merchantMap.isEmpty) return null;

    String? topMerchant;
    double maxAmount = 0;
    merchantMap.forEach((merchant, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        topMerchant = merchant;
      }
    });

    return topMerchant;
  }

  /// Detect spending trend (positive = increasing, negative = decreasing).
  double _detectSpendingTrend(List<TransactionModel> transactions) {
    if (transactions.length < 2) return 0;

    final sortedByDate = [...transactions]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final midpoint = sortedByDate.length ~/ 2;
    double firstHalf = 0, secondHalf = 0;

    for (int i = 0; i < midpoint; i++) {
      firstHalf += sortedByDate[i].amount;
    }

    for (int i = midpoint; i < sortedByDate.length; i++) {
      secondHalf += sortedByDate[i].amount;
    }

    final firstHalfAvg = firstHalf / midpoint;
    final secondHalfAvg = secondHalf / (sortedByDate.length - midpoint);

    if (firstHalfAvg == 0) return 0;
    return ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100;
  }

  /// Count recurring transactions.
  int _countRecurringTransactions(List<TransactionModel> transactions) {
    final merchantAmountMap = <String, List<double>>{};

    for (final t in transactions) {
      final merchant = t.merchant ?? 'Unknown';
      merchantAmountMap.putIfAbsent(merchant, () => []).add(t.amount);
    }

    int recurringCount = 0;
    for (final amounts in merchantAmountMap.values) {
      if (amounts.length >= 3) {
        recurringCount++;
      }
    }

    return recurringCount;
  }
}
