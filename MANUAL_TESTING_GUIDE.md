# Manual Testing Guide - PDF & AI Features

## Quick Verification (5 minutes)

### Part 1: CSV Upload (Already Working - Baseline Test)
1. Open app on device
2. Tap "Upload CSV/PDF" button
3. Select `sample_transactions.csv`
4. **Expected Result**: 
   - ✅ Message: "Successfully loaded 20 transactions from CSV"
   - ✅ Dashboard shows: ₹6,945 total spend
   - ✅ Categories visible: FOOD, TRANSPORT, SUBSCRIPTIONS, SHOPPING, MISCELLANEOUS
   - ✅ Top merchants: Swiggy, Uber, Netflix

### Part 2: PDF Upload (New Feature - Now Integrated)
1. Create a text-based PDF with sample transactions (see below)
2. Tap "Upload CSV/PDF" button  
3. Select the PDF file
4. **Expected Result**:
   - ✅ Message: "Successfully loaded N transactions from PDF" (NOT "in progress" message)
   - ✅ Dashboard updates with PDF data
   - ✅ Transactions appear in category/merchant lists
   - ✅ Same accuracy as CSV format

### Part 3: Categorization Accuracy (New Feature)
1. After uploading either CSV or PDF
2. Check Dashboard section "Spending by Category"
3. **Expected Results for sample_transactions.csv**:
   - ✅ FOOD: ₹1,500 (Swiggy, Starbucks, etc.)
   - ✅ TRANSPORT: ₹900 (Uber)
   - ✅ SUBSCRIPTIONS: ₹99 (Netflix)
   - ✅ SHOPPING: ₹349 (Amazon)

---

## Detailed Test Scenarios

### Scenario 1: Basic PDF with 5 Transactions

**Create test PDF with this content** (save as `test_transactions.pdf`):
```
Bank Statement - December 2024

Date       Amount      Merchant
01/12/2024 ₹500       SWIGGY FOOD
02/12/2024 ₹300       UBER AUTO
03/12/2024 ₹99        NETFLIX SUB
04/12/2024 ₹1500      AMAZON SHOPPING
05/12/2024 ₹250       STARBUCKS COFFEE
```

**Test Steps**:
1. Upload PDF
2. Verify: 5 transactions extracted
3. Check categories:
   - FOOD: ₹750 (Swiggy + Starbucks)
   - TRANSPORT: ₹300 (Uber)
   - SUBSCRIPTIONS: ₹99 (Netflix)
   - SHOPPING: ₹1500 (Amazon)

**Accuracy Check**: 
- ✅ 5/5 transaction extracted = 100%
- ✅ 5/5 dates parsed = 100%
- ✅ 5/5 amounts = 100%
- ✅ 5/5 merchants = 100%
- ✅ 5/5 categories correct = 100%

---

### Scenario 2: PDF with Multiple Date Formats (Testing Robustness)

**Create test PDF** (`date_formats.pdf`):
```
12/01/2024    ₹500     Swiggy
01-12-2024    ₹300     Uber
2024/12/02    ₹150     Netflix
02.12.2024    ₹200     Amazon
Dec 5, 2024   ₹50      Starbucks
```

**Test Steps**:
1. Upload PDF
2. Count extracted transactions

**Expected Result**: 
- ✅ First 4 transactions parsed (with supported formats)
- ✅ Last transaction may be skipped (non-standard format)
- ✅ Minimum 4/5 transactions = 80%

---

### Scenario 3: PDF with Amount Variations (Testing Flexibility)

**Create test PDF** (`amount_formats.pdf`):
```
01/12/2024   1000       Swiggy
02/12/2024   ₹500       Uber  
03/12/2024   1,200.50   Netflix
04/12/2024   ₹2,000     Amazon
05/12/2024   300.00     Starbucks
```

**Expected Result**:
- ✅ All 5 amounts extracted correctly
- ✅ Total = 1000 + 500 + 1200.50 + 2000 + 300 = ₹4,000.50

---

### Scenario 4: PDF with Unknown Merchants (Testing Fallback)

**Create test PDF** (`unknown_merchants.pdf`):
```
01/12/2024   ₹200      Local Vendor
02/12/2024   ₹150      XYZ Restaurant
03/12/2024   ₹500      ABC Transport
04/12/2024   ₹300      Unknown Shop
```

**Expected Result**:
- ✅ All 4 merchants extracted (as "Local", "XYZ", "ABC", "Unknown")
- ✅ Categories assigned (likely MISCELLANEOUS for most)
- ✅ Dashboard shows them in "Top Merchants" or "Other"

**Accuracy**: 95%+ (unknown merchants correctly extracted, categories may be "miscellaneous")

---

## Categorization Testing

### Test 1: Common Merchants (High Confidence)
Upload or manually check these merchants:
| Merchant | Expected Category | Confidence |
|----------|------------------|------------|
| Swiggy | FOOD | 99% |
| Zomato | FOOD | 99% |
| Uber | TRANSPORT | 99% |
| Netflix | SUBSCRIPTIONS | 99% |
| Amazon | SHOPPING | 99% |
| Spotify | ENTERTAINMENT | 99% |

