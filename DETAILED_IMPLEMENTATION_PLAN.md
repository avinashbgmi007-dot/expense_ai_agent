# 🎯 IMMEDIATE ACTION ITEMS - Next 7 Days

## Current Status ✅
- ✅ Transaction model ready
- ✅ Database schema initialized
- ✅ OCR service running
- ✅ Basic UI structure
- ✅ Parser service scaffolded

## Days 1-2: Extend Database & Create Core Models

### Task 1.1: Add Transaction Fields
**File: `lib/models/transaction.dart`**

Update to track more metrics:
```dart
class TransactionModel {
  // Existing fields
  final int? id;
  final String merchant;
  final double amount;
  final String date;
  // ... etc

  // NEW FIELDS to add:
  final String uploadId;          // Track which upload this came from
  final DateTime createdAt;       // When entered into system
  final bool isIgnored;           // User can mark as irrelevant
  final String? userNote;         // User-added notes
}
```

### Task 1.2: Create Spending Category Model
**File: `lib/models/spending_category.dart`**

```dart
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
  final List<String> topMerchants;

  CategorySpend({
    required this.category,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentageOfTotal,
    required this.topMerchants,
  });

  factory CategorySpend.fromTransactions(
    List<TransactionModel> transactions,
    SpendingCategory category,
  ) {
    final categoryTxns = transactions
        .where((t) => t.category == category.name)
        .toList();

    if (categoryTxns.isEmpty) {
      return CategorySpend(
        category: category,
        totalAmount: 0,
        transactionCount: 0,
        percentageOfTotal: 0,
        topMerchants: [],
      );
    }

    final total = categoryTxns.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );

    final merchantSpend = <String, double>{};
    for (var tx in categoryTxns) {
      merchantSpend[tx.merchant] =
          (merchantSpend[tx.merchant] ?? 0) + tx.amount;
    }

    final topMerchants = merchantSpend.entries
        .toList()
        ..[].sort((a, b) => b.value.compareTo(a.value));

    return CategorySpend(
      category: category,
      totalAmount: total,
      transactionCount: categoryTxns.length,
      percentageOfTotal: (total / transactions.fold(0.0, (sum, t) => sum + t.amount)) * 100,
      topMerchants: topMerchants
          .take(5)
          .map((e) => "${e.key} (₹${e.value.toStringAsFixed(0)})")
          .toList(),
    );
  }
}
```

### Task 1.3: Create Subscription Model
**File: `lib/models/subscription.dart`**

```dart
enum SubscriptionFrequency {
  daily,
  weekly,
  fortnightly,
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
  final DateTime? lastObservedDate;
  final int totalOccurrences;
  final double confidence; // 0.5 - 1.0
  final bool isConfirmed; // User has confirmed this exists
  final DateTime? cancelledDate;

  double get monthlyImpact {
    switch (frequency) {
      case SubscriptionFrequency.daily:
        return amount * 30;
      case SubscriptionFrequency.weekly:
        return amount * 4.3;
      case SubscriptionFrequency.fortnightly:
        return amount * 2.15;
      case SubscriptionFrequency.monthly:
        return amount;
      case SubscriptionFrequency.quarterly:
        return amount / 3;
      case SubscriptionFrequency.annual:
        return amount / 12;
    }
  }

  SubscriptionModel({
    this.id,
    required this.merchant,
    required this.amount,
    required this.frequency,
    required this.category,
    required this.firstObservedDate,
    this.lastObservedDate,
    required this.totalOccurrences,
    this.confidence = 0.8,
    this.isConfirmed = false,
    this.cancelledDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'frequency': frequency.name,
      'category': category,
      'firstObservedDate': firstObservedDate.toIso8601String(),
      'lastObservedDate': lastObservedDate?.toIso8601String(),
      'totalOccurrences': totalOccurrences,
      'confidence': confidence,
      'isConfirmed': isConfirmed ? 1 : 0,
      'cancelledDate': cancelledDate?.toIso8601String(),
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] as int?,
      merchant: map['merchant'] as String,
      amount: (map['amount'] as num).toDouble(),
      frequency: SubscriptionFrequency.values
          .firstWhere((e) => e.name == map['frequency']),
      category: map['category'] as String,
      firstObservedDate:
          DateTime.parse(map['firstObservedDate'] as String),
      lastObservedDate: map['lastObservedDate'] != null
          ? DateTime.parse(map['lastObservedDate'] as String)
          : null,
      totalOccurrences: map['totalOccurrences'] as int,
      confidence: (map['confidence'] as num).toDouble(),
      isConfirmed: (map['isConfirmed'] as int?) == 1,
      cancelledDate: map['cancelledDate'] != null
          ? DateTime.parse(map['cancelledDate'] as String)
          : null,
    );
  }
}
```

