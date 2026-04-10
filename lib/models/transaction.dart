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

  /// The ID of the upload this transaction belongs to.
  final String uploadId;

  /// When the transaction was created in the system.
  final DateTime createdAt;

  /// Whether the transaction should be ignored in calculations.
  final bool isIgnored;

  /// The category assigned to the transaction (e.g., 'food', 'transport').
  final String category;

  /// AI confidence score for the categorization (0.0 to 1.0).
  final double confidence;

  /// Whether this transaction is identified as recurring.
  final bool isRecurring;

  /// User's note about the transaction.
  final String? userNote;

  TransactionModel({
    required this.id,
    required this.timestamp,
    required this.amount,
    required this.currency,
    this.description,
    required this.credit,
    this.merchant,
    this.paymentMethod,
    this.uploadId = 'unknown',
    this.category = 'miscellaneous',
    this.confidence = 1.0,
    this.isRecurring = false,
    this.isIgnored = false,
    this.userNote,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Returns the date and time of the transaction in a human-readable format.
  String get formattedDateTime {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  /// Returns the amount of the transaction in the user's preferred currency.
  String get formattedAmount {
    return amount.toStringAsFixed(2);
  }

  /// Converts the model to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'amount': amount,
      'currency': currency,
      'description': description,
      'credit': credit,
      'merchant': merchant,
      'paymentMethod': paymentMethod,
      'uploadId': uploadId,
      'category': category,
      'confidence': confidence,
      'isRecurring': isRecurring,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isIgnored': isIgnored,
      'userNote': userNote,
    };
  }

  /// Creates a model from a map.
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'INR',
      description: map['description'],
      credit: map['credit'] ?? false,
      merchant: map['merchant'],
      paymentMethod: map['paymentMethod'],
      uploadId: map['uploadId'] ?? 'unknown',
      category: map['category'] ?? 'miscellaneous',
      confidence: (map['confidence'] as num? ?? 1.0).toDouble(),
      isRecurring: map['isRecurring'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      isIgnored: map['isIgnored'] ?? false,
      userNote: map['userNote'],
    );
  }

  /// Returns a copy with updated fields.
  TransactionModel copyWith({
    String? id,
    int? timestamp,
    double? amount,
    String? currency,
    String? description,
    bool? credit,
    String? merchant,
    String? paymentMethod,
    String? uploadId,
    String? category,
    double? confidence,
    bool? isRecurring,
    DateTime? createdAt,
    bool? isIgnored,
    String? userNote,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      credit: credit ?? this.credit,
      merchant: merchant ?? this.merchant,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      uploadId: uploadId ?? this.uploadId,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      isIgnored: isIgnored ?? this.isIgnored,
      userNote: userNote ?? this.userNote,
    );
  }

  /// Returns a string representation of the transaction model.
  @override
  String toString() {
    return 'TransactionModel($id, $merchant, \u{20B9}$amount, $category)';
  }
}
