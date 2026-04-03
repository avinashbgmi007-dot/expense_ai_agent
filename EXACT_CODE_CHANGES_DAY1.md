# 🔧 EXACT CODE CHANGES - COPY & PASTE READY

> **IMPORTANT:** Follow STEP_BY_STEP_ALIGNMENT_GUIDE.md first, then use this file for exact code snippets.

---

## 📌 FILE 1: Update `lib/models/transaction.dart`

### CHANGE 1: Add 4 New Final Fields

**FIND THIS:**
```dart
  final String? unnoticedNote;

  TransactionModel({
```

**REPLACE WITH:**
```dart
  final String? unnoticedNote;
  final String uploadId;        // Which file upload?
  final DateTime createdAt;     // When recorded?
  final bool isIgnored;         // User can ignore transactions
  final String? userNote;       // User's manual notes

  TransactionModel({
```

---

### CHANGE 2: Update Constructor

**FIND THIS:**
```dart
  TransactionModel({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.confidence,
    required this.paymentMethod,
    required this.category,
    required this.isRecurring,
    this.unnoticedNote,
  });
```

**REPLACE WITH:**
```dart
  TransactionModel({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.confidence,
    required this.paymentMethod,
    required this.category,
    required this.isRecurring,
    this.unnoticedNote,
    required this.uploadId,
    required this.createdAt,
    required this.isIgnored,
    this.userNote,
  });
```

---

### CHANGE 3: Update toMap() Method

**FIND THIS:**
```dart
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'date': date,
      'confidence': confidence,
      'paymentMethod': paymentMethod,
      'category': category,
      'isRecurring': isRecurring ? 1 : 0,
      'unnoticedNote': unnoticedNote,
    };
  }
```

**REPLACE WITH:**
```dart
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'date': date,
      'confidence': confidence,
      'paymentMethod': paymentMethod,
      'category': category,
      'isRecurring': isRecurring ? 1 : 0,
      'unnoticedNote': unnoticedNote,
      'uploadId': uploadId,
      'createdAt': createdAt.toIso8601String(),
      'isIgnored': isIgnored ? 1 : 0,
      'userNote': userNote,
    };
  }
```

---

### CHANGE 4: Update fromMap() Factory

**FIND THIS:**
```dart
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      merchant: map['merchant'] as String,
      amount: map['amount'] as double,
      date: map['date'] as String,
      confidence: map['confidence'] as double,
      paymentMethod: map['paymentMethod'] as String,
      category: map['category'] as String,
      isRecurring: (map['isRecurring'] as int?) == 1,
      unnoticedNote: map['unnoticedNote'] as String?,
    );
  }
}
```

**REPLACE WITH:**
```dart
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      merchant: map['merchant'] as String,
      amount: map['amount'] as double,
      date: map['date'] as String,
      confidence: map['confidence'] as double,
      paymentMethod: map['paymentMethod'] as String,
      category: map['category'] as String,
      isRecurring: (map['isRecurring'] as int?) == 1,
      unnoticedNote: map['unnoticedNote'] as String?,
      uploadId: map['uploadId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isIgnored: (map['isIgnored'] as int?) == 1,
      userNote: map['userNote'] as String?,
    );
  }
}
```

---

## 📌 FILE 2: Create `lib/models/subscription.dart`

**CREATE NEW FILE** with this ENTIRE content:

