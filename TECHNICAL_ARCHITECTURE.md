# 🏛️ TECHNICAL ARCHITECTURE - Deep Dive

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP (UI Layer)                       │
├─────────────────────────────────────────────────────────────────────┤
│  HomeScreen | AnalyticsScreen | LeaksScreen | SettingsScreen       │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────────────┐
│                    STATE MANAGEMENT (Provider)                      │
├──────────────────────────────────────────────────────────────────────┤
│  TransactionProvider | AnalyticsProvider | SubscriptionProvider    │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────────────┐
│                     SERVICE LAYER (Core Logic)                      │
├──────────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────┐  ┌────────────────────────┐                 │
│ │  DATA INGESTION     │  │  AI & PROCESSING       │                 │
│ ├─────────────────────┤  ├────────────────────────┤                 │
│ │ ParserService       │  │ CategorizationService  │                 │
│ │ OCRService          │  │ LeakDetectionService   │                 │
│ │ PDFParserService    │  │ InsightGeneratorSvc    │                 │
│ └─────────────────────┘  └────────────────────────┘                 │
│                                                                      │
│ ┌─────────────────────┐  ┌────────────────────────┐                 │
│ │  STORAGE & SYNC     │  │  SECURITY & BACKUP     │                 │
│ ├─────────────────────┤  ├────────────────────────┤                 │
│ │ DatabaseService     │  │ EncryptionService      │                 │
│ │ CacheService        │  │ BackupService          │                 │
│ │ AnalyzerService     │  │ NotificationService    │                 │
│ └─────────────────────┘  └────────────────────────┘                 │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────────────┐
│                     DATA LAYER (Local Storage)                      │
├──────────────────────────────────────────────────────────────────────┤
│  SQLite (Encrypted) | Shared Preferences | Cache Files              │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
   ┌────▼─────┐          ┌────▼──────┐
   │  Local   │          │  Device   │
   │   RTX    │          │  Storage  │
   │  4060    │          │ (Backup)  │
   └──────────┘          └───────────┘
```

---

## 1. DATA FLOW: From Upload to Insights

### Step 1: File Upload & Parsing
```
User uploads PDF/CSV
    ↓
File Detection (extension check)
    ↓
┌── If PDF:
│   ├─ Extract raw text (OCRService)
│   └─ Parse with Gemma
│
└── If CSV:
    ├─ Parse headers
    └─ Map columns to TransactionModel

Raw Transactions (unstructured)
    ↓
Validation (amount, date format)
    ↓
Storage in `transactions` table
    ↓
Update monthly_summary table
```

### Step 2: Categorization Pipeline
```
Raw Transaction {
  date: "2026-03-25",
  merchant: "SWIGGY",
  amount: 450,
  paymentMethod: "UPI"
}
    ↓
CategorizationService.categorizeTransaction()
    ├─ Level 1: Keyword match (SWIGGY → food)
    ├─ Level 2: Amount heuristics (UPI + 450 → food)
    └─ Level 3: Gemma AI (fallback)
    ↓
Categorized Transaction {
  category: "food",
  confidence: 0.95
}
```

### Step 3: Pattern Detection
```
All Categorized Transactions
    ↓
LeakDetectionService.detectRecurringTransactions()
    ├─ Group by merchant + amount
    ├─ Calculate gaps between dates
    ├─ Infer frequency (daily/weekly/monthly/etc)
    └─ Calculate confidence
    ↓
Subscriptions detected:
- Netflix: ₹649/month (high confidence)
- Gym: ₹1500/month (medium confidence)
    ↓
LeakDetectionService.detectSmallDrains()
    ├─ Find all ₹50-₹500 transactions
    ├─ Group by merchant
    ├─ Count occurrences
    └─ Project monthly impact
    ↓
Leaks detected:
- Swiggy: 15 orders = ₹6,750/month
- Starbucks: 20 visits = ₹2,000/month
```

### Step 4: Insight Generation
```
Processed Data:
- Transactions: 250
- Categories: {food: 8000, transport: 2000, ...}
- Subscriptions: [Netflix, Gym, Prime]
- Leaks: [Swiggy, Starbucks, Late-night food]
    ↓
