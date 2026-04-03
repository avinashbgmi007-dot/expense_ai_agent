# 📍 STEP-BY-STEP ALIGNMENT GUIDE

**Status**: All foundation files ready. Now executing Day 1 of 7-day implementation.

---

## 🎯 CURRENT PROJECT STATE

### ✅ What's Working (Verified)
| File | Status | Usage |
|------|--------|-------|
| `transaction.dart` | ✅ 80% Complete | Core model - needs 4 new fields |
| `database_service.dart` | ✅ 70% Complete | CRUD works - needs sub/summary tables |
| `ocr_service.dart` | ✅ 100% Complete | Extract text from PDFs |
| `parser_service.dart` | ✅ 70% Complete | Parse extracted text to JSON |
| `analyzer_service.dart` | ✅ 75% Complete | Calculate totals, merchants, leaks |
| `chat_service.dart` | ✅ 50% Complete | Basic insights - needs expansion |
| `date_utils.dart` | ✅ 100% Complete | Format dates |
| `home_screen.dart` | ✅ 60% Complete | Upload UI - needs analytics wiring |
| `main.dart` | ✅ 100% Complete | App entry point |
| `pubspec.yaml` | ✅ 100% Complete | All dependencies present |

### ❌ What Needs Building (Empty Files)
| File | Priority | Purpose |
|------|----------|---------|
| `subscription.dart` | 🔴 CRITICAL | Model for recurring charges |
| `monthly_summary.dart` | 🔴 CRITICAL | Cached monthly analytics |
| `spending_category.dart` | 🔴 CRITICAL | Category aggregation |
| `categorization_service.dart` | 🔴 CRITICAL | Classify transactions |
| `leak_detection_service.dart` | 🔴 CRITICAL | Find subscriptions & leaks |
| `insight_generator_service.dart` | 🟠 HIGH | Generate 7+ insights |
| `analytics_provider.dart` | 🟠 HIGH | State management |
| `analytics_screen.dart` | 🟠 HIGH | Display dashboard |
| `leaks_screen.dart` | 🟡 MEDIUM | Show leak details |

---

## 🚀 STEP-BY-STEP EXECUTION ROADMAP

### PHASE 0: UNDERSTANDING THE FLOW (5 minutes)

**What happens when user uploads a PDF:**

```
1. User selects PDF from device
   ↓
2. OCRService extracts text from PDF (ocr_service.dart)
   ↓
3. ParserService parses text → JSON transactions (parser_service.dart)
   ↓
4. CategorizationService labels each → "food", "transport", etc (NEW - Day 2)
   ↓
5. LeakDetectionService finds patterns → subscriptions & leaks (NEW - Day 3)
   ↓
6. InsightGeneratorService creates insights → "₹6,750/month on Swiggy" (NEW - Day 4)
   ↓
7. AnalyticsProvider aggregates all data for UI (NEW - Day 5)
   ↓
8. AnalyticsScreen displays beautiful dashboard (NEW - Day 6)
   ↓
9. DatabaseService stores everything encrypted locally (database_service.dart)
```

**Key Rule:** Each step DEPENDS on previous step. Cannot skip.

---

## 📋 DAY 1: EXTEND TRANSACTION MODEL & ADD DATABASE TABLES

### STEP 1.1: Update TransactionModel (5 minutes)

**File:** `lib/models/transaction.dart`

**Current State:**
```dart
class TransactionModel {
  final int? id;
  final String merchant;
  final double amount;
  final String date;
  final double confidence;
  final String paymentMethod;
  final String category;
  final bool isRecurring;
  final String? unnoticedNote;
  // Missing 4 fields ❌
}
```

**What to Add:**
Need to add 4 new fields to track:
- **uploadId**: Which file upload does this belong to?
- **createdAt**: When was this transaction recorded?
- **isIgnored**: User can mark as "ignore this"
- **userNote**: User's manual notes

**Action Steps:**

**Step 1.1.1:** Add final fields after `unnoticedNote`
```dart
final String? unnoticedNote;
final String uploadId;        // NEW ← Add this line
final DateTime createdAt;     // NEW ← Add this line
final bool isIgnored;         // NEW ← Add this line
final String? userNote;       // NEW ← Add this line
```