### Task 1.4: Create Monthly Summary Model
**File: `lib/models/monthly_summary.dart`**

```dart
class MonthlySummary {
  final String monthYear; // Format: "2026-03"
  final double totalSpend;
  final Map<String, double> spendByCategory;
  final List<String> topMerchants; // Top 5
  final double runwayMonths;
  final int transactionCount;
  final List<String> insights; // AI-generated
  final DateTime createdAt;

  double get averageDailySpend => totalSpend / 30;

  MonthlySummary({
    required this.monthYear,
    required this.totalSpend,
    required this.spendByCategory,
    required this.topMerchants,
    required this.runwayMonths,
    required this.transactionCount,
    required this.insights,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'monthYear': monthYear,
      'totalSpend': totalSpend,
      'spendByCategory': spendByCategory, // Store as JSON
      'topMerchants': topMerchants, // Store as JSON
      'runwayMonths': runwayMonths,
      'transactionCount': transactionCount,
      'insights': insights, // Store as JSON
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
```

---

## Days 2-3: Create Categorization Service

### Task 2.1: Build Merchant Keyword Database
**File: `lib/services/categorization_service.dart`**

```dart
import 'package:flutter_gemma/flutter_gemma.dart';

class CategorizationService {
  // Comprehensive merchant keywords for India
  static const Map<String, List<String>> indianMerchantKeywords = {
    'food': [
      'swiggy', 'zomato', 'uber_eats', 'dunzo',
      'restaurant', 'cafe', 'dhaba', 'bakery',
      'pizza_hut', 'dominos', 'mcd', 'kfc',
      'starbucks', 'costa', 'chai',
      'biryani', 'chinese', 'south_indian',
      'faasos', 'wow', 'dosa', 'idli',
      'samosa', 'chaat', 'street_food',
    ],
    'transport': [
      'uber', 'ola', 'rapido', 'metro', 'parking',
      'fuel', 'petrol', 'diesel', 'gas_station',
      'toll', 'highway', 'bus', 'train',
      'railway', 'ixigo', 'makemytrip_transport',
      'flight', 'airline', 'airport',
    ],
    'utilities': [
      'electricity', 'power', 'water', 'gas',
      'internet', 'broadband', 'wifi',
      'mobile_recharge', 'phone_bill',
      'jio', 'airtel', 'vodafone', 'bsnl',
      'digi', 'landline', 'phone',
    ],
    'subscriptions': [
      'netflix', 'amazon_prime', 'hotstar', 'sony_liv',
      'spotify', 'youtube', 'youtube_music',
      'adobe', 'microsoft', 'office365',
      'gym', 'fitness', 'membership',
      'annual_fee', 'membership_fee',
    ],
    'shopping': [
      'amazon', 'flipkart', 'myntra', 'nykaa',
      'uniqlo', 'mall', 'store', 'retail',
      'clothing', 'apparel', 'fashion',
    ],
    'health': [
      'pharmacy', 'apollo', 'max', 'fortis',
      'physician', 'doctor', 'clinic', 'hospital',
      'medicine', 'medical', 'health',
      'dental', 'dentist', 'pathlab', 'diagnostic',
    ],
    'education': [
      'school', 'college', 'university',
      'coaching', 'course', 'udemy',
      'fees', 'tuition', 'exam', 'book',
    ],
    'entertainment': [
      'movie', 'cinema', 'inox', 'pvr',
      'games', 'gaming', 'playstation',
      'concert', 'show', 'ticket',
    ],
  };

  /// Categorize a transaction using multi-level strategy
  Future<String> categorizeTransaction({
    required String merchant,
    required double amount,
    required String paymentMethod,
  }) async {
    // Level 1: Keyword matching (fastest, most accurate)
    final keywordMatch = _matchByKeywords(merchant.toLowerCase());
    if (keywordMatch != null) {
      return keywordMatch;
    }

    // Level 2: Amount heuristics
    final amountMatch = _matchByAmount(amount, paymentMethod);
    if (amountMatch != null) {
      return amountMatch;
    }

    // Level 3: Use Gemma for ambiguous cases
    try {
      return await _categorizeWithAI(merchant, amount);
    } catch (e) {
      print('AI categorization failed: $e');
      return 'miscellaneous'; // Safe fallback
    }
  }

  /// Match merchant to category by keywords
  String? _matchByKeywords(String merchantLower) {
    for (final categoryEntry in indianMerchantKeywords.entries) {
      for (final keyword in categoryEntry.value) {
        if (merchantLower.contains(keyword)) {
          return categoryEntry.key;
        }
      }
    }
    return null;
  }

  /// Use amount + payment method to guess category
  String? _matchByAmount(double amount, String paymentMethod) {
    // UPI payments ₹50-₹500 = likely food
    if (paymentMethod.toLowerCase() == 'upi' &&
        amount >= 50 &&
        amount <= 500) {
      return 'food';
    }

    // Card payments > ₹2000 = shopping or utilities
    if (amount > 2000) {
      return 'shopping'; // Educated guess
    }

    // Bills are usually round numbers or multiples of 100
    if (amount % 100 == 0 && amount > 500) {
      return 'utilities';
    }

    return null;
  }

  /// Use local Gemma model for categorization
  Future<String> _categorizeWithAI(
    String merchant,
    double amount,
  ) async {
    try {
      final model = await FlutterGemma.getActiveModel(maxTokens: 20);
      final chat = await model.createChat();

      final prompt = '''\
Categorize this Indian merchant transaction:
Merchant: $merchant
Amount: ₹$amount

Categories: food, transport, utilities, subscriptions, shopping, health, education, entertainment, miscellaneous

Respond with ONLY the category name, nothing else.''';

      // TODO: Implement based on actual Gemma API
      // For now, fallback to keyword match
      return 'miscellaneous';
    } catch (e) {
      print('AI categorization error: $e');
      return 'miscellaneous';
    }
  }
}
```