### Test 2: Typos/Variations (Medium Confidence - Fuzzy Matching)
These should still categorize correctly:
| Merchant | Expected Category | Method |
|----------|------------------|--------|
| SWIGY (typo) | FOOD | Fuzzy match |
| swiggy (lowercase) | FOOD | Exact match |
| SWIGGY DELIVERY | FOOD | Keyword extraction |

### Test 3: Unknown Merchants (Low Confidence - Fallback)
These will likely be miscellaneous:
| Merchant | Expected Category |
|----------|------------------|
| Random Shop | MISCELLANEOUS |
| XYZ Vendor | MISCELLANEOUS |
| Unknown Corp | MISCELLANEOUS |

---

## Performance Testing

### CSV Upload Performance
**Expected**: <100ms for 20 transactions
**Actual**:
- Parsing: _____ ms
- Database Save: _____ ms
- Category Assignment: _____ ms
- Total: _____ ms

### PDF Upload Performance
**Expected**: <500ms for 5 transactions
**Actual**:
- Text Extraction: _____ ms
- Transaction Identification: _____ ms
- Parsing: _____ ms
- Database Save: _____ ms
- Category Assignment: _____ ms
- Total: _____ ms

---

## Error Testing

### Test 1: Invalid PDF File
**Steps**:
1. Delete test PDF and create empty file `empty.pdf`
2. Try to upload
3. **Expected**: Error message "Could not extract text from PDF"

### Test 2: Corrupted PDF
**Steps**:
1. Create corrupted PDF (rename image to .pdf)
2. Try to upload
3. **Expected**: Error message + graceful failure

### Test 3: PDF with No Transactions
**Steps**:
1. Create PDF with only headers (no transaction rows)
2. Try to upload
3. **Expected**: Error message "No transactions found in PDF"

---

## Regression Testing (Ensure CSV Still Works)

After all PDF tests, verify CSV still works:
1. Upload `sample_transactions.csv` again
2. **Expected**: Same results as Part 1
3. ✅ Verify: All 20 transactions loaded
4. ✅ Verify: Same categories and totals

---

## Data Privacy Testing (Optional)

### Test 1: Transaction Deletion
1. Upload transactions
2. Clear app data
3. Restart app
4. **Expected**: Dashboard should be empty

### Test 2: Encryption (When Enabled)
1. Upload sensitive transactions
2. Check device file system
3. **Expected**: Data should be encrypted (not readable as plain text)

---

## Success Criteria Summary

### ✅ MUST PASS (Critical)
- [ ] PDF upload button works (no "in progress" message)
- [ ] 5 transactions extracted from test PDF with 100% accuracy
- [ ] Categories assigned correctly for common merchants (99%+ accuracy)
- [ ] Dashboard updates after PDF upload
- [ ] CSV upload still works (regression test)

### ✅ SHOULD PASS (Important)  
- [ ] Multiple date formats recognized
- [ ] Multiple amount formats recognized
- [ ] Unknown merchants extracted and categorized
- [ ] Performance <500ms for PDF processing

### ✅ NICE TO HAVE (Enhancement)
- [ ] Fuzzy matching works for typos
- [ ] Amount-based fallback categorization works
- [ ] All error messages are clear and helpful

---

## Test Results

### CSV Upload Test
**Date**: ________  
**Result**: ✅ PASS / ❌ FAIL  
**Notes**: _____________________________

### PDF Upload Test (5 transactions)
**Date**: ________  
**Result**: ✅ PASS / ❌ FAIL  
**Transactions Extracted**: ___ / 5  
**Notes**: _____________________________

### Categorization Test
**Date**: ________  
**Result**: ✅ PASS / ❌ FAIL  
**Accuracy**: ____%  
**Notes**: _____________________________

### Performance Test
**Date**: ________  
**CSV Processing**: _____ ms  
**PDF Processing**: _____ ms  
**Result**: ✅ PASS / ❌ FAIL  

### Overall Result
**Date**: ________  
**Overall**: ✅ PRODUCTION READY / ❌ NEEDS FIXES  

---

## PDF Creation Tips (For Testing)

### Easy Way: Use Word/Google Docs
1. Create document with transaction data
2. Export as PDF
3. Send to phone
4. Open with file manager and upload

### Medium Way: Use Text Editor
1. Create `.txt` file with transaction data
2. Use online tool to convert TXT → PDF
3. Download PDF
4. Upload to app

### Verification: Is PDF Text-Based?
- Open PDF in text editor
- If you can read it, it's text-based ✓
- If it shows binary/images, it's scanned ✗

---

## Support

If tests fail:
1. Check error message in app
2. Verify PDF format (text-based, not scanned)
3. Check transaction format matches samples
4. Ensure merchant names are in keyword list
5. Reach out with error message and PDF sample

