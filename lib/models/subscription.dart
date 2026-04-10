// lib/models/subscription.dart

enum SubscriptionFrequency {
  daily,
  weekly,
  biWeekly,
  monthly,
  quarterly,
  annual,
}

class SubscriptionModel {
  final int? id;
  final String merchant;
  final double amount;
  final SubscriptionFrequency frequency;
  final String category;
  final DateTime firstObservedDate;
  final DateTime lastObservedDate;
  final int totalOccurrences;
  final double confidence; // 0.0 to 1.0
  final bool isConfirmed; // User validated
  final DateTime? cancelledDate;

  SubscriptionModel({
    this.id,
    required this.merchant,
    required this.amount,
    required this.frequency,
    required this.category,
    required this.firstObservedDate,
    required this.lastObservedDate,
    required this.totalOccurrences,
    required this.confidence,
    required this.isConfirmed,
    this.cancelledDate,
  });

  // Getter: Calculate monthly impact (for display)
  double get monthlyImpact {
    switch (frequency) {
      case SubscriptionFrequency.daily:
        return amount * 30; // ₹50/day = ₹1500/month
      case SubscriptionFrequency.weekly:
        return amount * 4.3; // ₹100/week = ₹430/month
      case SubscriptionFrequency.biWeekly:
        return amount * 2.15; // ₹200/2weeks = ₹430/month
      case SubscriptionFrequency.monthly:
        return amount; // Already monthly
      case SubscriptionFrequency.quarterly:
        return amount / 3; // ₹900/3months = ₹300/month
      case SubscriptionFrequency.annual:
        return amount / 12; // ₹7200/year = ₹600/month
    }
  }

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'frequency': frequency.toString(),
      'category': category,
      'firstObservedDate': firstObservedDate.toIso8601String(),
      'lastObservedDate': lastObservedDate.toIso8601String(),
      'totalOccurrences': totalOccurrences,
      'confidence': confidence,
      'isConfirmed': isConfirmed,
      'cancelledDate': cancelledDate?.toIso8601String(),
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] as int?,
      merchant: map['merchant'] as String,
      amount: (map['amount'] as num).toDouble(),
      frequency: _parseFrequency(map['frequency'] as String),
      category: map['category'] as String,
      firstObservedDate: DateTime.parse(map['firstObservedDate'] as String),
      lastObservedDate: DateTime.parse(map['lastObservedDate'] as String),
      totalOccurrences: map['totalOccurrences'] as int,
      confidence: (map['confidence'] as num).toDouble(),
      isConfirmed: map['isConfirmed'] == true || map['isConfirmed'] == 1,
      cancelledDate: map['cancelledDate'] != null
          ? DateTime.parse(map['cancelledDate'] as String)
          : null,
    );
  }

  static SubscriptionFrequency _parseFrequency(String freq) {
    return SubscriptionFrequency.values.firstWhere(
      (e) => e.toString().split('.').last == freq.split('.').last,
      orElse: () => SubscriptionFrequency.monthly,
    );
  }
}
