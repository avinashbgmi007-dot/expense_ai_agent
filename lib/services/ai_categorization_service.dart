import '../models/transaction.dart';

/// AI-enhanced Categorization Service targeting 99%+ accuracy.
///
/// Three-pass system:
///   1. Exact merchant/description rules (highest priority)
///   2. Expanded keyword dictionary matching
///   3. Context-aware defaults (amount, credit/debit, recurring patterns)
class AICategorizationService {
  // =========================================================================
  // PASS 1: Exact merchant → category rules
  // These override everything else.
  // Short names (<= 3 chars) use exact match only to prevent false positives.
  // =========================================================================

  static const _merchantRules = <String, String>{
    // Transfers (person-to-person) — longer names, safe for substring matching
    'pasanna pragada': 'transfers',
    'g sravan': 'transfers',
    'chavidi balaiah': 'transfers',
    'manchala sravanthi': 'transfers',
    'kandala mane esha bal': 'transfers',
    'korra sunitha': 'transfers',
    'anipindi durgaprasad': 'transfers',
    'seethala manasa': 'transfers',
    'madani hemanth kumar': 'transfers',
    'bathula naveen kumar': 'transfers',
    'kondapalli deepthika': 'transfers',
    'karamtothu ravi': 'transfers',
    'nagati bhiksha pathi': 'transfers',
    'oruganti yadaiah': 'transfers',
    'jakkula bhaskar': 'transfers',
    'aleti shekar reddy': 'transfers',
    'sher khan mohammed': 'transfers',
    'manne sai vardhan': 'transfers',
    'samruddhi amrutulya': 'transfers',
    'bachalakuri purnaiah': 'transfers',
    'dumpa rambabu': 'transfers',
    'murugan kanniyapp': 'transfers',
    'ch v k subramanyam': 'transfers',
    'kolluru sai ram': 'transfers',
    'ramavath mounika': 'transfers',
    'jafruddin khan': 'transfers',
    'alpati gopal': 'transfers',
    'gaddam sai baba': 'transfers',
    'emmarasu kumar': 'transfers',
    'nema ram chaudhary': 'transfers',

    // Short names — exact match only (won't substring-match longer merchants)
    'santosh': 'transfers',
    'sani': 'transfers',
    'cash': 'transfers',
    'avinash': 'transfers',

    // Known businesses
    'shiva shankar vegetables': 'food',
    'mamu s food': 'food',
    'raksh medical': 'healthcare',
    'rakesh medical': 'healthcare',
    'city court': 'transport',
    'select cars': 'transport',

    // Income
    'capgemini': 'income',
    'google india': 'income',
    'cityflo': 'income',

    // Bills / Charges
    'sms charges': 'bills',
    'debit card charges': 'bills',
    'pmsby insurance': 'healthcare',
    'accidental insurance': 'healthcare',
    'pmsby': 'healthcare',
    'hmwssb bill': 'utilities',
    'hmwssb': 'utilities',
    'accidental ins': 'healthcare',
    'hdfc credit card bill': 'bills',

    // Payment gateways — only match exact, so "Paytm - Jio recharge" falls
    // through to Pass 2/3 description rules which correctly identify mobile/food/etc.
    'uidai': 'finance',
    'bharatpe': 'finance',
    'payzapp wallet': 'finance',
    'npci bhim': 'finance',
    'cred': 'finance',
    'google pay': 'finance',
    'mobikwik': 'finance',

    // Banks & internal
    'bank transfer': 'transfers',
    'neft': 'transfers',
    'rtgs': 'transfers',
    'imps': 'transfers',

    // Insurance / Investments
    'lic': 'finance',
    'lic of india': 'finance',
    'lic premium': 'finance',
    'ppf': 'finance',
    'mutual fund': 'finance',
    'zerodha': 'finance',
    'groww': 'finance',
    'upstox': 'finance',
    'angel one': 'finance',

    // Food delivery / quick commerce
    'zomato': 'food',
    'zomato instant': 'food',
    'swiggy': 'food',
    'swiggy instamart': 'food',
    'blinkit': 'food',
    'zepto': 'food',
    'bigbasket': 'food',
    'bb now': 'food',
    'amazon fresh': 'food',
    'instamart': 'food',

    // Shopping
    'amazon': 'shopping',
    'flipkart': 'shopping',
    'myntra': 'shopping',
    'ajio': 'shopping',
    'meesho': 'shopping',
    'nykaa': 'shopping',

    // Subscriptions
    'netflix': 'subscriptions',
    'amazon prime': 'subscriptions',
    'spotify': 'subscriptions',
    'youtube premium': 'subscriptions',
    'hotstar': 'subscriptions',
    'disney hotstar': 'subscriptions',
    'youtube music': 'subscriptions',
    'jiocinema': 'subscriptions',
    'sony liv': 'subscriptions',

    // Healthcare
    'apollo': 'healthcare',
    'fortis': 'healthcare',
    'max hospital': 'healthcare',
    'medplus': 'healthcare',
    'apollo pharmacy': 'healthcare',

    // Mobile
    'jio': 'mobile',
    'jio recharge': 'mobile',
    'airtel': 'mobile',
    'vodafone': 'mobile',
    'bsnl': 'mobile',

    // Transport
    'uber': 'transport',
    'ola': 'transport',
    'rapido': 'transport',
    'redbus': 'transport',
    'goibibo': 'transport',
    'makemytrip': 'transport',
    'indigo': 'transport',
    'irctc': 'transport',

    // Bills / Utilities
    'tata power': 'utilities',
    'electricity': 'utilities',
    'gas bill': 'utilities',
    'adani gas': 'utilities',
    'indiclpg': 'utilities',
    'broadband': 'utilities',
    'internet': 'utilities',
    'wifi': 'utilities',
  };

