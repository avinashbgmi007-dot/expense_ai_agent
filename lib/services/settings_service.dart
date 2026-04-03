import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app settings and preferences
class SettingsService {
  static const String _currencyKey = 'app_currency';
  static const String _languageKey = 'app_language';
  static const String _privacyAgreedKey = 'privacy_agreed';
  static const String _localAIEnabledKey = 'local_ai_enabled';

  late SharedPreferences _prefs;

  /// Initialize settings
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get current currency (default: INR)
  String getCurrency() {
    return _prefs.getString(_currencyKey) ?? 'INR';
  }

  /// Set currency
  Future<void> setCurrency(String currency) async {
    await _prefs.setString(_currencyKey, currency);
  }

  /// Get supported currencies
  List<String> getSupportedCurrencies() {
    return ['INR', 'USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD'];
  }

  /// Get currency symbol
  String getCurrencySymbol(String currency) {
    const symbols = {
      'INR': '₹',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'AUD': 'A\$',
      'CAD': 'C\$',
    };
    return symbols[currency] ?? currency;
  }

  /// Get language (default: en)
  String getLanguage() {
    return _prefs.getString(_languageKey) ?? 'en';
  }

  /// Set language
  Future<void> setLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
  }

  /// Get privacy agreement status
  bool hasAgreedToPrivacy() {
    return _prefs.getBool(_privacyAgreedKey) ?? false;
  }

  /// Set privacy agreement
  Future<void> setPrivacyAgreed(bool agreed) async {
    await _prefs.setBool(_privacyAgreedKey, agreed);
  }

  /// Check if local AI is enabled
  bool isLocalAIEnabled() {
    return _prefs.getBool(_localAIEnabledKey) ?? true;
  }

  /// Set local AI enabled status
  Future<void> setLocalAIEnabled(bool enabled) async {
    await _prefs.setBool(_localAIEnabledKey, enabled);
  }

  /// Clear all settings
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
