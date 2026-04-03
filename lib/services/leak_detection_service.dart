import '../models/transaction.dart';

/// Service to detect spending leaks - recurring subscriptions and small transactions.
class LeakDetectionService {
  /// Detect recurring transactions (simple grouping)
  List<TransactionModel> detectRecurringTransactions(
    List<TransactionModel> transactions, {
    int minOccurrences = 2,
  }) {
    if (transactions.isEmpty) return [];

    final Map<String, List<TransactionModel>> grouped = {};

    // Group by merchant and amount
    for (final tx in transactions) {
      final key = '${tx.merchant}_${tx.amount}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    // Filter groups with multiple occurrences
    final recurring = <TransactionModel>[];
    for (final group in grouped.values) {
      if (group.length >= minOccurrences) {
        recurring.addAll(group);
      }
    }

    return recurring;
  }

  /// Detect small transactions that accumulate over time
  List<TransactionModel> detectSmallDrains(
    List<TransactionModel> transactions, {
    double threshold = 50.0,
  }) {
    return transactions.where((t) => t.amount < threshold).toList();
  }

  /// Calculate the frequency of a recurring transaction pattern
  String inferFrequency(List<int> timestamps) {
    if (timestamps.length < 2) return 'unknown';

    timestamps.sort();
    final gaps = <int>[];
    for (int i = 1; i < timestamps.length; i++) {
      gaps.add(timestamps[i] - timestamps[i - 1]);
    }

    if (gaps.isEmpty) return 'unknown';

    final avgGap = gaps.reduce((a, b) => a + b) ~/ gaps.length;
    const dayMs = 24 * 60 * 60 * 1000;

    if (avgGap < dayMs * 2) return 'daily';
    if (avgGap < dayMs * 10) return 'weekly';
    if (avgGap < dayMs * 20) return 'fortnightly';
    if (avgGap < dayMs * 60) return 'monthly';
    if (avgGap < dayMs * 120) return 'quarterly';
    return 'annual';
  }

  /// Calculate monthly leak potential
  Map<String, double> calculateMonthlyLeakPotential(
    List<TransactionModel> transactions,
  ) {
    final recurring = detectRecurringTransactions(transactions);
    final small = detectSmallDrains(transactions);

    double recurringTotal = 0;
    double smallTotal = 0;

    for (final t in recurring) {
      recurringTotal += t.amount;
    }

    for (final t in small) {
      smallTotal += t.amount;
    }

    // Estimate monthly impact (assuming recurring happens ~4x/month)
    final estimatedMonthlySubscriptions =
        (recurringTotal / recurring.length) * 4 * (recurring.length ~/ 2);

    return {
      'subscriptions': estimatedMonthlySubscriptions > 0
          ? estimatedMonthlySubscriptions
          : 0,
      'smallTransactions': smallTotal,
      'total':
          (estimatedMonthlySubscriptions > 0
              ? estimatedMonthlySubscriptions
              : 0) +
          smallTotal,
    };
  }

  /// Suggest actions to reduce leaks
  List<String> suggestLeakReductionActions(
    List<TransactionModel> transactions,
  ) {
    final leaks = calculateMonthlyLeakPotential(transactions);
    final suggestions = <String>[];

    if ((leaks['subscriptions'] ?? 0) > 50) {
      suggestions.add(
        'Audit your subscriptions - estimated recurring charges: ₹${leaks['subscriptions']?.toStringAsFixed(0)}',
      );
    }

    if ((leaks['smallTransactions'] ?? 0) > 100) {
      suggestions.add(
        'Small transactions add up to ₹${leaks['smallTransactions']?.toStringAsFixed(0)} monthly',
      );
    }

    if (((leaks['total'] ?? 0)) > 500) {
      suggestions.add(
        'Total monthly leaks: ₹${leaks['total']?.toStringAsFixed(0)} - review and consolidate',
      );
    }

    return suggestions;
  }

  /// Detect all leaks and return as a map
  Map<String, dynamic> detectLeaks(List<TransactionModel> transactions) {
    final potential = calculateMonthlyLeakPotential(transactions);
    return {
      'subscriptions': potential['subscriptions'] ?? 0.0,
      'smallTransactions': potential['smallTransactions'] ?? 0.0,
      'total': potential['total'] ?? 0.0,
      'suggestions': suggestLeakReductionActions(transactions),
    };
  }
}