  // =========================================================================
  // PASS 2: Description patterns
  // Checks combined merchant + description text for more coverage.
  // =========================================================================

  static const List<MapEntry<String, String>> _descriptionPatterns = [
    MapEntry(r'by\s+cash', 'transfers'),
    MapEntry(r'^by\s+\d', 'transfers'),
    MapEntry(r'^frm\s+\d', 'transfers'),
    MapEntry(r'int\.pd|interest credited', 'income'),
    MapEntry(r'pmsby', 'healthcare'),
    MapEntry(r'accidental ins', 'healthcare'),
    MapEntry(r'sms charges', 'bills'),
    MapEntry(r'debit card charges', 'bills'),
    MapEntry(r'credit card bill', 'bills'),
    MapEntry(r'hmwssb', 'utilities'),
    MapEntry(r'salary|credit salary', 'income'),
    MapEntry(r'cash withdrawal|atm withdrawal', 'transfers'),
    MapEntry(r'nach|auto.?pay|mandate|sip', 'subscriptions'),
    MapEntry(r'insurance premium|lic premium', 'finance'),
    MapEntry(r'electricity|power bill|tneb', 'utilities'),
    MapEntry(r'toll|parking|fuel|petrol\b|diesel', 'transport'),
    MapEntry(r'mobile recharge|prepaid|postpaid\b', 'mobile'),
    MapEntry(r'jio\s+recharge|airtel\s+recharge', 'mobile'),
    MapEntry(r'\brecharge\.\b|\bmobile\b', 'mobile'),
    MapEntry(r'gst|tds', 'bills'),
  ];

  // =========================================================================
  // PASS 3: Expanded keyword dictionary
  // =========================================================================

