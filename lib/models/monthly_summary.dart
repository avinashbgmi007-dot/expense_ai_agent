import 'package:intl/intl.dart';

/// Monthly summary model.
class MonthlySummary {
  /// Constructs a new [MonthlySummary].
  const MonthlySummary({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
  });

  /// Year.
  final int year;

  /// Month.
  final int month;

  /// Total income.
  final double totalIncome;

  /// Total expenses.
  final double totalExpenses;

  /// Net profit.
  final double netProfit;

  /// Returns formatted month name.
  String get monthName {
    return DateFormat('MMMM').format(DateTime(year, month));
  }

  @override
  String toString() =>
      'MonthlySummary($year-$month: income=$totalIncome, expenses=$totalExpenses, profit=$netProfit)';
}
