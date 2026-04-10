// lib/models/monthly_summary.dart

class MonthlySummary {
  final int? id;
  final String monthYear; // Format: "2026-03"
  final double totalSpend;
  final Map<String, double>
  spendByCategory; // {"food": 8000, "transport": 2500}
  final List<String> topMerchants; // Top 5 merchants
  final double runwayMonths;
  final int transactionCount;
  final List<String> insights; // 7-10 insights

  MonthlySummary({
    this.id,
    required this.monthYear,
    required this.totalSpend,
    required this.spendByCategory,
    required this.topMerchants,
    required this.runwayMonths,
    required this.transactionCount,
    required this.insights,
  });

  // Getter: Calculate average daily spend
  double get averageDailySpend {
    return totalSpend / 30; // Approx 30 days per month
  }

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monthYear': monthYear,
      'totalSpend': totalSpend,
      'spendByCategory': spendByCategory, // Will need JSON encoding for SQLite
      'topMerchants': topMerchants,
      'runwayMonths': runwayMonths,
      'transactionCount': transactionCount,
      'insights': insights,
    };
  }

  factory MonthlySummary.fromMap(Map<String, dynamic> map) {
    return MonthlySummary(
      id: map['id'] as int?,
      monthYear: map['monthYear'] as String,
      totalSpend: (map['totalSpend'] as num).toDouble(),
      spendByCategory: (map['spendByCategory'] as Map).map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      ),
      topMerchants: List<String>.from(map['topMerchants'] as List),
      runwayMonths: (map['runwayMonths'] as num).toDouble(),
      transactionCount: map['transactionCount'] as int,
      insights: List<String>.from(map['insights'] as List),
    );
  }
}