**Step 1.1.2:** Update constructor parameters
```dart
TransactionModel({
  // ... existing params ...
  this.unnoticedNote,
  required this.uploadId,      // NEW - REQUIRED
  required this.createdAt,     // NEW - REQUIRED
  required this.isIgnored,     // NEW - REQUIRED (default false)
  this.userNote,               // NEW - OPTIONAL
});
```

**Step 1.1.3:** Update `toMap()` method
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
    'uploadId': uploadId,              // NEW ← Add
    'createdAt': createdAt.toIso8601String(),  // NEW ← Add
    'isIgnored': isIgnored ? 1 : 0,     // NEW ← Add (as 0/1)
    'userNote': userNote,               // NEW ← Add
  };
}
```

**Step 1.1.4:** Update `fromMap()` factory
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
    uploadId: map['uploadId'] as String,                    // NEW ← Add
    createdAt: DateTime.parse(map['createdAt'] as String), // NEW ← Add
    isIgnored: (map['isIgnored'] as int?) == 1,            // NEW ← Add
    userNote: map['userNote'] as String?,                  // NEW ← Add
  );
}
```

**Verification:** ✅ TransactionModel should now have 13 fields (9 old + 4 new)

---

### STEP 1.2: Create SubscriptionModel (10 minutes)

**File:** Create `lib/models/subscription.dart`

**Purpose:** Track monthly subscriptions like Netflix (₹649), Gym (₹1500), etc.

**Action Steps:**

**Step 1.2.1:** Create new file with enum
```dart
// lib/models/subscription.dart

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

  // Getter: Calculate monthly impact (for display)
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

**Verification:** ✅ File created, no compilation errors

---

### STEP 1.3: Create MonthlySummary Model (8 minutes)

**File:** Create `lib/models/monthly_summary.dart`

**Purpose:** Cache monthly analytics for fast dashboard loads.

**Action Steps:**

**Step 1.3.1:** Create file with model
```dart
// lib/models/monthly_summary.dart

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

**Verification:** ✅ File created, no compilation errors

---

### STEP 1.4: Create SpendingCategory Model (8 minutes)

**File:** Create `lib/models/spending_category.dart`

**Purpose:** Represent spending breakdown by category (food, transport, etc).

**Action Steps:**

