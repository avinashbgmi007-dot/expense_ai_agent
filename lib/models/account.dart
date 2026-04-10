// lib/models/account.dart
class Account {
  final int? id;
  final String name;
  final String type; // 'bank', 'credit_card', 'cash', 'investment'
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final double balance;
  final String? institution;
  final String? accountNumberHash;

  const Account({
    this.id,
    required this.name,
    required this.type,
    this.currency = 'INR',
    this.isActive = true,
    required this.createdAt,
    this.balance = 0.0,
    this.institution,
    this.accountNumberHash,
  });

  Account copyWith({
    int? id,
    String? name,
    String? type,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
    double? balance,
    String? institution,
    String? accountNumberHash,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      balance: balance ?? this.balance,
      institution: institution ?? this.institution,
      accountNumberHash: accountNumberHash ?? this.accountNumberHash,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'currency': currency,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'balance': balance,
      'institution': institution,
      'accountNumberHash': accountNumberHash,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as int?,
      name: json['name'] as String,
      type: json['type'] as String,
      currency: json['currency'] as String? ?? 'INR',
      isActive: (json['isActive'] as int?) == 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      institution: json['institution'] as String?,
      accountNumberHash: json['accountNumberHash'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.currency == currency &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.balance == balance &&
        other.institution == institution &&
        other.accountNumberHash == accountNumberHash;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      type,
      currency,
      isActive,
      createdAt,
      balance,
      institution,
      accountNumberHash,
    );
  }

  @override
  String toString() {
    return 'Account(id: $id, name: $name, type: $type, balance: $balance)';
  }
}