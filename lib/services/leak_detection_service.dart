import 'dart:math';
import '../models/transaction.dart';

/// Enhanced Leak Detection — returns actionable per-item data.
class LeakDetectionService {
  /// RecurringSubscription item with inferred metadata
  Map<String, dynamic> _buildSubscriptionInfo(List<TransactionModel> txns) {
    final merchant = txns.first.merchant ?? 'Unknown';
    final amount = txns.first.amount;
    final timestamps = txns.map((t) => t.timestamp).toList();
    final frequency = inferFrequency(timestamps);
    final category = txns.first.category.isNotEmpty
        ? txns.first.category
        : 'miscellaneous';
    final totalSpent = txns.fold<double>(0, (sum, t) => sum + t.amount);
    final monthlyEstimate = frequency == 'monthly'
        ? amount
        : frequency == 'quarterly'
        ? amount / 3
        : frequency == 'annual'
        ? amount / 12
        : amount * max(1, txns.length ~/ 3);

    return {
      'merchant': merchant,
      'amount': amount,
      'occurrences': txns.length,
      'frequency': frequency,
      'category': category,
      'totalSpent': totalSpent,
      'monthlyEstimate': monthlyEstimate,
    };
  }

  /// Small transaction item with category context
  Map<String, dynamic> _buildSmallTxnInfo(TransactionModel txn) {
    return {
      'merchant': txn.merchant ?? 'Unknown',
      'amount': txn.amount,
      'category': txn.category.isNotEmpty ? txn.category : 'miscellaneous',
      'date': txn.timestamp,
    };
  }

  /// Detect all leaks and return structured data
  Map<String, dynamic> detectLeaks(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return {
        'subscriptions': <dynamic>[],
        'smallTransactions': <dynamic>[],
        'totalMonthly': 0.0,
        'subscriptionMonthly': 0.0,
        'smallMonthly': 0.0,
        'suggestions': <String>[],
      };
    }

    final recurring = detectRecurringTransactions(
      transactions,
      minOccurrences: 2,
    );

    // Group recurring by merchant (exact match on merchant + same amount ±5%)
    final Map<String, List<TransactionModel>> recurringGroups = {};
    for (final txn in recurring) {
      final key = (txn.merchant ?? 'Unknown').toLowerCase();
      recurringGroups.putIfAbsent(key, () => []).add(txn);
    }

    // Filter out transfers from subscriptions (person-to-person payments are not "subscriptions")
    recurringGroups.removeWhere((key, txns) {
      final firstCat = txns.isNotEmpty
          ? (txns.first.category.isNotEmpty
                ? txns.first.category
                : 'miscellaneous')
          : 'miscellaneous';
      return firstCat == 'transfers' || firstCat == 'income';
    });

    final subscriptions = recurringGroups.entries
        .map((e) => _buildSubscriptionInfo(e.value))
        .toList();

    subscriptions.sort(
      (a, b) =>
          (b['monthlyEstimate'] as num).compareTo(a['monthlyEstimate'] as num),
    );

    // Small transactions (< ₹200) that are not transfers
    final smallTxns = transactions
        .where(
          (t) =>
              t.amount < 200 &&
              !t.credit &&
              t.category != 'transfers' &&
              t.category != 'income',
        )
        .toList();
    smallTxns.sort((a, b) => a.amount.compareTo(b.amount));

    final smallDetails = smallTxns
        .map((txn) => _buildSmallTxnInfo(txn))
        .toList();

    // Calculate totals
    final subscriptionMonthly = subscriptions.fold<double>(
      0,
      (sum, s) => sum + (s['monthlyEstimate'] as num).toDouble(),
    );
    final smallTotal = smallTxns.fold<double>(0, (sum, t) => sum + t.amount);

    // Suggestions
    final suggestions = <String>[];
    if (subscriptions.isNotEmpty) {
      final subCount = subscriptions.length;
      final subTotal = subscriptionMonthly.toStringAsFixed(0);
      suggestions.add(
        'You have $subCount recurring charges totaling ~₹$subTotal/month',
      );
      // Category breakdown
      final subByCategory = <String, double>{};
      for (final sub in subscriptions) {
        final cat = sub['category'] as String;
        subByCategory[cat] =
            (subByCategory[cat] ?? 0) +
            (sub['monthlyEstimate'] as num).toDouble();
      }
      for (final entry in subByCategory.entries) {
        suggestions.add(
          '${entry.key[0].toUpperCase() + entry.key.substring(1)}: ₹${entry.value.toStringAsFixed(0)}/month in recurring charges',
        );
      }
    }
    if (smallTotal > 500) {
      suggestions.add(
        'Small transactions add up to ₹${smallTotal.toStringAsFixed(0)} — review and consolidate where possible',
      );
    }