  static const Map<String, List<String>> _categoryKeywords = {
    'food': [
      'swiggy', 'zomato', 'dominos', 'uber eats', 'starbucks', 'coffee',
      'pizza', 'burger', 'restaurant', 'cafe', 'diner', 'bakery', 'fast food',
      'food delivery', 'grocery', 'supermarket', 'kirana', 'tiffin', 'dessert',
      'kitchen', 'sweets', 'catering', 'big basket', 'reliance fresh',
      'bb now', 'tiffins', 'samosa', 'biryani', 'dosa',
      'idli', 'vada', 'chai', 'tea', 'thali', 'pani puri', 'chat',
      'veg', 'non veg', 'mess', 'canteen', 'lunch', 'dinner', 'breakfast',
      'snacks', 'juice', 'milk', 'butter', 'bread', 'atta', 'rice', 'dal',
      'zepto', 'blinkit', 'instamart',
    ],
    'transport': [
      'uber', 'ola', 'rapido', 'taxi', 'auto', 'bus', 'train', 'flight',
      'airline', 'goibibo', 'makemytrip', 'redbus', 'vahan', 'parking',
      'fuel', 'petrol', 'diesel', 'ev charging', 'toll', 'irctc',
      'indigo', 'spicejet', 'air india', 'metro', 'ola share',
    ],
    'shopping': [
      'amazon', 'flipkart', 'ebay', 'myntra', 'ajio', 'nykaa',
      'uniqlo', 'forever 21', 'gap', 'clothing', 'clothes',
      'shoes', 'apparel', 'fashion', 'saree', 'kurta', 'meesho',
      'h&m', 'h and m', 'zara', 'westside', 'max fashion',
      'ordered from', 'purchase order', 'order place',
    ],
    'subscriptions': [
      'netflix', 'amazon prime', 'spotify', 'youtube', 'hotstar',
      'apple music', 'disney', 'zee', 'sony liv', 'gym', 'fitpass',
      'cult.fit', 'cultfit', 'monthly', 'yearly', 'annual',
      'subscription', 'plan', 'membership',
      'jiocinema', 'airtel xstream', 'sun direct', 'tata play',
      'dth', 'set top box',
    ],
    'entertainment': [
      'bookmyshow', 'cinema', 'movie', 'concert', 'event', 'ticket',
      'amusement', 'park', 'zoo', 'museum', 'games', 'gaming',
      'playstation', 'xbox', 'steam', 'pvr', 'inox',
      'paytm insider', 'insider',
    ],
    'utilities': [
      'electricity', 'water', 'gas', 'broadband', 'wifi',
      'power', 'insurance', 'hmwssb', 'tata power', 'tneb',
      'adani gas', 'indiclpg', 'indane', 'lpg', 'gas booking',
      'cable', 'dth', 'society maintenance', 'maintenance charges',
    ],
    'mobile': [
      'jio', 'airtel', 'vodafone', 'bsnl', 'mobile recharge',
      'prepaid', 'postpaid', 'data topup', 'top up',
    ],
    'healthcare': [
      'apollo', 'fortis', 'max hospital', 'doctor', 'hospital',
      'clinic', 'medicine', 'pharmacy', 'health check', 'dental', 'therapy',
      'physio', 'health insurance', 'pmsby', 'accidental ins', 'siri vallabh',
      'diagnostic', 'lab test', 'blood test', 'xray', 'scan', 'mri',
      'eye care', 'optical', 'spectacles', 'lens',
      'medplus', 'netmeds', '1mg', 'pharmeasy',
    ],
    'bills': [
      'bill', 'charges', 'penalty', 'late fee', 'gst', 'tax', 'tds',
      'stamp duty', 'registration fee', 'processing fee',
    ],
    'finance': [
      'bank', 'atm', 'stock', 'broker', 'investment', 'mutual fund',
      'trading', 'tax', 'uidai', 'bharatpe', 'paytm',
      'payzapp', 'npci', 'bhim', 'wallet',
      'zerodha', 'groww', 'upstox', 'angel one',
      'credit card payment', 'cc bill',
      'ppf', 'fd', 'rd', 'fixed deposit', 'recurring deposit',
    ],
    'income': [
      'capgemini', 'salary', 'wage', 'dividend', 'google india',
      'interest credited', 'refund', 'cashback', 'offer', 'reward',
      'reversal', 'credit salary',
    ],
    'transfers': [
      'sent to', 'received from', 'transfer', 'upi',
      'person to person', 'p2p',
    ],
    'miscellaneous': [],
  };

  // =========================================================================
  // Public API
  // =========================================================================

