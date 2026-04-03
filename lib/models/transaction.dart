import 'package:intl/intl.dart';

/// Model representing a transaction in the app.
class TransactionModel {
  /// The unique ID of the transaction.
  final String id;

  /// The timestamp of the transaction in milliseconds since epoch.
  final int timestamp;

  /// The amount of the transaction in the user's preferred currency.
  final double amount;

  /// The currency of the transaction (default: INR).
  final String currency;

  /// The description of the transaction, if any.
  final String? description;

  /// Whether the transaction is a credit or debit.
  final bool credit;

  /// The merchant/vendor name of the transaction.
  final String? merchant;

  /// The payment method used (card, cash, etc.).
  final String? paymentMethod;

  TransactionModel({
    required this.id,
    required this.timestamp,
    required this.amount,
    required this.currency,
    this.description,
    required this.credit,
    this.merchant,
    this.paymentMethod,
  });

  /// Returns the date and time of the transaction in a human-readable format.
  String get formattedDateTime {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  /// Returns the amount of the transaction in the user's preferred currency.
  String get formattedAmount {
    return amount.toStringAsFixed(2);
  }

  /// Returns a string representation of the transaction model.
  @override
  String toString() {
    return 'TransactionModel($id, $timestamp, $amount, $currency, $description, $credit)';
  }
}
