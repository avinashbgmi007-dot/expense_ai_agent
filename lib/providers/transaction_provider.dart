import 'package:flutter/foundation.dart';
import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/services/database_service.dart';

class TransactionProvider with ChangeNotifier {
  final DatabaseService _databaseService;

  TransactionProvider({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  bool _isLoading = false;
  String? _error;
  List<Transaction> _transactions = [];
  TransactionFilter _currentFilter = TransactionFilter();

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Transaction> get transactions => _transactions;
  TransactionFilter get currentFilter => _currentFilter;

  // Computed properties
  double get totalAmount => _transactions.fold(0.0, (sum, tx) => sum + tx.amount);
  int get transactionCount => _transactions.length;

  Map<String, double> get spendingByCategory {
    final categoryTotals = <String, double>{};
    for (final transaction in _transactions) {
      final category = transaction.category;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount;
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
      final loadedTransactions = await _databaseService.getTransactions(
        accountId: _currentFilter.accountId,
        category: _currentFilter.category,
        startDate: _currentFilter.startDate,
        endDate: _currentFilter.endDate,
        searchQuery: _currentFilter.searchQuery,
        limit: _currentFilter.limit,
        offset: _currentFilter.offset,
      );

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
  Future<void> addTransaction(Transaction transaction) async {
    try {
      final id = await _databaseService.insertTransaction(transaction);
      final newTransaction = transaction.copyWith(id: id);

      // Add to local list if it matches current filter
      if (_matchesFilter(newTransaction)) {
        _transactions.insert(0, newTransaction);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add transaction: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Update an existing transaction
  Future<void> updateTransaction(Transaction transaction) async {
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
  Future<void> deleteTransaction(int id) async {
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
  Future<void> addTransactions(List<Transaction> transactions) async {
    try {
      final ids = await _databaseService.insertTransactions(transactions);

      // Add to local list with assigned IDs
      for (var i = 0; i < transactions.length; i++) {
        final transaction = transactions[i].copyWith(id: ids[i]);
        if (_matchesFilter(transaction)) {
          _transactions.insert(0, transaction);
        }
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to add transactions: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Get transaction by ID
  Future<Transaction?> getTransaction(int id) async {
    try {
      // First check local list
      final localTransaction = _transactions.cast<Transaction?>().firstWhere(
            (tx) => tx?.id == id,
            orElse: () => null,
          );

      if (localTransaction != null) {
        return localTransaction;
      }

      // Otherwise fetch from database
      return await _databaseService.getTransaction(id);
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
    await loadTransactions(filter: TransactionFilter());
  }

  // Refresh current data
  Future<void> refresh() async {
    await loadTransactions(filter: _currentFilter);
  }

  // Check if transaction matches current filter
  bool _matchesFilter(Transaction transaction) {
    if (_currentFilter.accountId != null &&
        transaction.accountId != _currentFilter.accountId) {
      return false;
    }

    if (_currentFilter.category != null &&
        transaction.category != _currentFilter.category) {
      return false;
    }

    if (_currentFilter.startDate != null &&
        transaction.date.isBefore(_currentFilter.startDate!)) {
      return false;
    }

    if (_currentFilter.endDate != null &&
        transaction.date.isAfter(_currentFilter.endDate!)) {
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