InsightGeneratorService.generateInsights()
    ├─ Festival season check
    ├─ Subscription warning
    ├─ Top leak alert
    ├─ Category breakdown
    ├─ Runway prediction
    └─ Spending trend analysis
    ↓
Generated Insights (7-10 per month):
🎉 Festival season! Spending up 25%
⚠️  ₹2,500/month on subscriptions
🚨 Swiggy costing ₹6,750/month
📈 At current rate: 8.5 months until broke
```

### Step 5: Dashboard Rendering
```
Analytics Dashboard loads:
├─ Monthly Summary Card
│  ├─ Total: ₹25,000
│  ├─ Runway: 8.5 months
│  └─ Top merchant: Swiggy
├─ Category Breakdown (Pie Chart)
├─ Top 5 Merchants (List)
├─ Subscriptions List
├─ Leaks Alert (Red Banner)
└─ AI Insights (Text Cards)
```

---

## 2. DATABASE SCHEMA IN DETAIL

### Core Tables (5 Essential)

```sql
-- 1. TRANSACTIONS TABLE
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uploadId TEXT,
  date TEXT NOT NULL,
  merchant TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT,
  confidence REAL,
  paymentMethod TEXT,
  isRecurring INTEGER,
  unnoticedNote TEXT,
  isIgnored INTEGER DEFAULT 0,
  userNote TEXT,
  createdAt TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for fast queries
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_category ON transactions(category);
CREATE INDEX idx_transactions_merchant ON transactions(merchant);

-- 2. SUBSCRIPTIONS TABLE
CREATE TABLE subscriptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  merchant TEXT NOT NULL UNIQUE,
  amount REAL NOT NULL,
  frequency TEXT NOT NULL,
  category TEXT,
  firstObservedDate TEXT,
  lastObservedDate TEXT,
  totalOccurrences INTEGER,
  confidence REAL,
  isConfirmed INTEGER,
  cancelledDate TEXT,
  createdAt TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 3. MONTHLY_SUMMARY TABLE (Cached)