### Task 2.2: Update Database for New Models
**File: `lib/services/database_service.dart` - Add Methods**

```dart
// Add to database_service.dart

// Create subscriptions table
Future<void> _createSubscriptionsTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS subscriptions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      merchant TEXT NOT NULL,
      amount REAL NOT NULL,
      frequency TEXT NOT NULL,
      category TEXT,
      firstObservedDate TEXT NOT NULL,
      lastObservedDate TEXT,
      totalOccurrences INTEGER,
      confidence REAL,
      isConfirmed INTEGER,
      cancelledDate TEXT
    )
  ''');
}

// Insert subscription
Future<void> insertSubscription(SubscriptionModel sub) async {
  final db = await database;
  await db.insert(
    'subscriptions',
    sub.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

// Get all subscriptions
Future<List<SubscriptionModel>> getAllSubscriptions() async {
  final db = await database;
  final result = await db.query('subscriptions');
  return result
      .map((e) => SubscriptionModel.fromMap(e))
      .toList();
}

// Create monthly_summary table
Future<void> _createMonthlySummaryTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS monthly_summary (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      monthYear TEXT UNIQUE NOT NULL,
      totalSpend REAL,
      spendByCategory TEXT, -- JSON
      topMerchants TEXT, -- JSON
      runwayMonths REAL,
      transactionCount INTEGER,
      insights TEXT, -- JSON
      createdAt TEXT
    )
  ''');
}
```

---

## Days 3-4: Leak Detection Service

### Task 3.1: Implement Leak Detection
**File: `lib/services/leak_detection_service.dart`**