    final totalMonthly = subscriptionMonthly + smallTotal / 3;

    return {
      'subscriptions': subscriptions,
      'smallTransactions': smallDetails,
      'total': totalMonthly,
      'subscriptionMonthly': subscriptionMonthly,
      'smallMonthly': smallTotal,
      'suggestions': suggestions,
    };
  }

  /// Detect recurring transactions (simple grouping)
  List<TransactionModel> detectRecurringTransactions(
    List<TransactionModel> transactions, {
    int minOccurrences = 2,
  }) {
    if (transactions.isEmpty) return [];

    final Map<String, List<TransactionModel>> grouped = {};

    for (final tx in transactions) {
      final key = '${tx.merchant}_${(tx.amount / 10).floor() * 10}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

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
    double threshold = 200.0,
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

  /// Calculate monthly leak potential from transactions
  Map<String, dynamic> calculateMonthlyLeakPotential(
    List<TransactionModel> transactions,
  ) {
    if (transactions.isEmpty) {
      return {'subscriptions': 0.0, 'smallTransactions': 0.0, 'total': 0.0};
    }

    // Detect leaks first
    final leaks = detectLeaks(transactions);

    return {
      'subscriptions': leaks['subscriptionMonthly'] ?? 0.0,
      'smallTransactions': leaks['smallMonthly'] ?? 0.0,
      'total': leaks['totalMonthly'] ?? 0.0,
    };
  }

  /// Suggest actions to reduce leaks based on transaction patterns
  List<String> suggestLeakReductionActions(
    List<TransactionModel> transactions,
  ) {
    final leaks = detectLeaks(transactions);
    final suggestions = <String>[];

    // Subscription-based suggestions
    final subscriptions = leaks['subscriptions'] as List<dynamic>? ?? [];
    if (subscriptions.isNotEmpty) {
      // Group by category for more specific suggestions
      final Map<String, double> categoryTotals = {};
      for (final sub in subscriptions) {
        final category = sub['category'] as String? ?? 'miscellaneous';
        final monthlyEstimate =
            (sub['monthlyEstimate'] as num?)?.toDouble() ?? 0.0;
        categoryTotals[category] =
            (categoryTotals[category] ?? 0) + monthlyEstimate;
      }

      // Add category-specific suggestions
      categoryTotals.forEach((category, amount) {
        if (amount > 1000) {
          suggestions.add(
            'Consider reviewing your $category subscriptions - you\'re spending ₹${amount.toStringAsFixed(0)}/month',
          );
        } else if (amount > 500) {
          suggestions.add(
            'Your $category subscriptions total ₹${amount.toStringAsFixed(0)}/month - look for bundling opportunities',
          );
        }
      });

      // General subscription suggestion
      final totalSubMonthly = leaks['subscriptionMonthly'] ?? 0.0;
      if (totalSubMonthly > 0) {
        suggestions.add(
          'You have ${subscriptions.length} recurring subscriptions totaling ₹${totalSubMonthly.toStringAsFixed(0)}/month',
        );
      }
    }

    // Small transactions suggestions
    final smallTotal = leaks['smallMonthly'] ?? 0.0;
    if (smallTotal > 500) {
      suggestions.add(
        'Small transactions under ₹200 total ₹${smallTotal.toStringAsFixed(0)}/month - consider setting a weekly cash limit',
      );
    } else if (smallTotal > 200) {
      suggestions.add(
        'Monitor small daily expenses - they add up to ₹${smallTotal.toStringAsFixed(0)}/month',
      );
    }

    // If no significant leaks found
    if (suggestions.isEmpty) {
      final totalLeak = leaks['totalMonthly'] ?? 0.0;
      if (totalLeak > 0) {
        suggestions.add(
          'Your spending looks healthy! Keep monitoring for any new recurring charges.',
        );
      } else {
        suggestions.add('Great job! No significant spending leaks detected.');
      }
    }

    return suggestions;
  }
}
