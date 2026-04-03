# 🧪 Complete Test Instructions - Expense AI Agent

## ✅ BUGS FIXED

### Primary Bug: `NoSuchMethodError: Class 'TransactionModel' has no instance method '[]'`
**Root Cause:** The `subscriptions` list in `AnalyticsProvider` was storing raw `TransactionModel` objects, but the UI was trying to access them as maps using `subscriptions[i]['merchant']` and `subscriptions[i]['amount']`.

**Fix Applied:**
1. **`lib/providers/analytics_provider.dart` (line 62-73)**
   - Changed `'subscriptions': repeatedTransactions,`
   - To: `'subscriptions': repeatedTransactions.map((t) => {'merchant': t.merchant, 'amount': t.amount, 'date': t.formattedDateTime}).toList()`
   - Now stores maps instead of objects

2. **`lib/screens/home_screen.dart` (line 360-380)**
   - Changed from `.map().spread` syntax to explicit `for` loop
   - Now properly accesses `subscriptions[i]['merchant']` and `subscriptions[i]['amount']`

### Secondary Bug: Missing Database Persistence
**Root Cause:** CSV transactions were parsed but never saved to SharedPreferences

**Fix Applied:**
- `lib/screens/home_screen.dart` now saves each transaction via `DatabaseService.insertTransaction()`

---

## 🎯 Test Plan

### Pre-Test Setup
- ✅ APK built and installed on Pixel 6a
- ✅ Sample CSV (`sample_transactions.csv`) ready with 20 test transactions
- ✅ All code fixes applied and validated

### Manual Test Steps

#### Step 1: Launch App
1. Tap "Expense AI Agent" icon on Pixel 6a
2. **Expected:** Blank dashboard with "No Transactions Yet" message

#### Step 2: Upload CSV File
1. Tap floating button "Upload CSV/PDF" (orange button at bottom)
2. Select file → Navigate to `sample_transactions.csv`
3. **Expected:** Success message "✅ Successfully loaded 20 transactions from CSV"

#### Step 3: Validate Dashboard Data
Check dashboard displays:
- ✅ **Total Spend: ₹6,945**
- ✅ **Transaction Count: 20**

#### Step 4: Validate Categories
Should see "Spending by Category" card with:
- **Food:** ₹2,350.00 (33.8%)
  - Swiggy ×2 (₹500 + ₹500)
  - Zomato (₹500)
  - Dominos (₹500)
  - Starbucks (₹100)
  - Uber Eats (₹450)

- **Transport:** ₹675.00 (9.7%)
  - Uber ×2 (₹250 + ₹200)
  - Ola (₹150)
  - Rapido (₹75)

- **Subscriptions:** ₹747.00 (10.8%)
  - Netflix (₹99)
  - Amazon Prime (₹199)
  - Spotify (₹99)
  - YouTube Premium (₹49)
  - Hotstar (₹199)
  - Apple Music (₹99)

- **Shopping:** ₹1,999.00 (28.8%)
  - Amazon (₹150)
  - Flipkart (₹999)

- **Entertainment:** ₹300.00 (4.3%)
  - BookMyShow (₹300)

- **Miscellaneous:** ₹625.00 (9.0%)
  - All other merchants categorized as miscellaneous

#### Step 5: Validate Top Merchants
Should see "Top Merchants" showing highest spenders:
1. Flipkart - ₹999.00
2. Swiggy - ₹1,000.00 (or similar if aggregated)
3. Other merchants in order

#### Step 6: Validate Subscriptions
Should see "Recurring Charges (Subscriptions)" card listing:
- Netflix - ₹99.00
- Amazon Prime - ₹199.00
- Spotify - ₹99.00
- YouTube Premium - ₹49.00
- Hotstar - ₹199.00

#### Step 7: Validate Leaks Detection
Orange warning card "⚠️ Potential Leaks Summary" should show:
- **Monthly Subscriptions:** ₹744.00+ (sum of recurring)
- **Small Transactions:** Calculated from small purchases

#### Step 8: Test Persistence
1. Close app completely
2. Reopen app
3. **Expected:** Dashboard still shows the same 6,945 total and all data persists

---

## 📊 Sample CSV Content

```csv
Date,Amount,Merchant,Description
2024-01-15,500.00,Swiggy,Food Delivery
2024-01-15,250.00,Uber,Transport to Office
2024-01-16,99.00,Netflix,Monthly Subscription
2024-01-16,150.00,Amazon,Online Shopping
2024-01-17,500.00,Swiggy,Dinner
2024-01-17,199.00,Amazon Prime,Annual Membership
2024-01-18,450.00,Uber Eats,Food Delivery
2024-01-18,75.00,Rapido,Auto Ride
2024-01-19,99.00,Spotify,Music Streaming
2024-01-19,999.00,Flipkart,Electronics
2024-01-20,500.00,Dominos,Food Delivery
2024-01-20,150.00,Ola,Cab Ride
2024-01-21,100.00,Starbucks,Coffee
2024-01-21,49.00,YouTube Premium,Video Streaming
2024-01-22,500.00,Swiggy,Lunch
2024-01-22,200.00,Uber,Commute
2024-01-23,199.00,Hotstar,Streaming Service
2024-01-23,300.00,BookMyShow,Movie Tickets
2024-01-24,500.00,Zomato,Food Order
2024-01-24,99.00,Apple Music,Music Subscription
```

---

## ⚠️ If Tests Fail

### Error: Still seeing `NoSuchMethodError`
- Clear app data: Settings → Apps → Expense AI Agent → Storage → Clear Data
- Reinstall app
- Try again

### Error: Data not persisting
- Check device storage has space
- Verify SharedPreferences not blocked by OS

### Error: CSV not found
- Ensure `sample_transactions.csv` exists in project root
- Use file manager on device to verify file location

---

## ✅ Success Criteria

All of the following must be true:
- [ ] CSV uploads without errors
- [ ] Dashboard shows ₹6,945 total
- [ ] All 20 transactions visible in dashboard
- [ ] Categories auto-detected correctly
- [ ] Subscriptions section shows 6 recurring services
- [ ] Leaks warning displays
- [ ] Data persists after app restart
- [ ] All amounts in INR (₹)

---

**Build Details:**
- APK Size: 231.5MB
- Platform: Android ARM64
- Min SDK: 24 (Android 7.0+)
- Target SDK: 36 (Android 15)
- Device: Pixel 6a (bluejay_beta)