  /// Quick synchronous categorization.
  String categorize(String merchant) =>
      categorizeWithDescription(merchant, '', false, 0.0);

  /// Categorize with full context: merchant, remarks, credit/debit, amount.
  String categorizeWithDescription(
    String merchant,
    String description,
    bool isCredit,
    double amount,
  ) {
    final merchantLower = merchant.toLowerCase();
    final descLower = description.toLowerCase();
    final combined = '$merchantLower $descLower'.trim();

    // Payment gateway check: if merchant is a payment aggregator (Paytm, PhonePe,
    // Cred, UPI, etc.) and there's a meaningful description, defer to Pass 2/3
    // to categorize based on the actual service/product, not the payment channel.
    final isPaymentGateway = _isPaymentGateway(merchantLower);
    if (isPaymentGateway && descLower.isNotEmpty && descLower.length > 3) {
      final pass2Result = _pass2DescriptionPatterns(combined);
      if (pass2Result != null) return pass2Result;
      final pass3Result = _pass3Keywords(combined);
      if (pass3Result != null) return pass3Result;
      return _contextDefault(combined, isCredit, amount);
    }

    // Pass 1: Exact/Substring merchant rules (overrides everything)
    final result = _pass1MerchantRules(merchantLower, combined);
    if (result != null) return result;

    // Pass 2: Description/combined patterns
    final pass2Result = _pass2DescriptionPatterns(combined);
    if (pass2Result != null) return pass2Result;

    // Pass 3: Keyword dictionary
    final pass3Result = _pass3Keywords(combined);
    if (pass3Result != null) return pass3Result;

    // Pass 4: Context-aware defaults
    return _contextDefault(combined, isCredit, amount);
  }

  /// Payment gateways that act as conduits rather than actual merchants.
  /// For these we defer to Pass 2/3 description matching when description exists.
  bool _isPaymentGateway(String merchantLower) {
    const gateways = {'paytm', 'phonepe', 'cred', 'bhim', 'upi'};
    return gateways.any((g) => merchantLower == g || merchantLower.contains(g));
  }

  /// Categorize transaction using full context.
  Future<String> categorizeTransaction(TransactionModel transaction) async {
    return categorizeWithDescription(
      transaction.merchant ?? '',
      transaction.description ?? '',
      transaction.credit,
      transaction.amount,
    );
  }

  // =========================================================================
  // Pass 1: Merchant Rules
  // Short merchant names (<= 3 chars or common false-positive names) use
  // exact match only. Longer names use substring matching.
  // =========================================================================

  static const _shortExactNames = <String>{'cash', 'sani', 'avinash', 'santosh', 'bhim'};

  String? _pass1MerchantRules(String merchantLower, String combined) {
    for (final entry in _merchantRules.entries) {
      final ruleKey = entry.key;
      final keyShort = _shortExactNames.contains(ruleKey);

      if (keyShort) {
        // Exact match only — don't let "cash" match "cashew nuts" or "avinash" match "avinash restaurant"
        if (merchantLower == ruleKey) return entry.value;
      } else {
        // Longer names: substring match is safe
        if (merchantLower == ruleKey || merchantLower.contains(ruleKey)) {
          return entry.value;
        }
      }
    }
    return null;
  }

  // =========================================================================
  // Pass 2: Description/Combined Patterns
  // =========================================================================

  String? _pass2DescriptionPatterns(String combined) {
    if (combined.isEmpty) return null;
    for (final pattern in _descriptionPatterns) {
      if (RegExp(pattern.key, caseSensitive: false).hasMatch(combined)) {
        return pattern.value;
      }
    }
    return null;
  }

  // =========================================================================
  // Pass 3: Keyword Dictionary
  // =========================================================================

  String? _pass3Keywords(String combined) {
    if (combined.isEmpty) return null;
    for (final entry in _categoryKeywords.entries) {
      if (entry.value.isEmpty) continue;
      for (final keyword in entry.value) {
        if (_fuzzyMatch(combined, keyword)) return entry.key;
      }
    }
    return null;
  }