CREATE TABLE monthly_summary (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  monthYear TEXT UNIQUE NOT NULL,
  totalSpend REAL,
  spendByCategory TEXT, -- JSON: {food: 8000, ...}
  topMerchants TEXT,    -- JSON: ["Swiggy", "Uber", ...]
  runwayMonths REAL,
  transactionCount INTEGER,
  insights TEXT,        -- JSON: ["Insight 1", "Insight 2", ...]
  createdAt TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 4. UPLOADS TABLE (Metadata)
CREATE TABLE uploads (
  id TEXT PRIMARY KEY,
  filename TEXT NOT NULL,
  fileType TEXT,
  uploadTimestamp TEXT,
  transactionCount INTEGER,
  processingStatus TEXT, -- 'pending', 'processing', 'complete', 'error'
  errorMessage TEXT
);

-- 5. USER_SETTINGS TABLE
CREATE TABLE user_settings (
  id INTEGER PRIMARY KEY,
  isProUser INTEGER,
  alertsEnabled INTEGER,
  alertChannel TEXT,     -- 'whatsapp', 'telegram', 'email'
  alertPhoneNumber TEXT,
  lastBackupTime TEXT,
  dataEncryptionKey TEXT,
  createdAt TEXT DEFAULT CURRENT_TIMESTAMP
);
```

### Query Patterns (Optimized)

```dart
// Fast monthly summary
SELECT 
  DATE(date) as expense_date,
  category,
  SUM(amount) as daily_category_spend
FROM transactions
WHERE strftime('%Y-%m', date) = '2026-03'
GROUP BY DATE(date), category;

// Find recurring patterns
SELECT 
  merchant,
  amount,
  COUNT(*) as occurrences,
  DATE(date, '-' || days_between || ' days') as pattern_date
FROM transactions
WHERE amount = ? AND merchant = ?
GROUP BY pattern_date
HAVING COUNT(*) > 1;

// Leaks detection (quick)
SELECT 
  merchant,
  COUNT(*) as transaction_count,
  SUM(amount) as monthly_total
FROM transactions
WHERE amount BETWEEN 50 AND 500
  AND date >= date('now', '-30 days')
GROUP BY merchant
HAVING COUNT(*) >= 5
ORDER BY monthly_total DESC;
```

---

## 3. SERVICE LAYER ARCHITECTURE

### Service Responsibilities

| Service | Input | Processing | Output |
|---------|-------|-----------|--------|
| **ParserService** | PDF/CSV file | OCR + Text extraction | Raw transactions |
| **CategorizationService** | Raw transaction | Keyword + AI matching | Categorized transaction |
| **LeakDetectionService** | All transactions | Pattern mining | Subscriptions + Leaks |
| **InsightGeneratorService** | All processed data | Rule-based AI | Text insights (5-10) |
| **DatabaseService** | Model objects | SQLite operations | Persisted data |
| **AnalyzerService** | Transactions | Analytics math | Stats & metrics |

### Service Interdependencies

```
ParserService
    ↓
CategorizationService (takes output)
    ↓
LeakDetectionService (uses categorized)
    ↓
InsightGeneratorService (uses everything)
    ↓
AnalyticsProvider (displays results)
```

---

## 4. AI/ML PIPELINE (Local RTX 4060)

### Gemma Model Usage

```dart
// Initialize on app startup
Future<void> initAI() async {
  // Downloads ≈2GB quantized model (one-time)
  await FlutterGemma.initialize();
  
  // On RTX 4060: ~500ms response time per query
  // Uses 60% VRAM = ~4.8GB (leaving 3.2GB for app)
}

// Categorization prompt
final prompt = '''
Categorize this transaction:
Merchant: AMAZON
Amount: ₹5000
Date: 2026-03-25
Payment: Card

Categories: food, transport, utilities, subscriptions, shopping, health, education, entertainment, misc

Respond with: ONLY the category name
''';
// Expected: "shopping"
// Latency: ~500ms

// Insight generation prompt
final prompt = '''
Analyze this spending pattern and give 1 actionable insight:
- Total monthly spend: ₹25,000
- Monthly subscriptions: ₹2,500
- Food spending: ₹8,000
- Top leak: Swiggy (15 orders, ₹6,750)

Respond with: ONE sentence insight only
''';
// Expected: "Cancel unused subscriptions to save ₹2,500/month"
// Latency: ~300ms
```

### Fallback Strategy (No Network, No Gemma)

```dart
// If Gemma fails or not available:
// 1. Use keyword matching (90%+ accuracy)
// 2. Use amount heuristics
// 3. Default to 'miscellaneous'

// System keeps working 100% offline!
```

---

## 5. STATE MANAGEMENT (Provider)

### Provider Structure

```dart
// Main providers
MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => TransactionProvider(),
    ),
    ChangeNotifierProvider(
      create: (_) => AnalyticsProvider(),
    ),
    ChangeNotifierProvider(
      create: (_) => SubscriptionProvider(),
    ),
  ],
  child: MaterialApp(...),
);

// In widgets
Consumer<AnalyticsProvider>(
  builder: (context, analytics, child) {
    return DashboardCard(
      totalSpend: analytics.getTotalSpend(),
      topMerchants: analytics.getTopMerchants(),
      insights: analytics.getInsights(),
    );
  },
);
```

---

## 6. OFFLINE-FIRST ARCHITECTURE

### Principles

1. **All data stored locally** - SQLite on device
2. **All processing local** - Gemma runs on RTX 4060
3. **No external API calls** - Except optional webhooks (WhatsApp/Telegram)
4. **Graceful degradation** - Works without network

### Network Assumptions

```
Scenario 1: No Network (Always works)
├─ Upload file
├─ Parse & categorize
├─ Detect patterns
├─ Generate insights
└─ Save locally ✅

Scenario 2: Network Available (Optional enhancements)
├─ All of above
├─ Send WhatsApp alert (webhook)
├─ Sync backup to cloud (future)
└─ Fetch currency rates (future)

