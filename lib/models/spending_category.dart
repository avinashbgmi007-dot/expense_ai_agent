// lib/models/spending_category.dart

import 'transaction.dart';

enum SpendingCategory {
  food,
  transport,
  utilities,
  subscriptions,
  shopping,
  health,
  education,
  entertainment,
  miscellaneous,
}

class CategorySpend {
  final SpendingCategory category;
  final double totalAmount;
  final int transactionCount;
  final double percentageOfTotal;
  final List<String> topMerchants; // Top 5 merchants in this category

  CategorySpend({
    required this.category,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentageOfTotal,
    required this.topMerchants,
  });

  // Factory: Create from list of transactions
  factory CategorySpend.fromTransactions(
    List<TransactionModel> transactions,
    SpendingCategory cat,
    double totalSpend,
  ) {
    final catTransactions = transactions
        .where((t) => t.category.toLowerCase() == cat.name)
        .toList();

    if (catTransactions.isEmpty) {
      return CategorySpend(
        category: cat,
        totalAmount: 0,
        transactionCount: 0,
        percentageOfTotal: 0,
        topMerchants: [],
      );
    }

    final total = catTransactions.fold<double>(0, (sum, t) => sum + t.amount);

    // Get top merchants
    final merchantMap = <String, double>{};
    for (var t in catTransactions) {
      merchantMap[t.merchant ?? 'Unknown'] = (merchantMap[t.merchant ?? 'Unknown'] ?? 0) + t.amount;
    }
    final sortedMerchants = merchantMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topMerchants = sortedMerchants.take(5).map((e) => e.key).toList();

    return CategorySpend(
      category: cat,
      totalAmount: total,
      transactionCount: catTransactions.length,
      percentageOfTotal: totalSpend > 0 ? (total / totalSpend) * 100 : 0,
      topMerchants: topMerchants,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category.name,
      'totalAmount': totalAmount,
      'transactionCount': transactionCount,
      'percentageOfTotal': percentageOfTotal,
      'topMerchants': topMerchants,
    };
  }

  factory CategorySpend.fromMap(Map<String, dynamic> map) {
    return CategorySpend(
      category: SpendingCategory.values.firstWhere(
        (e) => e.name == map['category'],
      ),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      transactionCount: map['transactionCount'] as int,
      percentageOfTotal: (map['percentageOfTotal'] as num).toDouble(),
      topMerchants: List<String>.from(map['topMerchants'] as List),
    );
  }
}
