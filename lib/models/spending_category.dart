// lib/models/spending_category.dart

class SpendingCategory {
  final int id;
  final String name;
  final String description;
  final double totalAmount;
  final int transactionCount;

  const SpendingCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.totalAmount,
    required this.transactionCount,
  });
}
