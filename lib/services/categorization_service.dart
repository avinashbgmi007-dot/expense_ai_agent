import '../models/transaction.dart';

/// CategorizationService is responsible for categorizing transactions into different categories based on their keywords, amount, and other heuristics.
class CategorizationService {
  /// List of merchant keywords database used for categorization.
  final List<String> _keywords;

  /// Mapping of known merchants to their categories
  static const Map<String, String> _merchantCategoryMap = {
    'swiggy': 'food',
    'uber': 'transport',
    'netflix': 'subscriptions',
    'amazon': 'shopping',
  };

  /// Constructor for CategorizationService.
  CategorizationService(this._keywords);

  /// Simple synchronous categorize method for merchant names
  String categorize(String merchant) {
    final lowerMerchant = merchant.toLowerCase();

    // Check for exact match in merchant map
    if (_merchantCategoryMap.containsKey(lowerMerchant)) {
      return _merchantCategoryMap[lowerMerchant]!;
    }

    // Check for known merchants with fuzzy matching
    for (final merchantKey in _merchantCategoryMap.keys) {
      // Check for partial matches or fuzzy matching
      if (_isFuzzyMatch(lowerMerchant, merchantKey)) {
        return _merchantCategoryMap[merchantKey] ?? 'miscellaneous';
      }
    }

    // Check for partial matches in keywords
    for (final keyword in _keywords) {
      if (lowerMerchant.contains(keyword.toLowerCase()) ||
          keyword.toLowerCase().contains(lowerMerchant)) {
        // Simple categorization based on keyword
        final keywordLower = keyword.toLowerCase();
        if (keywordLower.contains('food') || keywordLower.contains('swiggy')) {
          return 'food';
        }
        if (keywordLower.contains('transport') ||
            keywordLower.contains('uber')) {
          return 'transport';
        }
        if (keywordLower.contains('subscription') ||
            keywordLower.contains('netflix')) {
          return 'subscriptions';
        }
      }
    }

    // Default category for unknown merchants
    return 'miscellaneous';
  }

  /// Check if two strings match with fuzzy matching (ignoring spaces and minor typos)
  bool _isFuzzyMatch(String input, String reference) {
    // Remove spaces for comparison
    final inputNoSpace = input.replaceAll(' ', '');

    // Check if reference is contained in input without spaces
    if (inputNoSpace.contains(reference)) {
      return true;
    }

    // Calculate Levenshtein distance for typo tolerance (increased threshold)
    if (reference.isNotEmpty &&
        _levenshteinDistance(inputNoSpace, reference) <= 2) {
      return true;
    }

    return false;
  }

  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final List<List<int>> dp = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1, // deletion
          dp[i][j - 1] + 1, // insertion
          dp[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[s1.length][s2.length];
  }

  /// Categorize a transaction based on its keywords, amount, and other heuristics.
  Future<String?> categorizeTransaction({
    required TransactionModel transaction,
  }) async {
    // Level 1: Match by keywords
    final keywords = await _matchByKeywords(transaction);
    if (keywords.isNotEmpty) {
      return keywords.first;
    }

    // Level 2: Match by amount heuristics
    final categories = await _matchByAmount(transaction);
    if (categories.isNotEmpty) {
      return categories.first;
    }

    // Level 3: Fallback
    return 'Other';
  }

  /// Match a transaction based on its keywords.
  Future<List<String>> _matchByKeywords(TransactionModel transaction) async {
    final List<String> keywords = [];
    final description = transaction.description?.toLowerCase() ?? '';
    final merchant = transaction.merchant?.toLowerCase() ?? '';

    for (final keyword in _keywords) {
      if (description.contains(keyword) || merchant.contains(keyword)) {
        keywords.add(keyword);
      }
    }
    return keywords;
  }

  /// Match a transaction based on its amount using heuristics.
  Future<List<String>> _matchByAmount(TransactionModel transaction) async {
    final List<String> categories = [];
    if (transaction.amount > 0 && transaction.amount < 100) {
      categories.add('Small_Expense');
    } else if (transaction.amount >= 100 && transaction.amount < 500) {
      categories.add('Medium_Expense');
    } else if (transaction.amount >= 500) {
      categories.add('Large_Expense');
    }
    return categories;
  }
}
