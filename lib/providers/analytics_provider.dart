import 'package:flutter/foundation.dart';

import '../services/analyzer_service.dart';
import '../services/database_service.dart';
import '../services/ai_categorization_service.dart';
import '../services/leak_detection_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final AnalyzerService _analyzerService = AnalyzerService();
  final AICategorizationService _categorizationService =
      AICategorizationService();
  final LeakDetectionService _leakDetectionService = LeakDetectionService();

  Map<String, dynamic> _analyticsData = {};
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  Map<String, dynamic> get data => _analyticsData;
  String? get error => _error;

  Future<void> loadData() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _databaseService.initialize();
      final transactions = _databaseService.getTransactions();

      if (transactions.isEmpty) {
        _analyticsData = {
          'totalSpend': 0.0,
          'transactionCount': 0,
          'spendByMerchant': {},
          'spendByCategory': {},
          'repeatedTransactions': [],
          'upiUsagePercentage': 0.0,
          'leaks': {'subscriptions': 0.0, 'smallTransactions': 0.0},
          'subscriptions': [],
        };
        _loading = false;
        notifyListeners();
        return;
      }

      // Calculate analytics using the analyzer service
      final totalSpend = _analyzerService.calculateTotalSpend(transactions);
      final spendByMerchant = _analyzerService.spendByMerchant(transactions);
      final repeatedTransactions = _analyzerService.detectRepeats(transactions);
      final upiUsage = _analyzerService.upiUsagePercentage(transactions);

      // Calculate spend by category
      Map<String, double> spendByCategory = {};
      for (var transaction in transactions) {
        final merchant = transaction.merchant ?? 'Unknown';
        final category = _categorizationService.categorize(merchant);
        spendByCategory[category] =
            (spendByCategory[category] ?? 0) + transaction.amount;
      }

      // Detect leaks
      final leaks = _leakDetectionService.detectLeaks(transactions);

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
      };
    } catch (e, _) {
      _error = 'Failed to load analytics: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> getSpendingByCategory() {
    return _analyticsData['spendByCategory'] ?? {};
  }

  List<dynamic> getTopMerchants() {
    return _analyticsData['topMerchants'] ?? [];
  }

  Map<String, dynamic> getLeaks() {
    return _analyticsData['leaks'] ?? {};
  }

  List<dynamic> getSubscriptions() {
    return _analyticsData['subscriptions'] ?? [];
  }

  List<dynamic> getInsights() {
    return _analyticsData['insights'] ?? [];
  }
}
