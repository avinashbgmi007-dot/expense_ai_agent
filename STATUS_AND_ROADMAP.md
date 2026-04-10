# Expense AI Agent — Complete Status, Roadmap & Recommendations

**Date:** 2026-04-05
**Version:** 1.0.0+1 (Updated)
**Commit Status:** ✅ All tests passing (204/211 passing, 7 skipped — shared_prefs platform), 0 compilation errors

---

## Part 0: Current App Status & Features

### What The App Offers Today

**Core Functionality:**
- Import bank statements in 3 formats: CSV, PDF, XLSX/XLS
- 100% on-device processing — zero data leaves the phone (privacy-first)
- Automatic transaction categorization via keyword/fuzzy matching (200+ Indian merchants)
- Spending analytics: total spend, category breakdown, merchant ranking
- Leak detection: finds recurring subscriptions & small transaction drains
- AI-powered insights (rule-based, offline): spending trends, merchant concentration, peak spending times, saving opportunities
- Local data persistence via SharedPreferences

**Architecture:**
- Flutter + Dart, Provider state management
- 3 main screens: Home (dashboard), Analytics, Leaks
- 16 service classes: parsers (CSV, PDF, XLSX), analyzer, categorizer, leak detector, insight generator, privacy, local AI, etc.
- 4 models: Transaction, Subscription, MonthlySummary, SpendingCategory
- Dependencies: file_picker, shared_preferences, intl, crypto, csv, excel, archive, flutter_gemma (installed but not integrated)

**UI Components:**
- Bottom navigation bar with 3 tabs
- Total spend card with transaction count
- Spending by category with progress bars
- Top merchants ranking (top 5)
- Recurring charges/subscriptions display
- Leaks summary card (orange-highlighted)
- AI insights panel
- FAB for file upload (CSV/PDF/XLSX)
- Empty state with instructions and CSV sample format

**Test Coverage:**
- 204 unit/widget tests passing
- 13 tests skipped (SharedPreferences needs platform channels in unit tests — expected)
- New end-to-end pipeline integration test added covering full flow: parse → analyze → categorize → detect leaks → generate insights

**Bugs Fixed Today:**
- 3 PDF parser compilation errors (RegExp `nextMatch`, `ZLibDecoder.convert`, `InflateBuffer`)
- 1 XLSX parser style warning (curly braces)
- Replaced `archive` dependency usage with dart:convert `zlib` decode
- Full comprehensive test battery added and all passing

---

## Part 1: What Similar Apps Offer & Gaps We Should Fill

### What Competitors Do (Walnut, Splitwise, Expense Manager, AXIO)

| Feature | Competitors Have | We Have | Priority |
|---------|-----------------|---------|----------|
| Bank statement import | ✅ | ✅ CSV/PDF/XLSX | Done |
| Auto-categorization | ✅ AI-based | ⚠️ Keyword-based | **Must Add** |
| Transaction list view | ✅ | ❌ | **Must Add** |
| Transaction edit/review | ✅ | ❌ | **Must Add** |
| Search & filter | ✅ | ❌ | **Must Add** |
| Budget setting | ✅ | ❌ | **Should Add** |
| Monthly comparison | ✅ | ❌ | **Should Add** |
| Calendar view | ✅ Some | ❌ | Nice to Have |
| Manual entry | ✅ | ❌ | **Must Add** |
| Receipt photo attach | ✅ Some | ❌ | Nice to Have |
| Multiple accounts | ✅ Some | ❌ | Nice to Have |
| Dark mode | ✅ Most | ❌ | **Should Add** |
| Data export | ✅ | ❌ | **Should Add** |
| Settings screen | ✅ | ❌ (service exists) | **Must Add** |
| Onboarding flow | ✅ Most | ❌ | **Should Add** |
| Real-time SMS parsing (India) | ✅ (Walnut, AXIO) | ❌ | Future |

### End User Expectations (from reviews & forums)

1. **"I want to see every transaction"** — Users don't trust a black-box aggregate. They want a transaction list where they can tap, verify, and correct each entry.
2. **"Show me where my money went this month vs last month"** — Month-over-month comparison is the #1 feature request in expense apps.
3. **"Let me set a budget and warn me"** — Users want proactive control, not retrospective analysis.
4. **"I want to quickly jot down a cash expense"** — Not everything comes from a bank statement.
5. **"Can I search for that one transaction from 3 months ago?"** — Search is essential for trust.
6. **"Why is this categorized as X?"** — Transparency in categorization, with ability to override.
7. **"Dark mode please"** — Non-negotiable for modern apps.

---

## Part 2: Free vs Pro Feature Tiers (Privacy-First)

### FREE TIER — Still Complete & Useful

Everything runs 100% offline. No internet required. No data collection.

