import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';

/// DatabaseService class to manage local data persistence.
class DatabaseService {
  static const String _transactionsKey = 'transactions';
  late SharedPreferences _prefs;

  /// Initialize the database.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Insert a transaction into the database.
  Future<void> insertTransaction(TransactionModel transaction) async {
    await initialize();
    final transactions = getTransactions();
    transactions.add(transaction);
    await _saveTransactions(transactions);
  }

  /// Get all transactions from the database.
  List<TransactionModel> getTransactions() {
    final String? jsonString = _prefs.getString(_transactionsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map(
            (t) => TransactionModel(
              id: t['id'] ?? '',
              timestamp: t['timestamp'] ?? 0,
              amount: (t['amount'] ?? 0).toDouble(),
              currency: t['currency'] ?? 'USD',
              description: t['description'],
              credit: t['credit'] ?? false,
              merchant: t['merchant'],
              paymentMethod: t['paymentMethod'],
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update a transaction in the database.
  Future<void> updateTransaction(TransactionModel transaction) async {
    await initialize();
    final transactions = getTransactions();
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index >= 0) {
      transactions[index] = transaction;
      await _saveTransactions(transactions);
    }
  }

  /// Delete a transaction from the database.
  Future<void> deleteTransaction(String id) async {
    await initialize();
    final transactions = getTransactions();
    transactions.removeWhere((t) => t.id == id);
    await _saveTransactions(transactions);
  }

  Future<void> _saveTransactions(List<TransactionModel> transactions) async {
    final encoded = jsonEncode(
      transactions
          .map(
            (t) => {
              'id': t.id,
              'timestamp': t.timestamp,
              'amount': t.amount,
              'currency': t.currency,
              'description': t.description,
              'credit': t.credit,
              'merchant': t.merchant,
              'paymentMethod': t.paymentMethod,
            },
          )
          .toList(),
    );
    await _prefs.setString(_transactionsKey, encoded);
  }
}