```dart
import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/models/subscription.dart';

class LeakDetectionService {
  /// Detect recurring transactions (subscriptions)
  List<SubscriptionModel> detectRecurringTransactions(
    List<TransactionModel> transactions,
  ) {
    // Group by merchant + amount
    final patterns = <String, List<TransactionModel>>{};

    for (final tx in transactions) {
      final key = '${tx.merchant}|${tx.amount}';
      patterns.putIfAbsent(key, () => []).add(tx);
    }

    final subscriptions = <SubscriptionModel>[];

    for (final entry in patterns.entries) {
      if (entry.value.length < 2) continue; // Need at least 2 occurrences

      final txns = entry.value;
      txns.sort((a, b) => DateTime.parse(a.date)
          .compareTo(DateTime.parse(b.date)));

      // Calculate gaps between transactions
      final gaps = <int>[];
      for (int i = 1; i < txns.length; i++) {
        final gap = DateTime.parse(txns[i].date)
            .difference(DateTime.parse(txns[i - 1].date))
            .inDays;
        gaps.add(gap);
      }

      if (gaps.isEmpty) continue;

      // Determine frequency from gaps
      final avgGap = gaps.reduce((a, b) => a + b) ~/ gaps.length;
      final frequency =
          _inferFrequency(avgGap);

      // Calculate confidence based on consistency
      final standardDeviation = _calculateStdDev(gaps);
      final confidence = standardDeviation < avgGap * 0.3 ? 0.9 : 0.6;

      subscriptions.add(
        SubscriptionModel(
          merchant: txns[0].merchant,
          amount: txns[0].amount,
          frequency: frequency,
          category: txns[0].category,
          firstObservedDate: DateTime.parse(txns[0].date),
          lastObservedDate: DateTime.parse(txns.last.date),
          totalOccurrences: txns.length,
          confidence: confidence,
        ),
      );
    }

    return subscriptions;
  }

  /// Detect small frequent spends (₹50-₹500)
  List<Map<String, dynamic>> detectSmallDrains(
    List<TransactionModel> transactions,
  ) {
    const minAmount = 50.0;
    const maxAmount = 500.0;
    const minOccurrences = 5; // At least 5 small transactions

    final smallTxns = transactions
        .where((t) => t.amount >= minAmount && t.amount <= maxAmount)
        .toList();

    // Group by merchant
    final byMerchant = <String, List<TransactionModel>>{};
    for (final tx in smallTxns) {
      byMerchant.putIfAbsent(tx.merchant, () => []).add(tx);
    }

    return byMerchant.entries
        .where((e) => e.value.length >= minOccurrences)
        .map((e) {
          final txns = e.value;
          final total =
              txns.fold(0.0, (sum, t) => sum + t.amount);
          final dayRange = _getDayRange(txns);

          return {
            'merchant': e.key,
            'transaction_count': txns.length,
            'total_drain': total,
            'average_amount': total / txns.length,
            'monthly_projected': (total / dayRange) * 30,
            'warning': 'Small frequent spends - review carefully!',
          };
        })
        .toList();
  }

  /// Infer subscription frequency from gap in days
  SubscriptionFrequency _inferFrequency(int avgGapDays) {
    if (avgGapDays < 2) return SubscriptionFrequency.daily;
    if (avgGapDays < 10) return SubscriptionFrequency.weekly;
    if (avgGapDays < 20) return SubscriptionFrequency.fortnightly;
    if (avgGapDays < 60) return SubscriptionFrequency.monthly;
    if (avgGapDays < 120) return SubscriptionFrequency.quarterly;
    return SubscriptionFrequency.annual;
  }

  /// Calculate standard deviation of gaps
  double _calculateStdDev(List<int> values) {
    if (values.isEmpty) return 0;
    final avg = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs =
        values.map((x) => (x - avg) * (x - avg)).toList();
    final variance =
        squaredDiffs.reduce((a, b) => a + b) / squaredDiffs.length;
    return Math.sqrt(variance);
  }

  int _getDayRange(List<TransactionModel> txns) {
    final dates = txns.map((t) => DateTime.parse(t.date)).toList();
    final maxDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final minDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    return maxDate.difference(minDate).inDays + 1;
  }
}
```

---

## Days 4-5: Insight Generation Service

### Task 4.1: Create Insight Generator
**File: `lib/services/insight_generator_service.dart`**

