import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/analyzer_service.dart';
import '../services/database_service.dart';
import '../services/ai_categorization_service.dart';
import '../services/leak_detection_service.dart';
import '../services/insight_generator_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final AnalyzerService _analyzerService = AnalyzerService();
  final AICategorizationService _categorizationService = AICategorizationService();
  final LeakDetectionService _leakDetectionService = LeakDetectionService();
  final InsightGeneratorService _insightService = InsightGeneratorService();

  Map<String, dynamic> _analyticsData = {};
  bool _loading = false;
  String? _error;

  // Cache for categorized transactions — avoids re-categorizing on every call
  List<TransactionModel>? _cachedTransactions;
  int? _lastTxnCount; // invalidate cache when count changes

  bool get loading => _loading;
  Map<String, dynamic> get data => _analyticsData;
  String? get error => _error;

  Future<void> loadData() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _databaseService.initialize();
      final transactions = getSortedTransactions();

      if (transactions.isEmpty) {
        _analyticsData = {
          'totalSpend': 0.0,
          'transactionCount': 0,
          'spendByMerchant': {},
          'spendByCategory': {},
          'repeatedTransactions': [],
          'upiUsagePercentage': 0.0,
          'leaks': {},
          'subscriptions': [],
          'insights': [],
        };
        _loading = false;
        notifyListeners();
        return;
      }

      final totalSpend = _analyzerService.calculateTotalSpend(transactions);
      final spendByMerchant = _analyzerService.spendByMerchant(transactions);
      final repeatedTransactions = _analyzerService.detectRepeats(transactions);
      final upiUsage = _analyzerService.upiUsagePercentage(transactions);

      Map<String, double> spendByCategory = {};
      for (var transaction in transactions) {
        final category = transaction.category.isNotEmpty
            ? transaction.category
            : 'miscellaneous';
        spendByCategory[category] =
            (spendByCategory[category] ?? 0) + transaction.amount;
      }

      final leaks = _leakDetectionService.detectLeaks(transactions);
      final insights = _insightService.generateInsights(transactions);

      _analyticsData = {
        'totalSpend': totalSpend,
        'transactionCount': transactions.length,
        'spendByMerchant': spendByMerchant,
        'spendByCategory': spendByCategory,
        'repeatedTransactions': repeatedTransactions
            .map(
              (t) => {
                'merchant': t.merchant,
                'amount': t.amount,
                'date': t.formattedDateTime,
              },
            )
            .toList(),
        'upiUsagePercentage': upiUsage,
        'leaks': leaks,
        'subscriptions': repeatedTransactions
            .map(
              (t) => {
                'merchant': t.merchant,
                'amount': t.amount,
                'date': t.formattedDateTime,
              },
            )
            .toList(),
        'insights': insights,
      };
    } catch (e) {
      _error = 'Failed to load analytics: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<TransactionModel> getSortedTransactions() {
    try {
      final txns = _databaseService.getTransactions();
      final count = txns.length;

      // Return cached version if transaction count hasn't changed
      if (_cachedTransactions != null && _lastTxnCount == count) {
        return _cachedTransactions!;
      }

      // Recategorize — transaction count changed
      final categorized = txns.map((t) {
        // If already categorized from import, use it; otherwise apply AI
        final existingCat = t.category;
        if (existingCat.isNotEmpty && existingCat != 'miscellaneous') return t;
        return t.copyWith(
          category: _categorizationService.categorizeWithDescription(
            t.merchant ?? '',
            t.description ?? '',
            t.credit,
            t.amount,
          ),
        );
      }).toList();
      categorized.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _cachedTransactions = categorized;
      _lastTxnCount = count;
      return categorized;
    } catch (e) {
      return [];
    }
  }

  Future<void> addTransaction(TransactionModel txn) async {
    try {
      await _databaseService.initialize();
      await _databaseService.insertTransaction(txn);
      _cachedTransactions = null; // invalidate cache
      _lastTxnCount = null;
      await loadData();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }

  Future<void> removeTransaction(String id) async {
    try {
      await _databaseService.initialize();
      await _databaseService.deleteTransaction(id);
      _cachedTransactions = null; // invalidate cache
      _lastTxnCount = null;
      await loadData();
    } catch (e) {
      debugPrint('Error removing transaction: $e');
    }
  }

  int getTransactionCount() {
    return getSortedTransactions().length;
  }

  Map<String, dynamic> getSpendingByCategory() {
    return _analyticsData['spendByCategory'] ?? {};
  }

  List<MapEntry<String, dynamic>> getTopMerchants() {
    final byMerchant = _analyticsData['spendByMerchant'] as Map<String, dynamic>? ?? {};
    return byMerchant.entries
        .toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
  }

  Map<String, dynamic> getLeaks() {
    return _analyticsData['leaks'] as Map<String, dynamic>? ?? {};
  }

  List<dynamic> getSubscriptions() {
    return _analyticsData['subscriptions'] ?? [];
  }

  List<dynamic> getInsights() {
    return _analyticsData['insights'] ?? [];
  }
}
