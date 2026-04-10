import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/settings_service.dart';
import '../services/privacy_service.dart';
import '../utils/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final PrivacyService _privacyService = PrivacyService();
  bool _aiEnabled = true;
  String _currency = 'INR';

  bool _privacyInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsService.initialize();
    await _privacyService.initialize();
    setState(() {
      _currency = _settingsService.getCurrency();
      _aiEnabled = _settingsService.isLocalAIEnabled();
      _privacyInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        children: [
          _buildSection(
            'Appearance',
            [
              _buildSwitchTile(
                icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark themes',
                value: themeProvider.isDarkMode,
                onChanged: (v) async {
                  themeProvider.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(v ? 'Dark mode enabled' : 'Light mode enabled'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSection(
            'Preferences',
            [
              _buildDropdownTile(
                icon: Icons.currency_exchange,
                title: 'Currency',
                subtitle: _currency,
                value: _currency,
                items: _settingsService.getSupportedCurrencies(),
                onChanged: (v) async {
                  if (v != null) {
                    await _settingsService.setCurrency(v);
                    setState(() => _currency = v);
                  }
                },
              ),
              _buildSwitchTile(
                icon: Icons.psychology,
                title: 'AI Categorization',
                subtitle: 'Use local AI for transaction categorization',
                value: _aiEnabled,
                onChanged: (v) async {
                  await _settingsService.setLocalAIEnabled(v);
                  setState(() => _aiEnabled = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSection(
            'Privacy & Security',
            [
              _buildInfoTile(
                icon: Icons.shield_outlined,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy commitment',
                onTap: () => _showPrivacyPolicy(context),
              ),
              _buildInfoTile(
                icon: Icons.data_usage_outlined,
                title: 'Data Minimization',
                subtitle: 'What we collect and why',
                onTap: () => _showDataGuidelines(context),
              ),
              ListTile(
                leading: Icon(
                  _privacyInitialized && _privacyService.verifyPrivacyCompliance()
                      ? Icons.check_circle
                      : Icons.warning,
                  color: _privacyInitialized && _privacyService.verifyPrivacyCompliance()
                      ? AppTheme.successColor
                      : AppTheme.dangerColor,
                ),
                title: const Text('Privacy Compliance'),
                subtitle: Text(
                  _privacyInitialized && _privacyService.verifyPrivacyCompliance()
                      ? 'All checks passed'
                      : 'Initializing...',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSection(
            'Data Management',
            [
              _buildDangerTile(
                icon: Icons.delete_forever,
                title: 'Clear All Data',
                subtitle: 'Permanently delete all transactions and settings',
                onTap: () => _confirmClearData(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSection(
            'About',
            [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0+1'),
              ),
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Data Storage'),
                subtitle: const Text('All data stored locally on your device'),
              ),
              ListTile(
                leading: const Icon(Icons.offline_bolt_outlined),
                title: const Text('Offline Capable'),
                subtitle: const Text('Works without internet connection'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: items.contains(value) ? value : null,
        underline: const SizedBox(),
        items: items
            .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c == 'INR'
                        ? '\u20B9 INR'
                        : c == 'USD'
                            ? '\$ USD'
                            : c == 'EUR'
                                ? '\u20AC EUR'
                                : c == 'GBP'
                                    ? '\u00A3 GBP'
                                    : c,
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: AppTheme.dangerColor),
      title: Text(title, style: const TextStyle(color: AppTheme.dangerColor)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.dangerColor),
      onTap: onTap,
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(_privacyService.getPrivacyPolicy()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDataGuidelines(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Minimization'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _privacyService
                .getDataMinimizationGuidelines()
                .map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('\u2022 $s'),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppTheme.dangerColor, size: 48),
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete ALL your transactions, settings, and cached data. '
          'This action CANNOT be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await _settingsService.clearAll();
              await _loadSettings();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('All data cleared successfully'),
                  backgroundColor: AppTheme.dangerColor,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}