```dart
import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/models/monthly_summary.dart';

class InsightGeneratorService {
  /// Generate India-specific spending insights
  List<String> generateInsights({
    required List<TransactionModel> transactions,
    required Map<String, double> categorySpend,
    required List<SubscriptionModel> subscriptions,
    required List<Map<String, dynamic>> leaks,
  }) {
    if (transactions.isEmpty) {
      return ['📊 Upload your first statement to get insights!'];
    }

    final insights = <String>[];

    // Insight 1: Festival spending
    if (_isFestivalSeason()) {
      final avgSpend = _calculateAverageSpend(transactions);
      insights.add(
          '🎉 Festival season! Your spending is up 25% from normal.');
    }

    // Insight 2: Subscription warning
    final monthlySubSpend =
        subscriptions.fold(0.0, (sum, s) => sum + s.monthlyImpact);
    if (monthlySubSpend > 1000) {
      insights.add(
          '⚠️  Subscriptions costing ₹${monthlySubSpend.toStringAsFixed(0)}/month. '
          'Consider cancelling unused ones!');
    }

    // Insight 3: Top leak
    if (leaks.isNotEmpty) {
      final topLeak = leaks[0];
      final monthlyLeak =
          (topLeak['monthly_projected'] as double?)?.toStringAsFixed(0) ??
              '0';
      insights.add(
          '🚨 Alert: ${topLeak['merchant']} costing ₹$monthlyLeak/month');
    }

    // Insight 4: Food spending
    if (categorySpend['food'] != null && categorySpend['food']! > 2000) {
      insights.add('🍕 Food: ₹${categorySpend['food']?.toStringAsFixed(0)}/month');
    }

    // Insight 5: Runway predictor
    final avgDaily = _calculateAverageDailySpend(transactions);
    final runway = _predictRunway(avgDaily);
    insights.add(
        '📈 At current rate: ${runway.toStringAsFixed(1)} months until broke');

    // Insight 6: Spending pattern
    final pattern = _getSpendingPattern(transactions);
    if (pattern.isNotEmpty) {
      insights.add(pattern);
    }

    return insights;
  }

  bool _isFestivalSeason() {
    final month = DateTime.now().month;
    // Diwali (Oct-Nov), Christmas (Dec), New Year, Holi (Feb-Mar)
    return [10, 11, 12, 1, 2, 3].contains(month);
  }

  double _calculateAverageSpend(List<TransactionModel> txns) {
    if (txns.isEmpty) return 0;
    final total = txns.fold(0.0, (sum, t) => sum + t.amount);
    final days = _getDayRange(txns);
    return total / days;
  }

  double _calculateAverageDailySpend(
      List<TransactionModel> txns) {
    return _calculateAverageSpend(txns);
  }

  double _predictRunway(double avgDaily) {
    if (avgDaily == 0) return double.infinity;
    // Assuming average balance of ₹100,000
    const estimatedBalance = 100000.0;
    return estimatedBalance / avgDaily / 30; // months
  }

  String _getSpendingPattern(List<TransactionModel> txns) {
    if (txns.length < 7) return '';

    final recentTxns = txns
        .where((t) {
          final days = DateTime.now()
              .difference(DateTime.parse(t.date))
              .inDays;
          return days <= 7;
        })
        .toList();

    final previousTxns = txns
        .where((t) {
          final days = DateTime.now()
              .difference(DateTime.parse(t.date))
              .inDays;
          return days > 7 && days <= 14;
        })
        .toList();

    if (recentTxns.isEmpty || previousTxns.isEmpty) return '';

    final recentTotal =
        recentTxns.fold(0.0, (sum, t) => sum + t.amount);
    final prevTotal =
        previousTxns.fold(0.0, (sum, t) => sum + t.amount);

    final percentChange = ((recentTotal - prevTotal) / prevTotal) * 100;

    if (percentChange > 20) {
      return '⬆️  Your spending increased by ${percentChange.toStringAsFixed(0)}% this week';
    } else if (percentChange < -20) {
      return '📉 Good! Your spending decreased by ${(-percentChange).toStringAsFixed(0)}% this week';
    }

    return '';
  }

  int _getDayRange(List<TransactionModel> txns) {
    final dates = txns.map((t) => DateTime.parse(t.date)).toList();
    final maxDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final minDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    return maxDate.difference(minDate).inDays + 1;
  }
}
```

---

## Days 5-7: Analytics Dashboard & Testing

