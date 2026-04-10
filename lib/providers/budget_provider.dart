import 'package:flutter/foundation.dart';
import 'package:expense_ai_agent/models/budget.dart';
import 'package:expense_ai_agent/services/sqlite_database_service.dart';

class BudgetProvider with ChangeNotifier {
  final SQLiteDatabaseService _databaseService;

  BudgetProvider({SQLiteDatabaseService? databaseService})
      : _databaseService = databaseService ?? SQLiteDatabaseService();

  bool _isLoading = false;
  String? _error;
  List<Budget> _budgets = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Budget> get budgets => _budgets;

  List<Budget> get activeBudgets => 
      _budgets.where((b) => b.isActive).toList();

  double get totalBudgeted => 
      _budgets.fold(0.0, (sum, b) => sum + b.monthlyLimit);

  double get totalSpent => 
      _budgets.fold(0.0, (sum, b) => sum + b.spentAmount);

  double get overallProgress => 
      totalBudgeted > 0 ? totalSpent / totalBudgeted : 0.0;

  List<Budget> get overBudgetItems => 
      _budgets.where((b) => b.isOverBudget).toList();

  List<Budget> get alertItems => 
      _budgets.where((b) => b.shouldAlert && !b.isOverBudget).toList();

  List<Budget> budgetsByAccount(int accountId) =>
      _budgets.where((b) => b.accountId == accountId).toList();

  Future<void> loadBudgets({int? accountId, bool? isActive}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _budgets = await _databaseService.getBudgets(
        accountId: accountId,
        isActive: isActive,
      );
    } catch (e) {
      _error = 'Failed to load budgets: $e';
      _budgets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBudget(Budget budget) async {
    try {
      final id = await _databaseService.insertBudget(budget);
      final newBudget = budget.copyWith(id: id);
      _budgets.add(newBudget);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add budget: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      await _databaseService.updateBudget(budget);
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index >= 0) {
        _budgets[index] = budget;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update budget: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBudget(int id) async {
    try {
      await _databaseService.deleteBudget(id);
      _budgets.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete budget: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSpentAmount(int budgetId, double spentAmount) async {
    final index = _budgets.indexWhere((b) => b.id == budgetId);
    if (index >= 0) {
      final updatedBudget = _budgets[index].copyWith(spentAmount: spentAmount);
      await updateBudget(updatedBudget);
    }
  }

  Future<void> refresh() async {
    await loadBudgets();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Budget? getBudgetById(int? id) {
    if (id == null) return null;
    try {
      return _budgets.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  Budget? getBudgetByCategory(String category, int accountId) {
    try {
      return _budgets.firstWhere(
        (b) => b.category == category && b.accountId == accountId,
      );
    } catch (e) {
      return null;
    }
  }
}