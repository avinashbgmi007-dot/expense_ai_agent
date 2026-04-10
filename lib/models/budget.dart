// lib/models/budget.dart
class Budget {
  final int? id;
  final int accountId;
  final String category;
  final double monthlyLimit;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double spentAmount;
  final double alertThreshold; // 0.0 to 1.0
  final bool isActive;
  final DateTime createdAt;

  const Budget({
    this.id,
    required this.accountId,
    required this.category,
    required this.monthlyLimit,
    required this.periodStart,
    required this.periodEnd,
    this.spentAmount = 0.0,
    this.alertThreshold = 0.8,
    this.isActive = true,
    required this.createdAt,
  });

  Budget copyWith({
    int? id,
    int? accountId,
    String? category,
    double? monthlyLimit,
    DateTime? periodStart,
    DateTime? periodEnd,
    double? spentAmount,
    double? alertThreshold,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      spentAmount: spentAmount ?? this.spentAmount,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'category': category,
      'monthlyLimit': monthlyLimit,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'spentAmount': spentAmount,
      'alertThreshold': alertThreshold,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as int?,
      accountId: json['accountId'] as int,
      category: json['category'] as String,
      monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0.0,
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble() ?? 0.8,
      isActive: (json['isActive'] as int?) == 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Computed properties
  double get remainingAmount => monthlyLimit - spentAmount;
  double get spentPercentage => monthlyLimit > 0 ? spentAmount / monthlyLimit : 0.0;
  bool get isOverBudget => spentAmount > monthlyLimit;
  bool get shouldAlert => spentPercentage >= alertThreshold;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget &&
        other.id == id &&
        other.accountId == accountId &&
        other.category == category &&
        other.monthlyLimit == monthlyLimit &&
        other.periodStart == periodStart &&
        other.periodEnd == periodEnd &&
        other.spentAmount == spentAmount &&
        other.alertThreshold == alertThreshold &&
        other.isActive == isActive &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      accountId,
      category,
      monthlyLimit,
      periodStart,
      periodEnd,
      spentAmount,
      alertThreshold,
      isActive,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Budget(id: $id, category: $category, limit: $monthlyLimit, spent: $spentAmount)';
  }
}