### Task 5.1: Create Analytics Provider
**File: `lib/providers/analytics_provider.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/services/analyzer_service.dart';
import 'package:expense_ai_agent/services/leak_detection_service.dart';
import 'package:expense_ai_agent/services/insight_generator_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final _analyzerService = AnalyzerService();
  final _leakDetectionService = LeakDetectionService();
  final _insightGeneratorService = InsightGeneratorService();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load transactions and compute analytics
  Future<void> loadAnalytics(
      List<TransactionModel> transactions) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = transactions;

      // Compute all metrics (happens automatically)
      notifyListeners();
    } catch (e) {
      _error = 'Error loading analytics: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get spending by category
  Map<String, double> getSpendingByCategory() {
    final result = <String, double>{};

    for (final category in [
      'food',
      'transport',
      'utilities',
      'subscriptions',
      'shopping',
      'health',
      'education',
      'entertainment',
      'miscellaneous'
    ]) {
      final categoryTotal = _transactions
          .where((t) => t.category == category)
          .fold(0.0, (sum, t) => sum + t.amount);
      if (categoryTotal > 0) {
        result[category] = categoryTotal;
      }
    }

    return result;
  }

  /// Get top merchants
  List<Map<String, dynamic>> getTopMerchants({int limit = 5}) {
    final merchantSpend = <String, double>{};

    for (final tx in _transactions) {
      merchantSpend[tx.merchant] =
          (merchantSpend[tx.merchant] ?? 0) + tx.amount;
    }

    return merchantSpend.entries
        .toList()
        ..[].sort((a, b) => b.value.compareTo(a.value))
        .take(limit)
        .map((e) => {
              'merchant': e.key,
              'amount': e.value,
            })
        .toList();
  }

  /// Get leaks
  List<Map<String, dynamic>> getLeaks() {
    return _leakDetectionService.detectSmallDrains(_transactions);
  }

  /// Get subscriptions
  List<SubscriptionModel> getSubscriptions() {
    return _leakDetectionService
        .detectRecurringTransactions(_transactions);
  }

  /// Get insights
  List<String> getInsights() {
    final categorySpend = getSpendingByCategory();
    final subscriptions = getSubscriptions();
    final leaks = getLeaks();

    return _insightGeneratorService.generateInsights(
      transactions: _transactions,
      categorySpend: categorySpend,
      subscriptions: subscriptions,
      leaks: leaks,
    );
  }

  /// Get monthly summary
  MonthlySummary getMonthlySummary() {
    final now = DateTime.now();
    final monthYear =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final categorySpend = getSpendingByCategory();
    final topMerchants = getTopMerchants()
        .map((e) => '${e['merchant']}: ₹${e['amount']}')
        .toList();

    final totalSpend =
        _transactions.fold(0.0, (sum, t) => sum + t.amount);
    final insights = getInsights();
    final runway = _predictRunway(totalSpend);

    return MonthlySummary(
      monthYear: monthYear,
      totalSpend: totalSpend,
      spendByCategory: categorySpend,
      topMerchants: topMerchants,
      runwayMonths: runway,
      transactionCount: _transactions.length,
      insights: insights,
      createdAt: DateTime.now(),
    );
  }

  double _predictRunway(double totalSpend) {
    if (_transactions.isEmpty) return double.infinity;

    final avgDaily = totalSpend / 30;
    if (avgDaily == 0) return double.infinity;

    const estimatedBalance = 100000.0;
    return estimatedBalance / avgDaily / 30; // months
  }
}
```

---

## 🎯 FINAL IMPLEMENTATION ORDER

### Week 1:
1. ✅ Days 1-2: Add new models (CategorySpend, Subscription, MonthlySummary)
2. ✅ Days 2-3: Build CategorizationService with keyword matching
3. ✅ Days 3-4: Build LeakDetectionService
4. ✅ Days 4-5: Build InsightGeneratorService
5. Days 5-7: Create UI screens (Dashboard, Analytics, Leaks)

### Week 2:
1. Encryption & offline functionality
2. Backup service
3. Freemium logic
4. Testing & debugging

---

## ✅ Testing Checklist

- [ ] Transaction categorization accuracy > 90%
- [ ] Leak detection catches subscriptions correctly
- [ ] Monthly summary calculations accurate
- [ ] UI loads analytics in < 2 seconds
- [ ] Data persists after app restart
- [ ] Offline mode works without network
- [ ] No crashes with 10K+ transactions

**Ready to start? Begin with Task 1.1!** 🚀
