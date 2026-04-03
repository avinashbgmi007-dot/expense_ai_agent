# 🏗️ AI Expense Tracker - Complete Implementation Roadmap

## Overview
Building a privacy-first, offline AI-powered expense tracker for Indian users. **Zero cloud dependency**, local RTX 4060 processing.

---

## 📋 Phase 1: Core Architecture & Setup (Week 1)

### 1.1 Project Structure Refinement
```
lib/
├── config/
│   ├── app_config.dart          # App-wide settings
│   ├── db_config.dart           # Database configuration
│   └── ai_config.dart           # Model parameters
├── models/
│   ├── transaction.dart         # ✅ Done
│   ├── monthly_summary.dart     # NEW
│   ├── spending_category.dart   # NEW
│   └── subscription.dart        # NEW
├── services/
│   ├── ocr_service.dart         # ✅ Done
│   ├── parser_service.dart      # ✅ Core AI
│   ├── database_service.dart    # ✅ Local storage
│   ├── analyzer_service.dart    # ✅ Pattern detection
│   ├── categorization_service.dart    # NEW (AI-driven)
│   ├── leak_detection_service.dart    # NEW (recurring detection)
│   ├── insight_generator_service.dart # NEW (dashboard data)
│   └── backup_service.dart            # NEW (offline backup)
├── providers/
│   ├── transaction_provider.dart      # NEW (state mgmt)
│   ├── analytics_provider.dart        # NEW (insights)
│   └── subscription_provider.dart     # NEW (freemium logic)
├── screens/
│   ├── home_screen.dart              # ✅ Upload & dashboard
│   ├── analytics_screen.dart         # NEW
│   ├── leak_alerts_screen.dart       # NEW
│   └── settings_screen.dart          # NEW
├── widgets/
│   ├── transaction_list.dart         # NEW
│   ├── dashboard_card.dart           # NEW
│   ├── category_breakdown.dart       # NEW
│   └── runway_predictor.dart         # NEW
└── utils/
    ├── date_utils.dart               # ✅ Done
    ├── currency_formatter.dart       # NEW
    ├── category_mapper.dart          # NEW
    └── notification_handler.dart     # NEW (alerts)
```

### 1.2 Database Schema Design
**Tables Required:**
```sql
1. transactions
   - id (PK)
   - date
   - merchant
   - amount
   - category (food, transport, utilities, subscriptions, misc)
   - payment_method (UPI, card, cash, etc)
   - confidence_score (0.5-1.0)
   - is_recurring
   - upload_id (FK to uploads)
   - created_at
   - updated_at

2. uploads
   - id (PK)
   - filename
   - file_type (pdf, csv, razorpay, upwork)
   - upload_timestamp
   - transaction_count
   - processing_status

3. subscriptions
   - id (PK)
   - merchant_name
   - amount
   - frequency (monthly, weekly, daily)
   - category
   - start_date
   - end_date (nullable)
   - confidence

4. monthly_summary
   - id (PK)
   - month_year
   - total_spend
   - by_category (JSON)
   - top_merchants (JSON)
   - runway_months
   - created_at

5. leaks (small recurring spends)
   - id (PK)
   - merchant
   - daily_amount
   - frequency
   - monthly_total
   - alert_status
   - created_at

6. user_settings
   - id (PK)
   - is_pro_user
   - alert_enabled
   - backup_timestamp
   - data_encryption_key
```

### 1.3 Update pubspec.yaml
**Add Required Dependencies:**
```yaml
dependencies:
  # ✅ Already added
  flutter_gemma: ^0.12.6
  google_mlkit_text_recognition: ^0.15.1
  sqflite: ^2.4.2
  intl: ^0.19.0
  image_picker: ^1.2.1

  # NEW additions
  provider: ^6.0.0              # State management
  pdf: ^3.10.0                  # PDF parsing
  csv: ^5.1.0                   # CSV parsing
  encrypt: ^4.0.0               # SQLite encryption
  sqflite_common_ffi: ^2.0.0    # For desktop
  path_provider: ^2.0.0         # Secure storage
  flutter_secure_storage: ^9.0.0 # Encrypted storage
  share_plus: ^6.0.0            # Data export
  uuid: ^4.0.0                  # Unique IDs
  http: ^1.1.0                  # Local webhooks
```

---