```dart
enum SubscriptionFrequency {
  daily,
  weekly,
  biWeekly,
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
  final DateTime lastObservedDate;
  final int totalOccurrences;
  final double confidence; // 0.0 to 1.0
  final bool isConfirmed; // User validated
  final DateTime? cancelledDate;

  SubscriptionModel({
    this.id,
    required this.merchant,
    required this.amount,
    required this.frequency,
    required this.category,
    required this.firstObservedDate,
    required this.lastObservedDate,
    required this.totalOccurrences,
    required this.confidence,
    required this.isConfirmed,
    this.cancelledDate,
  });

  // Calculate monthly impact (for display in dashboard)
  // This converts any frequency to monthly amount
  double get monthlyImpact {
    switch (frequency) {
      case SubscriptionFrequency.daily:
        return amount * 30; // ₹50/day = ₹1500/month
      case SubscriptionFrequency.weekly:
        return amount * 4.3; // ₹100/week = ₹430/month
      case SubscriptionFrequency.biWeekly:
        return amount * 2.15; // ₹200/2weeks = ₹430/month
      case SubscriptionFrequency.monthly:
        return amount; // Already monthly
      case SubscriptionFrequency.quarterly:
        return amount / 3; // ₹900/3months = ₹300/month
      case SubscriptionFrequency.annual:
        return amount / 12; // ₹7200/year = ₹600/month
    }
  }

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'frequency': frequency.toString(),
      'category': category,
      'firstObservedDate': firstObservedDate.toIso8601String(),
      'lastObservedDate': lastObservedDate.toIso8601String(),
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
      amount: map['amount'] as double,
      frequency: _parseFrequency(map['frequency'] as String),
      category: map['category'] as String,
      firstObservedDate: DateTime.parse(map['firstObservedDate'] as String),
      lastObservedDate: DateTime.parse(map['lastObservedDate'] as String),
      totalOccurrences: map['totalOccurrences'] as int,
      confidence: map['confidence'] as double,
      isConfirmed: (map['isConfirmed'] as int?) == 1,
      cancelledDate: map['cancelledDate'] != null
          ? DateTime.parse(map['cancelledDate'] as String)
          : null,
    );
  }

  static SubscriptionFrequency _parseFrequency(String freq) {
    return SubscriptionFrequency.values.firstWhere(
      (e) => e.toString().split('.').last == freq.split('.').last,
      orElse: () => SubscriptionFrequency.monthly,
    );
  }
}
```

---

## 📌 FILE 3: Create `lib/models/monthly_summary.dart`

**CREATE NEW FILE** with this ENTIRE content:

```dart
class MonthlySummary {
  final int? id;
  final String monthYear; // Format: "2026-03"
  final double totalSpend;
  final Map<String, double> spendByCategory; // {"food": 8000, "transport": 2500}
  final List<String> topMerchants; // Top 5 merchants
  final double runwayMonths;
  final int transactionCount;
  final List<String> insights; // 7-10 insights

  MonthlySummary({
    this.id,
    required this.monthYear,
    required this.totalSpend,
    required this.spendByCategory,
    required this.topMerchants,
    required this.runwayMonths,
    required this.transactionCount,
    required this.insights,
  });

  // Getter: Calculate average daily spend
  double get averageDailySpend {
    return totalSpend / 30; // Approx 30 days per month
  }

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monthYear': monthYear,
      'totalSpend': totalSpend,
      'spendByCategory': spendByCategory, // Will be JSON
      'topMerchants': topMerchants, // Will be JSON array
      'runwayMonths': runwayMonths,
      'transactionCount': transactionCount,
      'insights': insights, // Will be JSON array
    };
  }

  factory MonthlySummary.fromMap(Map<String, dynamic> map) {
    return MonthlySummary(
      id: map['id'] as int?,
      monthYear: map['monthYear'] as String,
      totalSpend: map['totalSpend'] as double,
      spendByCategory: Map<String, double>.from(
        map['spendByCategory'] as Map,
      ),
      topMerchants: List<String>.from(map['topMerchants'] as List),
      runwayMonths: map['runwayMonths'] as double,
      transactionCount: map['transactionCount'] as int,
      insights: List<String>.from(map['insights'] as List),
    );
  }
}
```

---

## 📌 FILE 4: Create `lib/models/spending_category.dart`

**CREATE NEW FILE** with this ENTIRE content:

