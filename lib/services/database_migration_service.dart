import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/models/account.dart';

// lib/services/database_migration_service.dart
class DatabaseMigrationService {
  static const String _migrationKey = 'migration_completed';
  static const String _backupKey = 'migration_backup';

  final Database database;

  DatabaseMigrationService(this.database);

  /// Migrates data from SharedPreferences to SQLite
  Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if migration already completed
    if (prefs.getBool(_migrationKey) == true) {
      return;
    }

    try {
      // Create backup of existing data
      await _createBackup(prefs);

      // Get existing transaction data
      final transactionKeys =
          prefs.getKeys().where((key) => key.startsWith('transaction_'));

      for (final key in transactionKeys) {
        final transactionData = prefs.getString(key);
        if (transactionData != null) {
          await _migrateTransaction(transactionData);
        }
      }

      // Create default account if no transactions exist
      final transactionCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM transactions'),
      );

      if (transactionCount == 0) {
        await _createDefaultAccount();
      }

      // Mark migration as completed
      await prefs.setBool(_migrationKey, true);
    } catch (e) {
      // Rollback on error
      await rollbackMigration();
      rethrow;
    }
  }

  /// Creates a backup of existing SharedPreferences data
  Future<void> _createBackup(SharedPreferences prefs) async {
    final allData = <String, dynamic>{};

    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      if (value != null) {
        allData[key] = value;
      }
    }

    final backupJson = jsonEncode(allData);
    await prefs.setString(_backupKey, backupJson);
  }

  /// Migrates a single transaction from JSON string to SQLite
  Future<void> _migrateTransaction(String transactionJson) async {
    try {
      final jsonData = jsonDecode(transactionJson);

      // Convert old TransactionModel format to new Transaction format
      final transaction = Transaction(
        accountId: 1, // Default account
        uploadId: jsonData['uploadId'] ?? 'migrated',
        date: jsonData['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(jsonData['createdAt'])
            : DateTime.now(),
        amount: (jsonData['amount'] as num?)?.toDouble() ?? 0.0,
        merchant: jsonData['merchant'],
        description: jsonData['description'],
        category: jsonData['category'] ?? 'miscellaneous',
        isRecurring: jsonData['isRecurring'] ?? false,
        tags: [],
        createdAt: jsonData['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(jsonData['createdAt'])
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await database.insert('transactions', transaction.toJson());
    } catch (e) {
      // Log error but continue with other transactions
      print('Error migrating transaction: $e');
    }
  }

  /// Creates a default account for migrated transactions
  Future<void> _createDefaultAccount() async {
    final defaultAccount = Account(
      name: 'Default Account',
      type: 'bank',
      currency: 'INR',
      isActive: true,
      createdAt: DateTime.now(),
      balance: 0.0,
    );

    await database.insert('accounts', defaultAccount.toJson());
  }

  /// Validates that migration was successful
  Future<bool> validateMigrationIntegrity() async {
    try {
      // Check that tables exist and have data
      final transactionCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM transactions'),
      );

      final accountCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM accounts'),
      );

      // Basic integrity checks
      return transactionCount != null &&
          accountCount != null &&
          accountCount > 0;
    } catch (e) {
      return false;
    }
  }

  /// Checks if a backup exists
  Future<bool> backupExists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_backupKey);
  }

  /// Rolls back migration by restoring from backup
  Future<void> rollbackMigration() async {
    final prefs = await SharedPreferences.getInstance();

    if (!await backupExists()) {
      throw Exception('No backup available for rollback');
    }

    try {
      // Clear current SQLite data
      await database.delete('transactions');
      await database.delete('accounts');

      // Restore from backup
      final backupJson = prefs.getString(_backupKey);
      if (backupJson != null) {
        final rawBackup = jsonDecode(backupJson);
        // Safe cast: JSON decode can return Map<dynamic,dynamic>
        if (rawBackup is! Map<String, dynamic>) {
          throw Exception('Invalid backup format');
        }
        final backupData = rawBackup;

        for (final entry in backupData.entries) {
          if (entry.key.startsWith('transaction_')) {
            await prefs.setString(entry.key, entry.value as String);
          }
        }
      }

      // Remove migration flag
      await prefs.remove(_migrationKey);
    } catch (e) {
      throw Exception('Rollback failed: $e');
    }
  }

  /// Cleans up backup data after successful migration
  Future<void> cleanupBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backupKey);
  }

  /// Gets migration status
  Future<MigrationStatus> getMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final isCompleted = prefs.getBool(_migrationKey) == true;
    final hasBackup = await backupExists();

    return MigrationStatus(
      isCompleted: isCompleted,
      hasBackup: hasBackup,
      canRollback: hasBackup && !isCompleted,
    );
  }
}

/// Migration status information
class MigrationStatus {
  final bool isCompleted;
  final bool hasBackup;
  final bool canRollback;

  const MigrationStatus({
    required this.isCompleted,
    required this.hasBackup,
    required this.canRollback,
  });

  @override
  String toString() {
    return 'MigrationStatus(completed: $isCompleted, backup: $hasBackup, canRollback: $canRollback)';
  }
}