## 🧠 Phase 2: AI & Categorization Engine (Week 2)

### 2.1 Categorization Service
**File: `lib/services/categorization_service.dart`**

```dart
class CategorizationService {
  // Indian merchant patterns & keywords
  static const Map<String, List<String>> categoryKeywords = {
    'food': ['swiggy', 'zomato', 'uber_eats', 'bhai', 'cafe', 'restaurant', 
             'dhaba', 'pizza', 'burger', 'pizza_hut', 'dominos', 'faasos'],
    'transport': ['uber', 'ola', 'metro', 'parking', 'fuel', 'petrol', 'diesel',
                  'toll', 'bus', 'railway', 'flight', 'train'],
    'utilities': ['electricity', 'water', 'gas', 'internet', 'broadband', 'phone',
                  'mobile_recharge', 'jio', 'airtel', 'vodafone'],
    'subscriptions': ['netflix', 'prime', 'hotstar', 'spotify', 'youtube', 'adobe',
                     'gym', 'membership', 'annual_fee', 'subscription'],
    'shopping': ['amazon', 'flipkart', 'myntra', 'mall', 'store', 'retail'],
    'health': ['pharmacy', 'doctor', 'hospital', 'clinic', 'medicine', 'health'],
    'education': ['school', 'college', 'university', 'coaching', 'course', 'fees'],
    'miscellaneous': ['others']
  };

  /// Categorize transaction using:
  /// 1. Merchant name matching (keywords)
  /// 2. Amount heuristics (e.g., ₹50-₹500 likely food)
  /// 3. Payment method patterns (UPI = small spend)
  Future<String> categorizeTransaction({
    required String merchant,
    required double amount,
    required String paymentMethod,
    required String date,
  }) async {
    // Step 1: Keyword matching (highest priority)
    for (var category in categoryKeywords.entries) {
      if (category.value.any((keyword) =>
          merchant.toLowerCase().contains(keyword))) {
        return category.key;
      }
    }

    // Step 2: Amount-based heuristics
    if (amount >= 50 && amount <= 500 && 
        paymentMethod.toLowerCase() == 'upi') {
      return 'food'; // Most likely
    }
    
    // Step 3: Use ML model if available
    try {
      return await _useGemmaForCategorization(merchant, amount);
    } catch (_) {
      return 'miscellaneous'; // Fallback
    }
  }

  /// Use local Gemma model for smart categorization
  Future<String> _useGemmaForCategorization(
    String merchant,
    double amount,
  ) async {
    try {
      final model = await FlutterGemma.getActiveModel(maxTokens: 50);
      final chat = await model.createChat();
      
      final prompt = '''\
Categorize this Indian merchant into ONE category:
Merchant: $merchant | Amount: ₹$amount

Categories: food, transport, utilities, subscriptions, shopping, health, education, miscellaneous

Respond with ONLY the category name.
''';

      // Parse response...
      return 'miscellaneous'; // Placeholder
    } catch (e) {
      return 'miscellaneous';
    }
  }

  /// Get spending insights for a category
  Map<String, dynamic> getCategoryInsights(
    List<TransactionModel> transactions,
    String category,
  ) {
    final categoryTxns = transactions
        .where((t) => t.category == category)
        .toList();

    return {
      'category': category,
      'total_spend': categoryTxns.fold(0.0, (sum, t) => sum + t.amount),
      'transaction_count': categoryTxns.length,
      'average_transaction': categoryTxns.isEmpty
          ? 0
          : categoryTxns.fold(0.0, (sum, t) => sum + t.amount) /
              categoryTxns.length,
      'merchants': categoryTxns.map((t) => t.merchant).toSet().length,
    };
  }
}
```

### 2.2 Leak Detection Service
**File: `lib/services/leak_detection_service.dart`**

Detects recurring subscriptions & small daily drains:

