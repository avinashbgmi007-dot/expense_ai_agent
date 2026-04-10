// lib/models/privacy_consent.dart
class PrivacyConsent {
  final String userId;
  final bool consentGiven;
  final List<String> featuresEnabled;
  final DateTime consentTimestamp;
  final DateTime? consentRevokedAt;
  final String? consentVersion;

  const PrivacyConsent({
    required this.userId,
    required this.consentGiven,
    required this.featuresEnabled,
    required this.consentTimestamp,
    this.consentRevokedAt,
    this.consentVersion,
  });

  // Check if consent is valid (not expired, not revoked)
  bool get isValid {
    if (!consentGiven) return false;
    if (consentRevokedAt != null) return false;

    // Consent expires after 1 year
    final expiryDate = consentTimestamp.add(Duration(days: 365));
    return DateTime.now().isBefore(expiryDate);
  }

  // Check if specific feature is enabled
  bool isFeatureEnabled(String feature) {
    return consentGiven && featuresEnabled.contains(feature);
  }

  PrivacyConsent copyWith({
    String? userId,
    bool? consentGiven,
    List<String>? featuresEnabled,
    DateTime? consentTimestamp,
    DateTime? consentRevokedAt,
    String? consentVersion,
  }) {
    return PrivacyConsent(
      userId: userId ?? this.userId,
      consentGiven: consentGiven ?? this.consentGiven,
      featuresEnabled: featuresEnabled ?? this.featuresEnabled,
      consentTimestamp: consentTimestamp ?? this.consentTimestamp,
      consentRevokedAt: consentRevokedAt ?? this.consentRevokedAt,
      consentVersion: consentVersion ?? this.consentVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'consentGiven': consentGiven,
      'featuresEnabled': featuresEnabled,
      'consentTimestamp': consentTimestamp.toIso8601String(),
      'consentRevokedAt': consentRevokedAt?.toIso8601String(),
      'consentVersion': consentVersion,
    };
  }

  factory PrivacyConsent.fromJson(Map<String, dynamic> json) {
    return PrivacyConsent(
      userId: json['userId'] as String,
      consentGiven: json['consentGiven'] as bool? ?? false,
      featuresEnabled: List<String>.from(json['featuresEnabled'] as List? ?? []),
      consentTimestamp: DateTime.parse(json['consentTimestamp'] as String),
      consentRevokedAt: json['consentRevokedAt'] != null
          ? DateTime.parse(json['consentRevokedAt'] as String)
          : null,
      consentVersion: json['consentVersion'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrivacyConsent &&
        other.userId == userId &&
        other.consentGiven == consentGiven &&
        other.featuresEnabled == featuresEnabled &&
        other.consentTimestamp == consentTimestamp &&
        other.consentRevokedAt == consentRevokedAt &&
        other.consentVersion == consentVersion;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      consentGiven,
      featuresEnabled,
      consentTimestamp,
      consentRevokedAt,
      consentVersion,
    );
  }

  @override
  String toString() {
    return 'PrivacyConsent(userId: $userId, consentGiven: $consentGiven, features: $featuresEnabled)';
  }
}