  // =========================================================================
  // Context-aware defaults
  // =========================================================================

  String _contextDefault(String text, bool isCredit, double amount) {
    // Credits
    if (isCredit) {
      if (amount > 10000) return 'income';
      if (text.contains('salary') || text.contains('interest')) return 'income';
      if (text.contains('refund') || text.contains('cashback') || text.contains('reversal')) return 'income';
      if (amount > 500) return 'transfers';
      return 'income';
    }

    // Debits
    if (amount < 50) return 'bills';
    if (amount < 200) {
      if (_isSubscriptionDescription(text)) return 'subscriptions';
      if (_isRecurringDescription(text)) return 'bills';
      return 'food';
    }
    if (amount < 2000) {
      if (_isSubscriptionDescription(text)) return 'subscriptions';
      if (text.contains('fuel') || text.contains('petrol') || text.contains('parking')) return 'transport';
      return 'food'; // most common small-mid debit in India
    }
    if (amount > 10000) {
      if (_isSubscriptionDescription(text)) return 'subscriptions';
      return 'miscellaneous'; // large amounts without clear signal
    }

    return 'miscellaneous';
  }

  // =========================================================================
  // Helpers
  // =========================================================================

  bool _fuzzyMatch(String text, String keyword) {
    if (text.contains(keyword)) return true;
    final textWords = text.split(RegExp(r'[\s/.,@|_:()\-]+'));
    for (final word in textWords) {
      final clean = word.replaceAll(RegExp(r'[^\w]'), '');
      if (clean.isEmpty) continue;
      // Keywords ≤ 4 chars: exact word match only (prevent false positives)
      if (keyword.length <= 4 && clean == keyword) return true;
      // Keywords 5-10 chars: fuzzy match with distance ≤ 2
      if (clean.length <= 12 && keyword.length >= 5 && keyword.length <= 10 &&
          _levenshteinDistance(clean, keyword) <= 2) {
        return true;
      }
    }
    return false;
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    final prevRow = List.filled(s2.length + 1, 0);
    for (int i = 0; i <= s2.length; i++) prevRow[i] = i;
    for (int i = 0; i < s1.length; i++) {
      final currRow = List.filled(s2.length + 1, 0);
      currRow[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        final cost = s1[i] == s2[j] ? 0 : 1;
        currRow[j + 1] = [
          prevRow[j + 1] + 1,
          currRow[j] + 1,
          prevRow[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      prevRow.setAll(0, currRow);
    }
    return prevRow[s2.length];
  }

  bool _isRecurringDescription(String text) {
    final patterns = ['monthly', 'quarter', 'annual', 'yearly', 'every'];
    return patterns.any((p) => text.contains(p));
  }

  bool _isSubscriptionDescription(String text) {
    final patterns = [
      'subscription', 'monthly', 'quarterly', 'yearly', 'annual',
      'auto-pay', 'autopay', 'mandate', 'nach', 'sip', 'plan',
      'membership', 'recurring', 'premium',
    ];
    return patterns.any((p) => text.contains(p));
  }

  /// Get confidence for the categorization (0.0 - 1.0).
  double getConfidence(
    String category,
    String merchant,
    String description,
    bool isCredit,
  ) {
    final merchantLower = merchant.toLowerCase();
    if (_shortExactNames.contains(merchantLower) && _merchantRules[merchantLower] != null) return 0.99;
    if (_merchantRules.containsKey(merchantLower)) return 0.99;
    if (_merchantRules.keys.any((k) => merchantLower.contains(k))) {
      return 0.97;
    }
    final combined = '${merchantLower} ${description.toLowerCase()}'.trim();
    if (_descriptionPatterns.any(
        (p) => RegExp(p.key, caseSensitive: false).hasMatch(combined))) {
      return 0.90;
    }
    if (_categoryKeywords[category]
            ?.any((k) => combined.contains(k)) ??
        false) {
      return 0.80;
    }
    return 0.50;
  }

  List<String> getSupportedCategories() {
    return _categoryKeywords.keys.where((k) => k != 'miscellaneous').toList();
  }
}