```dart
class LeakDetectionService {
  /// Detect recurring transactions (subscriptions, EMIs, etc)
  List<Map<String, dynamic>> detectSubscriptions(
    List<TransactionModel> transactions,
  ) {
    const int minOccurrences = 2; // At least 2 occurrences
    final subscriptions = <String, List<TransactionModel>>{};

    // Group by merchant + amount
    for (final tx in transactions) {
      final key = '${tx.merchant}_${tx.amount}';
      subscriptions.putIfAbsent(key, () => []).add(tx);
    }

    // Filter recurring patterns
    return subscriptions.entries
        .where((e) => e.value.length >= minOccurrences)
        .map((e) {
          final txns = e.value;
          final dates = txns.map((t) => DateTime.parse(t.date)).toList();
          dates.sort();

          // Calculate frequency
          final gaps = <int>[];
          for (int i = 1; i < dates.length; i++) {
            gaps.add(dates[i].difference(dates[i - 1]).inDays);
          }
          
          final avgGap = gaps.isEmpty ? 0 : gaps.reduce((a, b) => a + b) ~/ gaps.length;

          return {
            'merchant': txns[0].merchant,
            'amount': txns[0].amount,
            'frequency_days': avgGap,
            'occurrences': txns.length,
            'monthly_impact': (txns[0].amount * 30) / avgGap,
          };
        })
        .toList();
  }

  /// Detect small daily drains (₹99-₹499)
  List<Map<String, dynamic>> detectSmallDrains(
    List<TransactionModel> transactions,
  ) {
    const double minAmount = 99;
    const double maxAmount = 499;
    const int threshold = 5; // At least 5 small transactions

    final smallSpends = transactions
        .where((t) => t.amount >= minAmount && t.amount <= maxAmount)
        .toList();

    // Group by merchant
    final byMerchant = <String, List<TransactionModel>>{};
    for (final tx in smallSpends) {
      byMerchant.putIfAbsent(tx.merchant, () => []).add(tx);
    }

    return byMerchant.entries
        .where((e) => e.value.length >= threshold)
        .map((e) {
          final txns = e.value;
          final totalDrain = txns.fold(0.0, (sum, t) => sum + t.amount);
          
          return {
            'merchant': e.key,
            'transaction_count': txns.length,
            'total_drain': totalDrain,
            'average_amount': totalDrain / txns.length,
            'warning': 'Small frequent spends adding up!',
            'monthly_projected': totalDrain * 30 / _getDaysInDataset(txns),
          };
        })
        .toList();
  }

  int _getDaysInDataset(List<TransactionModel> txns) {
    final dates = txns.map((t) => DateTime.parse(t.date));
    final maxDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final minDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    return maxDate.difference(minDate).inDays + 1;
  }
}
```

### 2.3 Insight Generator Service
**File: `lib/services/insight_generator_service.dart`**

```dart
class InsightGeneratorService {
  /// Generate India-specific spending insights
  List<String> generateInsights({
    required List<TransactionModel> transactions,
    required Map<String, dynamic> categoryBreakdown,
    required List<Map<String, dynamic>> subscriptions,
    required List<Map<String, dynamic>> leaks,
  }) {
    final insights = <String>[];

    // Insight 1: Festival spending detection
    if (_isFestivalSeason()) {
      insights.add('🎉 Festival season detected! Your shopping spends ↑25% vs normal');
    }

    // Insight 2: Subscription warning
    final monthlySubscriptions = subscriptions.fold(0.0,
        (sum, s) => sum + ((s['monthly_impact'] as double?) ?? 0));
    
    if (monthlySubscriptions > 1000) {
      insights.add('⚠️  Subscriptions costing ₹$monthlySubscriptions/month - '
          'consider unsubscribing unused ones');
    }

    // Insight 3: Leaks
    if (leaks.isNotEmpty) {
      final topLeak = leaks.first;
      insights.add('🚨 Leak detected: ${topLeak['merchant']} - '
          '₹${topLeak['monthly_projected'].toStringAsFixed(0)}/month');
    }

    // Insight 4: Category insights
    if (categoryBreakdown['food'] != null) {
      final foodSpend = categoryBreakdown['food']['total_spend'];
      insights.add('🍕 Food spending: ₹$foodSpend/month');
    }

    // Insight 5: Runway predictor
    final avgDaily = _calculateAverageDailySpend(transactions);
    final runway = _predictRunway(transactions, avgDaily);
    insights.add('📊 At current rate: ${runway.toStringAsFixed(1)} months until broke');

    return insights;
  }

  /// Check if it's festival/holiday season in India
  bool _isFestivalSeason() {
    final month = DateTime.now().month;
    // Diwali (Oct-Nov), Christmas (Dec), New Year (Dec-Jan), Holi (Feb-Mar)
    return [10, 11, 12, 1, 2, 3].contains(month);
  }

  double _calculateAverageDailySpend(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return 0;
    final total = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final days = _getDaysInDataset(transactions);
    return total / days;
  }

  double _predictRunway(List<TransactionModel> transactions, double avgDaily) {
    if (avgDaily == 0) return double.infinity;
    // Assuming ₹100,000 as average account balance (adjustable)
    return 100000 / avgDaily / 30; // months
  }

  int _getDaysInDataset(List<TransactionModel> txns) {
    if (txns.isEmpty) return 1;
    final dates = txns.map((t) => DateTime.parse(t.date));
    final maxDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final minDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    return maxDate.difference(minDate).inDays + 1;
  }
}
```

