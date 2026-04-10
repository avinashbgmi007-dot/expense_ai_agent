import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';
import '../models/subscription.dart';
import '../models/monthly_summary.dart';

/// DatabaseService class to manage local data persistence.
class DatabaseService {
  static const String _transactionsKey = 'transactions';
  static const String _subscriptionsKey = 'subscriptions';
  static const String _summariesKey = 'monthly_summaries';
  SharedPreferences? _prefs;

  /// Initialize the database.
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> _getPrefs() async {
    await initialize();
    return _prefs!;
  }

  /// Insert a transaction into the database.
  Future<void> insertTransaction(TransactionModel transaction) async {
    final transactions = getTransactions();
    transactions.add(transaction);
    await _saveTransactions(transactions);
  }

  /// Get all transactions from the database.
  List<TransactionModel> getTransactions() {
    if (_prefs == null) return [];
    final String? jsonString = _prefs!.getString(_transactionsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((t) => TransactionModel.fromMap(t as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update a transaction in the database.
  Future<void> updateTransaction(TransactionModel transaction) async {
    final transactions = getTransactions();
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index >= 0) {
      transactions[index] = transaction;
      await _saveTransactions(transactions);
    }
  }

  /// Delete a transaction from the database.
  Future<void> deleteTransaction(String id) async {
    final transactions = getTransactions();
    transactions.removeWhere((t) => t.id == id);
    await _saveTransactions(transactions);
  }

  Future<void> _saveTransactions(List<TransactionModel> transactions) async {
    final prefs = await _getPrefs();
    final encoded = jsonEncode(transactions.map((t) => t.toMap()).toList());
    await prefs.setString(_transactionsKey, encoded);
  }

  /// Save detected subscriptions.
  Future<void> saveSubscriptions(List<SubscriptionModel> subs) async {
    final prefs = await _getPrefs();
    final encoded = jsonEncode(subs.map((s) => s.toMap()).toList());
    await prefs.setString(_subscriptionsKey, encoded);
  }

  /// Get all subscriptions.
  List<SubscriptionModel> getSubscriptions() {
    if (_prefs == null) return [];
    final String? jsonString = _prefs!.getString(_subscriptionsKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((s) => SubscriptionModel.fromMap(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save monthly summary cache.
  Future<void> saveMonthlySummary(MonthlySummary summary) async {
    final summaries = getMonthlySummaries();
    final index = summaries.indexWhere((s) => s.monthYear == summary.monthYear);

    if (index >= 0) {
      summaries[index] = summary;
    } else {
      summaries.add(summary);
    }

    final prefs = await _getPrefs();
    final encoded = jsonEncode(summaries.map((s) => s.toMap()).toList());
    await prefs.setString(_summariesKey, encoded);
  }

  /// Get cached monthly summaries.
  List<MonthlySummary> getMonthlySummaries() {
    if (_prefs == null) return [];
    final String? jsonString = _prefs!.getString(_summariesKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((s) => MonthlySummary.fromMap(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
