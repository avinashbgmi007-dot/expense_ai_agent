import 'package:flutter/foundation.dart';
import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/services/database_service.dart';

class TransactionProvider with ChangeNotifier {
  final DatabaseService _databaseService;

  TransactionProvider({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  bool _isLoading = false;
  String? _error;
  List<TransactionModel> _transactions = [];
  TransactionFilter _currentFilter = TransactionFilter();

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<TransactionModel> get transactions => _transactions;
  TransactionFilter get currentFilter => _currentFilter;

  // Computed properties
  double get totalAmount =>
      _transactions.fold(0.0, (sum, tx) => sum + tx.amount);
  int get transactionCount => _transactions.length;

  Map<String, double> get spendingByCategory {
    final categoryTotals = <String, double>{};
    for (final transaction in _transactions) {
      final category = transaction.category;
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + transaction.amount;
    }
    return categoryTotals;
  }

  // Load transactions with optional filtering
  Future<void> loadTransactions({TransactionFilter? filter}) async {
    _isLoading = true;
    _error = null;
    _currentFilter = filter ?? TransactionFilter();
    notifyListeners();

    try {
      await _databaseService.initialize();
      final loadedTransactions = _databaseService.getTransactions();

      _transactions = loadedTransactions;
    } catch (e) {
      _error = 'Failed to load transactions: $e';
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _databaseService.initialize();
      await _databaseService.insertTransaction(transaction);

      // Add to local list if it matches current filter
      if (_matchesFilter(transaction)) {
        _transactions.add(transaction);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add transaction: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Update an existing transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _databaseService.updateTransaction(transaction);

      // Update in local list
      final index = _transactions.indexWhere((tx) => tx.id == transaction.id);
      if (index >= 0) {
        _transactions[index] = transaction;

        // Check if it still matches filter
        if (!_matchesFilter(transaction)) {
          _transactions.removeAt(index);
        }

        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update transaction: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await _databaseService.deleteTransaction(id);

      // Remove from local list
      _transactions.removeWhere((tx) => tx.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete transaction: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Bulk add transactions
  Future<void> addTransactions(List<TransactionModel> transactions) async {
    try {
      for (final transaction in transactions) {
        await _databaseService.insertTransaction(transaction);
        _transactions.add(transaction);
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to add transactions: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Get transaction by ID
  Future<TransactionModel?> getTransaction(String id) async {
    try {
      // First check local list
      final localIndex = _transactions.indexWhere((tx) => tx.id == id);
      if (localIndex != -1) {
        return _transactions[localIndex];
      }

      // Otherwise fetch from database
      await _databaseService.initialize();
      final allTransactions = _databaseService.getTransactions();
      final dbIndex = allTransactions.indexWhere((tx) => tx.id == id);
      if (dbIndex != -1) {
        return allTransactions[dbIndex];
      }

      return null;
    } catch (e) {
      _error = 'Failed to get transaction: $e';
      notifyListeners();
      return null;
    }
  }

  // Apply new filter
  Future<void> applyFilter(TransactionFilter filter) async {
    await loadTransactions(filter: filter);
  }

  // Clear current filter
  Future<void> clearFilter() async {
    await loadTransactions(filter: _currentFilter);
  }

  // Refresh current data
  Future<void> refresh() async {
    await loadTransactions(filter: _currentFilter);
  }

  // Check if transaction matches current filter
  bool _matchesFilter(TransactionModel transaction) {
    // Note: TransactionModel doesn't have accountId, date properties
    // We'll filter based on category and search query only

    if (_currentFilter.category != null &&
        transaction.category != _currentFilter.category) {
      return false;
    }

    if (_currentFilter.searchQuery != null &&
        _currentFilter.searchQuery!.isNotEmpty) {
      final query = _currentFilter.searchQuery!.toLowerCase();
      final merchant = transaction.merchant?.toLowerCase() ?? '';
      final description = transaction.description?.toLowerCase() ?? '';

      if (!merchant.contains(query) && !description.contains(query)) {
        return false;
      }
    }

    return true;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Transaction filter class
class TransactionFilter {
  final int? accountId;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final int? limit;
  final int? offset;

  const TransactionFilter({
    this.accountId,
    this.category,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });

  TransactionFilter copyWith({
    int? accountId,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? limit,
    int? offset,
  }) {
    return TransactionFilter(
      accountId: accountId ?? this.accountId,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  bool get isEmpty =>
      accountId == null &&
      category == null &&
      startDate == null &&
      endDate == null &&
      (searchQuery == null || searchQuery!.isEmpty);

  @override
  String toString() {
    return 'TransactionFilter(accountId: $accountId, category: $category, '
        'startDate: $startDate, endDate: $endDate, searchQuery: $searchQuery, '
        'limit: $limit, offset: $offset)';
  }
}
