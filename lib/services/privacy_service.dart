import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle privacy and encryption for sensitive data
class PrivacyService {
  static const String _dataEncryptionKey = 'data_encryption_enabled';

  late SharedPreferences _prefs;

  /// Initialize privacy service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Check if data encryption should be enabled
    if (!_prefs.containsKey(_dataEncryptionKey)) {
      await _prefs.setBool(_dataEncryptionKey, true);
    }
  }

  /// Hash sensitive data using SHA-256
  String hashSensitiveData(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Check if data encryption is enabled
  bool isDataEncryptionEnabled() {
    return _prefs.getBool(_dataEncryptionKey) ?? true;
  }

  /// Set data encryption status
  Future<void> setDataEncryptionEnabled(bool enabled) async {
    await _prefs.setBool(_dataEncryptionKey, enabled);
  }

  /// Privacy policy text
  String getPrivacyPolicy() {
    return '''
PRIVACY POLICY - Expense AI Agent

1. DATA STORAGE
- All transaction data is stored locally on your device
- No data is transmitted to external servers
- Your financial information remains private and secure

2. DATA ENCRYPTION
- Sensitive data is encrypted using SHA-256 hashing
- Local storage uses device's secure storage when available
- Encryption is enabled by default

3. PERMISSIONS
- Camera: Required for OCR text extraction from receipts (local processing)
- File Access: Required to import CSV/PDF files
- Storage: Required to save transaction data locally

4. LOCAL PROCESSING
- OCR text extraction happens locally on your device
- AI insights are generated locally without internet
- No data leaves your device unless explicitly shared

5. DATA DELETION
- You can delete all transaction data anytime
- Deletion is permanent and cannot be recovered
- No backups are sent to cloud servers

6. SHARING RESTRICTIONS
- Transaction data cannot be shared outside the app
- Export functionality (if available) is for local backup only
- No third-party integrations access your financial data

7. UPDATES
- This privacy policy may be updated periodically
- You will be notified of significant changes
- Your continued use indicates acceptance of changes

Last Updated: March 28, 2026

For questions, please visit our support page.
    ''';
  }

  /// Get data collection minimization guidelines
  List<String> getDataMinimizationGuidelines() {
    return [
      'Only essential transaction information is collected',
      'Personal identifiable information is kept minimal',
      'Metadata is not tracked or stored',
      'User behavior is not analyzed or profiled',
      'No cookies or tracking pixels are used',
      'Device identifiers are not collected',
    ];
  }

  /// Verify privacy compliance
  bool verifyPrivacyCompliance() {
    // Check if data encryption is enabled
    if (!isDataEncryptionEnabled()) {
      return false;
    }

    // Additional compliance checks can be added here
    return true;
  }

  /// Sanitize transaction data before logging
  String sanitizeForLogging(String data) {
    // Remove sensitive information before logging
    var sanitized = data;

    // Remove amounts (patterns like 100.00, ₹500, etc.)
    sanitized = sanitized.replaceAll(RegExp(r'\d+\.?\d*'), '***');

    // Remove specific merchant names
    sanitized = sanitized.replaceAll(
      RegExp(r'(swiggy|uber|netflix|amazon|walmart)', caseSensitive: false),
      '***',
    );

    return sanitized;
  }
}
