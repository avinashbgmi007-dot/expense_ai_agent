import 'package:test/test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:expense_ai_agent/services/privacy_service.dart';

void main() {
  group('PrivacyService', () {
    late PrivacyService service;

    setUp(() {
      service = PrivacyService();
    });

    test('should hash sensitive data using SHA-256', () {
      final data = 'sensitive_data_12345';
      final hash = service.hashSensitiveData(data);

      // Verify it matches SHA-256 hash
      final expectedHash = sha256.convert(utf8.encode(data)).toString();
      expect(hash, equals(expectedHash));
    });

    test('should produce consistent hashes', () {
      final data = 'test_data';
      final hash1 = service.hashSensitiveData(data);
      final hash2 = service.hashSensitiveData(data);

      expect(hash1, equals(hash2));
    });

    test('should produce different hashes for different data', () {
      final hash1 = service.hashSensitiveData('data1');
      final hash2 = service.hashSensitiveData('data2');

      expect(hash1, isNot(equals(hash2)));
    });

    test('should have data encryption enabled by default', () async {
      await service.initialize();
      final enabled = service.isDataEncryptionEnabled();
      expect(enabled, isTrue);
    });

    test('should toggle data encryption', () async {
      await service.initialize();
      await service.setDataEncryptionEnabled(false);
      var enabled = service.isDataEncryptionEnabled();
      expect(enabled, isFalse);

      await service.setDataEncryptionEnabled(true);
      enabled = service.isDataEncryptionEnabled();
      expect(enabled, isTrue);
    });

    test('should provide privacy policy text', () {
      final policy = service.getPrivacyPolicy();

      expect(policy, contains('PRIVACY POLICY'));
      expect(policy, contains('DATA STORAGE'));
      expect(policy, contains('DATA ENCRYPTION'));
      expect(policy, contains('LOCAL PROCESSING'));
      expect(policy.length, greaterThan(100));
    });

    test('should provide data minimization guidelines', () {
      final guidelines = service.getDataMinimizationGuidelines();

      expect(guidelines.length, greaterThan(0));
      expect(
        guidelines,
        contains('Only essential transaction information is collected'),
      );
      expect(
        guidelines,
        contains('Personal identifiable information is kept minimal'),
      );
    });

    test('should verify privacy compliance', () async {
      await service.initialize();
      final compliant = service.verifyPrivacyCompliance();

      // Should be compliant by default
      expect(compliant, isTrue);
    });

    test('should fail compliance check when encryption disabled', () async {
      await service.initialize();
      await service.setDataEncryptionEnabled(false);
      final compliant = service.verifyPrivacyCompliance();

      expect(compliant, isFalse);
    });

    test('should sanitize data for logging', () {
      final sensitiveData = 'Amount: ₹500, Merchant: Swiggy, Date: 2024-01-15';
      final sanitized = service.sanitizeForLogging(sensitiveData);

      // Should replace amounts with ***
      expect(sanitized, contains('***'));
      // Should replace merchant names
      expect(sanitized.toLowerCase(), isNot(contains('swiggy')));
    });

    test('should sanitize merchant names case-insensitively', () {
      final data1 = service.sanitizeForLogging('Transaction at AMAZON');
      final data2 = service.sanitizeForLogging('Transaction at amazon');

      // Both should be sanitized
      expect(data1.contains('***'), isTrue);
      expect(data2.contains('***'), isTrue);
    });
  });
}
