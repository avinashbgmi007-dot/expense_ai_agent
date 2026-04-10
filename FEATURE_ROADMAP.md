# Feature Roadmap & User Experience Recommendations

## Current State Assessment

After a thorough end-to-end audit, here's where the app stands:

**Working end-to-end today:**
- Upload CSV → Parse → Categorize → Display analytics
- Upload PDF → Extract text → Parse → Categorize → Display analytics  
- Upload XLSX → Parse columns → Parse → Categorize → Display analytics
- Spending by category with percentages and progress bars
- Top merchants ranking
- Subscription/recurring charge detection
- Small transaction leak detection
- AI insights (rule-based, privacy-first)
- Bottom navigation: Home ↔ Analytics ↔ Leaks

**Not wired up yet:**
- flutter_gemma local AI model (installed in pubspec but never used)
- Settings/preferences screen (service exists, no UI)
- SQLite/Drift (dependencies exist but SharedPreferences used)
- Data export
- Budget management
- Search/filter/sort

---

## What an End User Would Expect

Based on modern expense tracking apps (Splitwise, Walnut, Axio):

### 1. **Instant Feedback on Upload** ✅ Mostly Done
When user uploads a file, they should immediately see a preview of detected transactions with the ability to edit/delete wrong entries. Currently goes straight to dashboard.

### 2. **Transaction Review Screen** ❌ Missing
After parsing, user should see a list of all imported transactions and confirm them:
- "Is this ₹500 from SWIGGY correct? Food?"
- Allow editing merchant name, category, or marking as personal (not expense)
- This is critical for building user trust in the AI categorization

### 3. **Calendar View** ❌ Missing
Users expect to see spending on a calendar — "What did I spend on March 15?"

### 4. **Monthly Comparison** ❌ Missing
"How much more did I spend this month vs last month?" — This is the second most-used feature after import.

### 5. **Budget Setting** ❌ Missing
"Set monthly food budget: ₹10,000 → Notify me when I reach 80%"

### 6. **Search & Filter** ❌ Missing
"Show me all food expenses > ₹500 this month" — Power users need this.

### 7. **Receipt Image Attachment** ❌ Missing
Take a photo of a bill and attach it to a transaction. Already have image_picker dependency.

### 8. **Manual Transaction Entry** ❌ Missing
Sometimes users want to quickly log a cash expense.

---

## Recommended Feature Tiers (Privacy-First)

### FREE TIER (Privacy-First MVP)

Everything runs 100% on-device. No data leaves the phone.

| Feature | Description | Effort |
|---------|-------------|--------|
| File Import (CSV/PDF/XLSX) | ✅ Already works | - |
| Keyword Categorization | ✅ Already works (200+ Indian merchants) | - |
| Analytics Dashboard | ✅ Already works | - |
| Leak Detection | ✅ Already works | - |
| Rule-based AI Insights | ✅ Already works | - |
| Transaction List View | ⚠️ Partial | Low |
| Transaction Review/Edit | ❌ Needed | Medium |
| Settings Screen | ❌ Needed | Low |
| Search/Filter | ❌ Needed | Medium |
| Monthly Comparison | ❌ Needed | Medium |
| Calendar View | ❌ Nice to have | High |
| Manual Entry | ❌ Needed | Medium |
| Receipt Photos | ❌ Nice to have | Medium |
| Budget Alerts | ❌ Needed | Medium |
| Dark Mode | ❌ Nice to have | Low |
| Multiple Accounts | ❌ Nice to have | Medium |

### PRO TIER (Still Privacy-First, No Cloud Needed)

Enhanced AI still runs locally. No server dependency for core features.