**Step 1.4.1:** Create file
```dart
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

**Verification:** ✅ File created, no compilation errors

---

### STEP 1.5: Update DatabaseService - Add Tables (15 minutes)

**File:** `lib/services/database_service.dart`

**Action Steps:**

**Step 1.5.1:** Update onCreate method to execute multiple table creations
```dart
Future<Database> _initDB() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'transactions.db');

  return await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Create transactions table (EXISTING)
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
      
      // Create subscriptions table (NEW)
      await _createSubscriptionsTable(db);
      
      // Create monthly summary table (NEW)
      await _createMonthlySummaryTable(db);
    },
  );
}
```

**Step 1.5.2:** Add method to create subscriptions table
```dart
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
```

**Step 1.5.3:** Add method to create monthly summary table
```dart
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
```

**Step 1.5.4:** Add method to insert subscription
```dart
Future<void> insertSubscription(SubscriptionModel sub) async {
  final db = await database;
  await db.insert(
    'subscriptions',
    sub.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
```

**Step 1.5.5:** Add method to get all subscriptions
```dart
Future<List<SubscriptionModel>> getAllSubscriptions() async {
  final db = await database;
  final result = await db.query('subscriptions');
  return result.map((e) => SubscriptionModel.fromMap(e)).toList();
}
```

**Step 1.5.6:** Add import at top
```dart
import 'package:expense_ai_agent/models/subscription.dart';
```

**Verification:** 
- ✅ Code compiles without errors
- ✅ Can see all method signatures in database_service.dart

---

### STEP 1.6: Update main.dart to Use New Models (2 minutes)

**File:** `lib/main.dart`

**Action:** Add import for new models
```dart
import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/models/subscription.dart';
import 'package:expense_ai_agent/models/monthly_summary.dart';
import 'package:expense_ai_agent/models/spending_category.dart';
```

**Verification:** ✅ No compilation errors

---

### STEP 1.7: TEST Day 1 (5 minutes)

**Steps to verify everything works:**

**Step 1.7.1:** Open VS Code terminal
```bash
cd c:\Users\Avinash-Pro\Documents\work_space\expense_ai_agent
flutter pub get
```

**Step 1.7.2:** Run analyzer to check for errors
```bash
flutter analyze
```

**Expected Output:** Should show 0 errors (warnings are OK for now)

**Step 1.7.3:** Run app to verify compilation
```bash
flutter run
```

**Expected Result:** 
- App should compile without errors
- HomeScreen should display
- No crashes

**If errors occur:**
1. Check your Transaction constructor - does it have uploadId, createdAt, isIgnored?
2. Check SubscriptionModel - does enum parse correctly?
3. Check imports in database_service.dart

---

## 📋 DAY 2: IMPLEMENT CATEGORIZATION SERVICE

**Skip to next section when ready to implement Day 2**

---

## ✅ DAY 1 COMPLETION CHECKLIST

Before moving to Day 2, verify:

- [ ] TransactionModel has 13 fields total (9 old + 4 new)
- [ ] TransactionModel.toMap() includes all 4 new fields
- [ ] TransactionModel.fromMap() handles all 4 new fields
- [ ] SubscriptionModel created with enum (6 frequency values)
- [ ] SubscriptionModel monthlyImpact getter calculates correctly
- [ ] MonthlySummary created with 8 fields
- [ ] SpendingCategory created with enum (9 categories)
- [ ] DatabaseService has _createSubscriptionsTable()
- [ ] DatabaseService has _createMonthlySummaryTable()
- [ ] DatabaseService has insertSubscription()
- [ ] DatabaseService has getAllSubscriptions()
- [ ] All imports updated in main.dart
- [ ] `flutter analyze` returns 0 errors
- [ ] `flutter run` compiles and shows HomeScreen
- [ ] No crashes when opening app

---

## 🎯 WHAT YOU'VE ACCOMPLISHED

After Day 1, you will have:

✅ **Extended transaction tracking:**
- Track which upload each transaction came from
- Know when transaction was recorded
- Ability to mark transactions as ignored
- User can add manual notes

✅ **Subscription model ready:**
- Store Netflix, Gym, EMI subscriptions
- Auto-calculate monthly impact
- Track first/last occurrence & confidence

✅ **Monthly caching ready:**
- Store computed monthly analytics
- Fast dashboard loads (no re-computation)
- Cache insights for display

✅ **Category aggregation ready:**
- Calculate % spend per category
- Find top merchants per category
- Build category pie charts

✅ **Database schema ready:**
- Create 2 new tables (subscriptions, monthly_summary)
- Store all transactions with new fields
- Query subscriptions, monthly summaries

✅ **App compiles:**
- No errors
- Ready for Day 2 implementation

---

## 🚀 AFTER DAY 1 - WHAT'S NEXT

**Day 2 is CategorizationService.** It depends on:
- ✅ TransactionModel (Day 1)
- ✅ SpendingCategory (Day 1)
- ✅ DatabaseService (Day 1)

You will implement logic to classify "Swiggy" → "food", "Netflix" → "subscriptions", etc.

---

## 📞 REFERENCE

**If You Get Stuck:**

| Issue | Solution |
|-------|----------|
| "Undefined name 'SubscriptionModel'" | Add import: `import 'package:expense_ai_agent/models/subscription.dart';` |
| "toMap() method missing" | Check if you added it in subscription.dart lines |
| "Database table not created" | Verify _createSubscriptionsTable() called in onCreate |
| "Compilation aborted" | Run `flutter clean` then `flutter pub get` then `flutter run` |

---

**YOU'RE NOW READY TO CODE DAY 1!** ✨  
Print this guide, follow each step methodically, and you'll have a solid foundation by end of day.
