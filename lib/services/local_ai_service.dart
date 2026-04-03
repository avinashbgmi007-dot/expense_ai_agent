import '../models/transaction.dart';

/// Service to generate AI insights using local models (offline-capable)
class LocalAIService {
  /// Generate spending insights without requiring internet
  List<String> generateLocalInsights(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return ['No transactions available for analysis'];
    }

    final insights = <String>[];

    // 1. Daily spending pattern
    final dailyAverage = _calculateDailyAverage(transactions);
    insights.add(_generateDailyInsight(dailyAverage));

    // 2. Peak spending time
    final peakTime = _detectPeakSpendingTime(transactions);
    if (peakTime != null) {
      insights.add('Peak spending time: $peakTime');
    }

    // 3. Merchant concentration
    final topMerchantInsight = _detectMerchantConcentration(transactions);
    if (topMerchantInsight != null) {
      insights.add(topMerchantInsight);
    }

    // 4. Transaction frequency anomaly
    final anomaly = _detectTransactionAnomaly(transactions);
    if (anomaly != null) {
      insights.add(anomaly);
    }

    // 5. Savings opportunity
    final savingsOpportunity = _detectSavingOpportunity(transactions);
    if (savingsOpportunity != null) {
      insights.add(savingsOpportunity);
    }

    return insights;
  }

  /// Calculate daily average spending
  double _calculateDailyAverage(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return 0;

    final total = transactions.fold<double>(0, (sum, tx) => sum + tx.amount);

    // Get day range
    if (transactions.length < 2) return total;

    transactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final first = transactions.first.timestamp;
    final last = transactions.last.timestamp;

    const dayMs = 24 * 60 * 60 * 1000;
    final dayRange = ((last - first) / dayMs).ceil();

    return dayRange > 0 ? total / dayRange : total;
  }

  /// Generate insight about daily spending
  String _generateDailyInsight(double dailyAverage) {
    if (dailyAverage < 100) {
      return 'Your daily spending is low (₹${dailyAverage.toStringAsFixed(0)}/day) - Good control!';
    } else if (dailyAverage < 500) {
      return 'Your daily spending is moderate (₹${dailyAverage.toStringAsFixed(0)}/day) - Sustainable';
    } else if (dailyAverage < 1000) {
      return 'Your daily spending is elevated (₹${dailyAverage.toStringAsFixed(0)}/day) - Review opportunities';
    }
    return 'Your daily spending is high (₹${dailyAverage.toStringAsFixed(0)}/day) - Consider reducing';
  }

  /// Detect peak spending time (morning, afternoon, evening, night)
  String? _detectPeakSpendingTime(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return null;

    final timeMap = <String, double>{
      'morning': 0, // 6 AM - 12 PM
      'afternoon': 0, // 12 PM - 6 PM
      'evening': 0, // 6 PM - 12 AM
      'night': 0, // 12 AM - 6 AM
    };

    for (final tx in transactions) {
      final hour = DateTime.fromMillisecondsSinceEpoch(tx.timestamp).hour;

      if (hour >= 6 && hour < 12) {
        timeMap['morning'] = timeMap['morning']! + tx.amount;
      } else if (hour >= 12 && hour < 18) {
        timeMap['afternoon'] = timeMap['afternoon']! + tx.amount;
      } else if (hour >= 18 && hour < 24) {
        timeMap['evening'] = timeMap['evening']! + tx.amount;
      } else {
        timeMap['night'] = timeMap['night']! + tx.amount;
      }
    }

    final peakTime = timeMap.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return 'Most spending in ${peakTime.key} (₹${peakTime.value.toStringAsFixed(0)})';
  }

  /// Detect if spending is concentrated on few merchants
  String? _detectMerchantConcentration(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return null;

    final merchantMap = <String, double>{};
    for (final tx in transactions) {
      final merchant = tx.merchant ?? 'Unknown';
      merchantMap[merchant] = (merchantMap[merchant] ?? 0) + tx.amount;
    }

    final total = transactions.fold<double>(0, (sum, tx) => sum + tx.amount);
    if (total == 0) return null;

    // Get top merchant
    final topMerchant = merchantMap.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final concentration = (topMerchant.value / total) * 100;

    if (concentration > 40) {
      return '⚠️ High concentration: ${topMerchant.key} is ${concentration.toStringAsFixed(0)}% of spending';
    } else if (concentration > 25) {
      return 'Top merchant ${topMerchant.key} accounts for ${concentration.toStringAsFixed(0)}%';
    }

    return null;
  }

  /// Detect transaction anomalies
  String? _detectTransactionAnomaly(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return null;

    final amounts = transactions.map((t) => t.amount).toList();
    amounts.sort();

    final median = amounts.length % 2 == 0
        ? (amounts[amounts.length ~/ 2 - 1] + amounts[amounts.length ~/ 2]) / 2
        : amounts[amounts.length ~/ 2];

    // Find outliers (more than 3x the median)
    final outliers = amounts.where((a) => a > median * 3).toList();

    if (outliers.isNotEmpty) {
      return 'Unusual large transaction detected: ₹${outliers.first.toStringAsFixed(0)}';
    }

    return null;
  }

  /// Detect opportunities to save money
  String? _detectSavingOpportunity(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return null;

    // Detect recurring small expenses that add up
    final merchantMap = <String, List<double>>{};
    for (final tx in transactions) {
      final merchant = tx.merchant ?? 'Unknown';
      merchantMap.putIfAbsent(merchant, () => []).add(tx.amount);
    }

    for (final entry in merchantMap.entries) {
      final amounts = entry.value;
      if (amounts.length >= 3 && amounts.every((a) => a < 100)) {
        final total = amounts.fold<double>(0, (sum, a) => sum + a);
        return 'Save opportunity: ${entry.key} costs ₹${total.toStringAsFixed(0)} (${amounts.length}x)';
      }
    }

    return null;
  }
}