---

## 📊 Phase 3: Dashboard & Analytics UI (Week 3)

### 3.1 Analytics Screen
**Displays:**
- Monthly spend breakdown (pie chart)
- Top 5 merchants
- Category distribution
- Runway predictor
- Week-over-week comparison
- India-specific insights

### 3.2 Leak Alerts Screen
**Displays:**
- Recurring subscriptions with toggle to manage
- Small daily drains with warning badges
- Monthly impact projections
- Action buttons (unsubscribe, block merchant)

### 3.3 Dashboard Widgets
Create reusable widgets:
- `SpendingBreakdownCard` (pie chart)
- `RunwayPredictorCard` (months remaining)
- `TopMerchantsCard` (rankings)
- `SubscriptionWidget` (recurring list)
- `LeakWarningBanner` (critical alerts)

---

## 🔒 Phase 4: Data Privacy & Offline (Week 4)

### 4.1 Encryption Service
```dart
class EncryptionService {
  /// Encrypt SQLite database with local key
  /// Use: sqlcipher, encrypted_shared_preferences
  
  Future<void> encryptDatabase() async {
    // Use sqlcipher for transparent encryption
  }

  /// Generate device-specific encryption key
  Future<String> generateDeviceKey() async {
    // Use device ID + unique identifier
  }
}
```

### 4.2 Backup Service
```dart
class BackupService {
  /// Weekly encrypted backup to device storage
  /// Format: encrypted JSON zip
  
  Future<void> createWeeklyBackup() async {
    // Export all transactions + settings
    // Encrypt with device key
    // Save to device secure storage
  }

  Future<void> restoreBackup(String backupFile) async {
    // Decrypt backup
    // Validate integrity
    // Restore to database
  }
}
```

### 4.3 Offline-First Architecture
- All AI processing happens locally
- No external API calls except optional WhatsApp webhooks
- Periodic sync checks (if internet available)
- Graceful degradation if APIs fail

---

## 💰 Phase 5: Freemium & Monetization (Week 5)

### 5.1 Subscription Tier Logic
```dart
enum SubscriptionTier { free, pro }

class SubscriptionService {
  bool canUploadFiles(SubscriptionTier tier) => tier == SubscriptionTier.pro;
  bool canExportData(SubscriptionTier tier) => tier == SubscriptionTier.pro;
  bool getUnlimitedHistory(SubscriptionTier tier) => tier == SubscriptionTier.pro;
  bool getAlertNotifications(SubscriptionTier tier) => tier == SubscriptionTier.pro;
  
  const pricePerMonth = 299; // ₹ 299/month
}
```

### 5.2 Free Tier Limits
- ✅ 3 uploads/month
- ✅ Last 3 months history
- ✅ Basic categorization
- ✅ No alerts
- ✅ No export

### 5.3 Pro Tier Features
- ✅ Unlimited uploads
- ✅ Full history
- ✅ Advanced categorization
- ✅ Weekly WhatsApp alerts
- ✅ Data export (CSV/PDF)
- ✅ Advanced analytics

---

## 🚀 Phase 6: Notifications & Integrations (Week 6)

### 6.1 Local Webhook Handler
```dart
class NotificationService {
  /// Send weekly leak alerts via webhook to WhatsApp/Telegram
  /// Payload: { merchant, amount, frequency, action_url }
  
  Future<void> sendWeeklyAlerts(List<Map<String, dynamic>> leaks) async {
    // Hit local webhook → external service (optional)
    // Format WhatsApp-friendly message
  }
}
```