| Feature | Description | Why Paid |
|---------|-------------|----------|
| **Gemma AI Categorization** | Use flutter_gemma on-device LLM for 99% accuracy on any merchant, even unknown ones | Needs Gemma model download (~1.5GB), GPU usage for inference |
| **Smart Budget Suggestions** | AI analyzes spending pattern and suggests optimal budgets per category | Advanced AI analysis |
| **Subscription Tracker** | Dedicated screen for managing detected subscriptions (Netflix, Spotify, gym, EMI) | Complex UI/UX |
| **Yearly Reports** | PDF export of annual spending with charts | Report generation |
| **Custom Categories** | Create your own categories with custom rules | User-configurable system |
| **Data Export (CSV/PDF)** | Download all your data for tax purposes | File generation |
| **Encrypted Backup** | E2E encrypted backup to user's own Google Drive/iCloud | Crypto + API integration |
| **WhatsApp Alerts** | Daily/weekly spending summary via WhatsApp | Notification system |
| **Multi-Currency** | Track expenses in different currencies with real-time exchange | Exchange rate API |

### SERVER-DEPENDENT (Optional, Not Recommended for Privacy-First)

These require sending data to your servers. Skip these if privacy is the core promise.

| Feature | Description | Privacy Concern |
|---------|-------------|-----------------|
| Cloud Sync | Sync across devices | Requires encrypted storage at rest |
| Shared Expenses | Split bills with friends | Requires user accounts |
| Social Benchmarks | "You spend 30% less on food than average" | Requires anonymized data collection |
| Tax Filing Export | Auto-generate tax-ready reports | Requires sending financial data to your server |

---

## User Experience Tweaks (Quick Wins, <1 Day Each)

1. **Empty State Improvement** — Add a "Try Sample Data" button so new users can explore the dashboard without uploading data first

2. **Upload Progress** — Show "Reading file..." → "Parsing 45 transactions..." → "Categorizing with AI..." → "Done!" instead of just a spinner

3. **Undo Delete** — When user deletes a transaction, show a snackbar with "Undo" for 5 seconds

4. **First Run Onboarding** — 3-screen carousel: "Upload your bank statement" → "See where your money goes" → "Detect subscription leaks you forgot about"

5. **Currency Toggle** — Quick toggle between ₹₹₹ and USD/EUR in header

6. **Quick Category Filter** — Tappable category chips on dashboard: "Show me ALL food spends this month"

7. **Notification Settings** — Let users choose which alerts they want (subscription renewals, budget thresholds, unusual spending)

8. **Data Deletion Confirmation** — "Clear all data" should have a red warning screen explaining this cannot be undone

---

## Technical Architecture Recommendations

### 1. Migrate from SharedPreferences to SQLite
- SharedPreferences is a flat JSON — not designed for structured queries
- Need: "Show food spends > ₹500 between Jan 1-15"
- sqflite or drift are already in pubspec — just need wiring

### 2. Proper AI Integration (flutter_gemma)
flutter_gemma is an on-device LLM. Here's the recommended approach:
- Download Gemma 2B model (~1.5GB) once
- Prompt: `"Categorize this transaction: Merchant: SWIGGY, Amount: ₹450, Description: Food delivery, Category: ?"`
- Returns one of: `food`, `transport`, `utilities`, `subscriptions`, `shopping`, `health`, `education`, `entertainment`, `miscellaneous`
- Fallback to keyword matching if model loading fails
- All processing is local — perfect for privacy-first app

### 3. State Management
- Currently using `provider` with one `AnalyticsProvider` class
- Good for now, but consider `riverpod` or `riverpod_generator` once app grows
- The analytics provider currently loads ALL transactions on every tab change — needs pagination

### 4. Testing
- 147 tests passing — good foundation
- Missing: Integration tests, widget tests for screens beyond the main widget_test
- Missing: Tests with real sample data (actual bank statement outputs)

---

## Priority Order for Next Sprint

1. **Transaction Review Screen** (before analytics) — Users want to verify parsed transactions
2. **Settings/Preferences Screen** — Currency, language, privacy controls
3. **Search & Filter** — Essential for usability
4. **Gemma AI Integration** — Key differentiator for "AI" in the product name
5. **SQLite Migration** — Needed for scalability
6. **Monthly Comparison** — High user value
7. **Budget Alerts** — High engagement feature