Scenario 3: Network Lost Mid-Operation
├─ All local operations continue
├─ Webhook fails gracefully (retry later)
└─ User never sees error ✅
```

---

## 7. SECURITY & ENCRYPTION

### Data Protection Strategy

```
SQLite Database
├─ Encrypted with AES-256
├─ Key derived from device ID + user password
└─ All tables encrypted transparently

Sensitive Fields
├─ Phone numbers (WhatsApp alerts)
├─ Encryption keys
└─ Backup files

Backup Files
├─ Format: encrypted ZIP
├─ Contains: all transactions + settings
├─ Stored: device secure storage
└─ Frequency: weekly

Zero External Exposure
├─ No data sent to cloud (unless user opts-in)
├─ No analytics tracking
├─ No telemetry
└─ No ads
```

### Encryption Implementation

```dart
class EncryptionService {
  // Generate unique device key on first run
  Future<String> getOrCreateDeviceKey() async {
    // Combine: DeviceID + Phone Model + Unique ID
    final deviceId = await DeviceInfoPlugin().androidInfo;
    final seed = '$deviceId' + Random.secure().nextInt(999999999).toString();
    return sha256.convert(utf8.encode(seed)).toString();
  }

  // Encrypt SQLite with SQLCipher
  void setupDatabaseEncryption(String key) {
    // Use sqflite_common_ffi + sqlcipher
    // Transparent encryption at DB level
  }
}
```

---

## 8. PERFORMANCE OPTIMIZATION

### Memory Management

```
RTX 4060 (8GB VRAM):
├─ Gemma Model: 2GB (quantized)
├─ Flutter App: 1.5GB
├─ SQLite Cache: 1GB
├─ Free headroom: 3.5GB ✅

Dataset Handling:
├─ 1K transactions: ~5MB SQLite
├─ 10K transactions: ~50MB + 2s load time
├─ 100K transactions: ~500MB + 20s load time
```

### Query Optimization

```dart
// ❌ SLOW: Load everything
final allTxns = await db.query('transactions');

// ✅ FAST: Use WHERE clause
final monthTxns = await db.query(
  'transactions',
  where: "strftime('%Y-%m', date) = ?",
  whereArgs: ['2026-03'],
);

// ✅ FAST: Use LIMIT
final recentTxns = await db.query(
  'transactions',
  orderBy: 'date DESC',
  limit: 1000,
);

// ✅ FAST: Pre-compute and cache
// Store monthly_summary, reuse for dashboard
```

---

## 9. TESTING STRATEGY

### Unit Tests
```dart
// Test categorization accuracy
test('CategorizationService categorizes Swiggy as food', () {
  final result = categorizer.categorize(
    merchant: 'SWIGGY',
    amount: 450,
    method: 'UPI',
  );
  expect(result, 'food');
});

// Test leak detection
test('LeakDetectionService detects Netflix subscription', () {
  final subs = detector.detectRecurringTransactions(txns);
  expect(subs.where((s) => s.merchant == 'Netflix'), isNotEmpty);
});
```

### Integration Tests
```dart
// Test full flow: upload → categorize → leak detect → insights
testWidgets('Full analysis flow', (tester) async {
  // 1. Upload file
  // 2. Verify transactions saved
  // 3. Verify categorization
  // 4. Verify subscriptions detected
  // 5. Verify insights generated
});
```

### Performance Tests
```dart
// Test dashboard load time
test('Analytics load < 2 seconds for 10K txns', () async {
  final stopwatch = Stopwatch()..start();
  await analyticsProvider.loadAnalytics(transactions);
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(2000));
});
```

---

## 10. DEPLOYMENT CHECKLIST

### Pre-Release
- [ ] Security audit (encryption, data handling)
- [ ] Performance testing (10K+ transactions)
- [ ] Beta test with 20-30 users
- [ ] Collect feedback
- [ ] Fix critical bugs

### Release
- [ ] Play Store deployment
- [ ] App Store deployment
- [ ] Version: 1.0.0
- [ ] Features: Basic categorization, offline mode, insights

### Post-Release (V1.1)
- [ ] WhatsApp alerts integration
- [ ] Advanced analytics
- [ ] Multi-account support
- [ ] Pro tier rollout

---

**Status: Architecture Finalized & Ready for Implementation** ✅
