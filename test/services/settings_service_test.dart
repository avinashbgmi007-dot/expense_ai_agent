import 'package:test/test.dart';
import 'package:expense_ai_agent/services/settings_service.dart';

void main() {
  group('SettingsService', () {
    late SettingsService service;

    setUp(() {
      service = SettingsService();
    });

    test('should return supported currencies', () {
      final currencies = service.getSupportedCurrencies();

      expect(currencies, contains('INR'));
      expect(currencies, contains('USD'));
      expect(currencies, contains('EUR'));
      expect(currencies, contains('GBP'));
      expect(currencies.length, equals(7));
    });

    test('should get currency symbols correctly', () {
      expect(service.getCurrencySymbol('INR'), equals('₹'));
      expect(service.getCurrencySymbol('USD'), equals('\$'));
      expect(service.getCurrencySymbol('EUR'), equals('€'));
      expect(service.getCurrencySymbol('GBP'), equals('£'));
      expect(service.getCurrencySymbol('JPY'), equals('¥'));
    });

    test('should return currency for unsupported currency', () {
      final symbol = service.getCurrencySymbol('XYZ');
      expect(symbol, equals('XYZ'));
    });

    test('should have default currency as INR', () async {
      await service.initialize();
      final currency = service.getCurrency();
      expect(currency, equals('INR'));
    });

    test('should have default language as en', () async {
      await service.initialize();
      final language = service.getLanguage();
      expect(language, equals('en'));
    });

    test('should have local AI enabled by default', () async {
      await service.initialize();
      final enabled = service.isLocalAIEnabled();
      expect(enabled, isTrue);
    });

    test('should have privacy agreement false by default', () async {
      await service.initialize();
      final agreed = service.hasAgreedToPrivacy();
      expect(agreed, isFalse);
    });

    test('should update currency successfully', () async {
      await service.initialize();
      await service.setCurrency('USD');
      final currency = service.getCurrency();
      expect(currency, equals('USD'));
    });

    test('should update language successfully', () async {
      await service.initialize();
      await service.setLanguage('hi');
      final language = service.getLanguage();
      expect(language, equals('hi'));
    });

    test('should set privacy agreement', () async {
      await service.initialize();
      await service.setPrivacyAgreed(true);
      final agreed = service.hasAgreedToPrivacy();
      expect(agreed, isTrue);
    });

    test('should toggle local AI setting', () async {
      await service.initialize();
      await service.setLocalAIEnabled(false);
      var enabled = service.isLocalAIEnabled();
      expect(enabled, isFalse);

      await service.setLocalAIEnabled(true);
      enabled = service.isLocalAIEnabled();
      expect(enabled, isTrue);
    });
  });
}
