// lib/services/mode_manager.dart
import 'dart:async';
import 'package:expense_ai_agent/services/privacy_service.dart';
import 'package:expense_ai_agent/models/privacy_consent.dart';

// App mode enumeration
enum AppMode {
  offline,
  online,
}

// Mode manager for handling offline/online switching
class ModeManager {
  final PrivacyService _privacyService;
  AppMode _currentMode = AppMode.offline;
  final StreamController<AppMode> _modeController = StreamController<AppMode>.broadcast();

  ModeManager({required PrivacyService privacyService})
      : _privacyService = privacyService {
    _initializeMode();
  }

  // Current app mode
  AppMode get currentMode => _currentMode;

  // Stream of mode changes
  Stream<AppMode> get modeStream => _modeController.stream;

  // Initialize mode from stored settings
  Future<void> _initializeMode() async {
    try {
      final storedMode = await _privacyService.getSetting('app_mode');
      if (storedMode == 'online') {
        final consent = await _privacyService.getPrivacyConsent();
        if (consent?.consentGiven == true) {
          _currentMode = AppMode.online;
        }
      }
    } catch (e) {
      // Default to offline on error
      _currentMode = AppMode.offline;
    }
  }

  // Switch to online mode
  Future<void> switchToOnlineMode() async {
    // Check if consent is given
    final consent = await _privacyService.getPrivacyConsent();
    if (consent?.consentGiven != true) {
      throw Exception('Privacy consent required for online mode');
    }

    // Check if online features are enabled
    final onlineEnabled = await _privacyService.getSetting('privacy_consent_online');
    if (onlineEnabled != 'true') {
      throw Exception('Online features not enabled in privacy settings');
    }

    _currentMode = AppMode.online;
    await _privacyService.setSetting('app_mode', 'online', 'string');
    _modeController.add(_currentMode);
  }

  // Switch to offline mode
  Future<void> switchToOfflineMode() async {
    _currentMode = AppMode.offline;
    await _privacyService.setSetting('app_mode', 'offline', 'string');
    _modeController.add(_currentMode);
  }

  // Check if online mode can be enabled
  Future<bool> canSwitchToOnline() async {
    try {
      final consent = await _privacyService.getPrivacyConsent();
      final onlineEnabled = await _privacyService.getSetting('privacy_consent_online');
      return consent?.consentGiven == true && onlineEnabled == 'true';
    } catch (e) {
      return false;
    }
  }

  // Get current privacy consent
  Future<PrivacyConsent?> getPrivacyConsent() async {
    return await _privacyService.getPrivacyConsent();
  }

  // Update privacy consent
  Future<void> updatePrivacyConsent(PrivacyConsent consent) async {
    await _privacyService.savePrivacyConsent(consent);

    // If consent is revoked, switch to offline mode
    if (!consent.consentGiven && _currentMode == AppMode.online) {
      await switchToOfflineMode();
    }
  }

  // Check if online features are available
  bool get isOnlineMode => _currentMode == AppMode.online;

  // Get available features based on current mode
  List<String> getAvailableFeatures() {
    if (_currentMode == AppMode.offline) {
      return [
        'file_upload',
        'local_ai_categorization',
        'local_analytics',
        'local_storage',
        'basic_budgeting',
      ];
    } else {
      return [
        'file_upload',
        'local_ai_categorization',
        'enhanced_ai_categorization',
        'local_analytics',
        'cloud_analytics',
        'local_storage',
        'cloud_backup',
        'advanced_budgeting',
        'real_time_sync',
      ];
    }
  }

  // Dispose of resources
  void dispose() {
    _modeController.close();
  }
}