### 6.2 WhatsApp Integration (Optional)
```
Example Message:
🚨 Weekly Expense Leak Alert
- Swiggy: ₹2,100/month (5 orders)
- Netflix: ₹649/month (subscription)
- Starbucks: ₹1,200/month (daily!)

💡 Tip: Cancel unused subscriptions to save ₹1,849/month
```

---

## 📱 Phase 7: UI/UX Polish & Testing (Week 7)

### 7.1 Navigation Structure
```
Bottom Navigation:
├── Home (Upload + Quick Stats)
├── Analytics (Detailed Dashboard)
├── Leaks (Recurring Spends + Alerts)
├── Settings (Encryption, Backup, Subscription)
└── Profile (Account, Credits)
```

### 7.2 Key Screens to Build
1. **Upload Screen** - Multi-file picker with progress
2. **Dashboard** - Overview of spending
3. **Detailed Analytics** - Time-series charts
4. **Leak Management** - Action items
5. **Settings** - Encryption, backup, subscription status
6. **Insights Panel** - AI-generated recommendations

### 7.3 Testing Checklist
- [ ] Offline functionality (disable network, verify works)
- [ ] PDF parsing (various bank formats)
- [ ] CSV parsing (edge cases)
- [ ] Encryption/decryption (backup/restore)
- [ ] AI categorization accuracy (>90%)
- [ ] Database performance (10K+ transactions)
- [ ] Memory usage (RTX 4060 constraints)

---

## 🔧 Technical Implementation Details

### Database Initialization
```dart
// in database_service.dart
Future<Database> _initDB() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'expense_tracker.db');

  return await openDatabase(
    path,
    version: 2, // Increment for schema changes
    onCreate: (db, version) async {
      // Create all tables
      await db.execute(_createTransactionsTable);
      await db.execute(_createUploadsTable);
      await db.execute(_createSubscriptionsTable);
      await db.execute(_createMonthlySummaryTable);
      await db.execute(_createLeaksTable);
      await db.execute(_createUserSettingsTable);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      // Handle schema migrations
    },
  );
}
```

### PDF Parsing Strategy
```dart
// in parser_service.dart
// 1. Extract text using MLKit OCR
// 2. Use regex to find transaction patterns:
//    Pattern: DATE | MERCHANT | AMOUNT
// 3. Validate extracted data
// 4. Pass to Gemma for cleanup
// 5. Categorize using CategorizationService
```

### CSV Parsing Strategy
```dart
// 1. Detect CSV format (headers)
// 2. Map columns (date, amount, merchant, etc)
// 3. Parse rows
// 4. Validate data types
// 5. Process same as PDF
```

---

## 📈 Success Metrics

### Performance Targets
- [ ] Upload processing: < 5s (10 transactions)
- [ ] Dashboard load: < 2s (10K transactions)
- [ ] Memory footprint: < 300MB
- [ ] Battery drain: < 5% per hour
- [ ] AI accuracy: > 90% category match

### Feature Completeness
- [ ] Multi-format ingestion: 100%
- [ ] Offline functionality: 100%
- [ ] Encryption: AES-256
- [ ] Leak detection: 95%+ accuracy
- [ ] Insights generation: 10+ unique insights

---

## 🎯 Launch Checklist

### Pre-Launch (Week 8)
- [ ] Security audit (encryption, data handling)
- [ ] Performance testing (large datasets)
- [ ] Beta test with 10-20 users
- [ ] Collect feedback & iterate
- [ ] Finalize monetization logic

### Launch (Week 9)
- [ ] Deploy to Play Store & App Store
- [ ] Create landing page
- [ ] Start marketing to Indian finance communities
- [ ] Monitor crash reports & user feedback
- [ ] Plan Pro tier marketing

---

## 💡 Future Enhancements

1. **Multi-Account Support** - Track multiple bank accounts
2. **Investment Tracking** - Mutual funds, stocks
3. **Budget Planning** - Set monthly budgets per category
4. **AI Expense Prediction** - Forecast next month's spend
5. **Income Tracking** - Monthly income + salary tracking
6. **Tax Planning** - GST aggregation for freelancers
7. **Family Sharing** - Multiple users on same device
8. **Export Reports** - Professional PDF reports

---

**Status: Ready for Implementation** ✅

Now let's start Phase 1 implementation!