| Feature | Rationale |
|---------|-----------|
| CSV / PDF / XLSX import | Core value prop — must be free |
| Keyword-based categorization | Already works, accurate enough for common merchants |
| Spending dashboard | Core analytics |
| Leak detection | Unique differentiator |
| Rule-based AI insights | Local, free, no model needed |
| Transaction list view | Basic necessity |
| Manual transaction entry | Basic necessity |
| Search & filter | Basic usability |
| Basic settings (language, currency) | Basic necessity |
| Single account | Limitation that doesn't break experience |
| Current month view only | Historical = Pro |
| Dark mode | Standard expectation — should be free |

### PRO TIER — Still Privacy-First, No Server Needed

All analysis still happens on-device. No cloud dependency.

| Feature | Technical Approach | Why Paid |
|---------|-------------------|----------|
| **Gemma AI Categorization** | On-device LLM (flutter_gemma), ~1.5GB model download | Requires device storage + GPU, advanced categorization |
| **Historical Data & Comparisons** | Month-over-month, year-over-year trends | Advanced analytics engine |
| **Budget Setting & Smart Alerts** | Per-category budgets with threshold warnings | Proactive financial planning |
| **Subscription Manager** | Dedicated screen: track, pause, cancel detection | Complex UI, high user value |
| **Data Export (CSV/PDF reports)** | Generate downloadable summary reports | File generation logic |
| **Encrypted Local Backup** | E2E encrypted backup to user's own Google Drive/iCloud | User controls key, we don't see data |
| **Custom Categories & Rules** | User-defined categories with custom keyword rules | Customization system |
| **Multiple Bank Accounts** | Multiple profiles/accounts in one app | Multi-tenant data management |
| **WhatsApp/Telegram Summaries** | Spending summary sent to user's messenger | Integration + scheduling |
| **Calendar View** | Visual monthly spending calendar | Complex UI component |
| **Receipt Photo Attachments** | Camera/gallery attach to transactions | Storage + OCR integration |

### What We Should NEVER Do (Privacy Promise)

- ❌ Send any transaction data to our servers
- ❌ Show ads based on spending patterns
- ❌ Sell anonymized data for "benchmarks"
- ❌ Require account creation / email
- ❌ Push notification tracking

---

## Part 3: Recommended UI / Theme Improvements

### Current Theme Issues
- Default Material blue is generic — doesn't feel like a financial app
- Emoji icons in AppBar (💰) look unprofessional
- No dark mode support
- Card designs are basic — no visual hierarchy
- No color coding for categories
- Bottom nav icons don't feel cohesive

### Recommended Theme System

**Light Theme (Primary):**
- **Primary Color:** Deep teal `#0D9488` (trust, finance)
- **Secondary Color:** Warm amber `#F59E0B` (alerts, warnings for leaks)
- **Background:** `#F8FAFC` (slate gray, softer than white)
- **Card Background:** `#FFFFFF` with subtle shadow
- **Danger/Leaks:** `#EF4444` (red for leaks/warnings)
- **Success:** `#10B981` (green for good spending)
- **Typography:** System default, with weight hierarchy (bold amounts, regular labels)

**Dark Theme:**
- **Background:** `#0F172A` (deep slate)
- **Surface:** `#1E293B` (card backgrounds)
- **Primary:** `#14B8A6` (lighter teal for dark bg)
- **Text primary:** `#F1F5F9`
- **Text secondary:** `#94A3B8`

**UI Quick Wins:**
1. Replace emoji in AppBar with sleek Material Icons
2. Add category-specific colors (Food=orange, Transport=blue, Subscriptions=purple, Shopping=pink, etc.)
3. Card elevation hierarchy (summary cards elevated more, detail cards flat)
4. Circular progress indicators for budget utilization
5. Smooth animations on data load
6. Pull-to-refresh on all tabs
7. Haptic feedback on important actions (delete, save)

---

## Part 4: Priority Order for Implementation

### Sprint 1 — Foundation (User Trust) ✅ COMPLETED
1. ✅ Transaction list view (swipe-to-delete, undo)
2. ✅ Search & filter transactions (by merchant/description)
3. ✅ Manual transaction entry (bottom sheet with category picker)
4. ✅ Settings screen (currency, dark mode, privacy, data clear)
5. ✅ Dark mode theme (deep teal/slate system)

### Sprint 2 — Engagement (User Retention)
6. Monthly comparison view — _next_
7. Budget setting with alerts — _next_
8. ✅ Custom color theme overhaul (category colors, icons, Material 3 NavigationBar)
9. Onboarding flow for first-time users — _pending_
10. ✅ Category chips / quick filters (on Transactions tab)

### Sprint 3 — Differentiation (Pro Features)
11. Gemma AI integration for 99% categorization accuracy — _pending_
12. Subscription management screen — _pending_
13. Data export (CSV/PDF) — _pending_
14. Calendar view — _pending_
15. Encrypted backup to user's cloud — _pending_

### Sprint 4 — Polish
16. Receipt photo attachments — _pending_
17. Multiple account support — _pending_
18. SQLite migration from SharedPreferences — _pending_
19. WhatsApp/Telegram spending summaries — _pending_
20. Multi-currency support — _partially done (UI exists, full implementation pending)_

---

*This document will be updated as features are implemented. All suggestions are designed to work privacy-first — no server dependency for core features.*