```dart
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

    final total = catTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    // Get top merchants
    final merchantMap = <String, double>{};
    for (var t in catTransactions) {
      merchantMap[t.merchant] = (merchantMap[t.merchant] ?? 0) + t.amount;
    }
    final topMerchants = merchantMap.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        .take(5)
        .map((e) => e.key)
        .toList();

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
      totalAmount: map['totalAmount'] as double,
      transactionCount: map['transactionCount'] as int,
      percentageOfTotal: map['percentageOfTotal'] as double,
      topMerchants: List<String>.from(map['topMerchants'] as List),
    );
  }
}
```

---

## 📌 FILE 5: Update `lib/services/database_service.dart`

### CHANGE 1: Add Import at Top

**FIND THIS:**
```dart
import 'package:expense_ai_agent/models/transaction.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
```

**ADD AFTER:**
```dart
import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/models/subscription.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
```

---

### CHANGE 2: Update onCreate Method

**FIND THIS:**
```dart
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'transactions.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant TEXT,
            amount REAL,
            date TEXT,
            confidence REAL,
            paymentMethod TEXT,
            category TEXT,
            isRecurring INTEGER,
            unnoticedNote TEXT
          )
        ''');
      },
    );
  }
```

**REPLACE WITH:**
```dart
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'transactions.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant TEXT,
            amount REAL,
            date TEXT,
            confidence REAL,
            paymentMethod TEXT,
            category TEXT,
            isRecurring INTEGER,
            unnoticedNote TEXT,
            uploadId TEXT,
            createdAt TEXT,
            isIgnored INTEGER,
            userNote TEXT
          )
        ''');
        await _createSubscriptionsTable(db);
        await _createMonthlySummaryTable(db);
      },
    );
  }
```

---

### CHANGE 3: Add New Methods (After deleteTransaction)

**FIND THIS:**
```dart
  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
```

**REPLACE WITH:**
```dart
  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ============ SUBSCRIPTIONS TABLE ============
  Future<void> _createSubscriptionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant TEXT,
        amount REAL,
        frequency TEXT,
        category TEXT,
        firstObservedDate TEXT,
        lastObservedDate TEXT,
        totalOccurrences INTEGER,
        confidence REAL,
        isConfirmed INTEGER,
        cancelledDate TEXT
      )
    ''');
  }

  Future<void> insertSubscription(SubscriptionModel sub) async {
    final db = await database;
    await db.insert(
      'subscriptions',
      sub.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SubscriptionModel>> getAllSubscriptions() async {
    final db = await database;
    final result = await db.query('subscriptions');
    return result.map((e) => SubscriptionModel.fromMap(e)).toList();
  }

  // ============ MONTHLY SUMMARY TABLE ============
  Future<void> _createMonthlySummaryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monthly_summary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monthYear TEXT UNIQUE,
        totalSpend REAL,
        spendByCategory TEXT,
        topMerchants TEXT,
        runwayMonths REAL,
        transactionCount INTEGER,
        insights TEXT
      )
    ''');
  }
}
```

---

## ✅ SUMMARY OF CHANGES

| File | Change Type | Status |
|------|------------|--------|
| `transaction.dart` | 4 changes (add fields, update constructor, toMap, fromMap) | 📝 Edit existing |
| `subscription.dart` | NEW file creation | ➕ Create |
| `monthly_summary.dart` | NEW file creation | ➕ Create |
| `spending_category.dart` | NEW file creation | ➕ Create |
| `database_service.dart` | 3 changes (add import, update onCreate, add methods) | 📝 Edit existing |

**Total:** 5 files modified/created, ~500 lines of code

---

## 🎯 VERIFICATION CHECKLIST

After making all changes, run:

```bash
flutter clean
flutter pub get
flutter analyze
flutter run
```

Expected results:
- ✅ `flutter analyze` → 0 errors
- ✅ `flutter run` → App compiles and displays HomeScreen
- ✅ No crashes on startup

If you see errors, check:
1. All field names match (case-sensitive)
2. All imports are correct
3. All toMap() and fromMap() methods complete
4. Database table creation methods called in onCreate

---

**Ready to code? Start with STEP_BY_STEP_ALIGNMENT_GUIDE.md!** 🚀
