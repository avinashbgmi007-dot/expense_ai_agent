import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/models/account.dart';
import 'package:expense_ai_agent/models/budget.dart';

class SQLiteDatabaseService {
  static final SQLiteDatabaseService _instance = SQLiteDatabaseService._internal();
  factory SQLiteDatabaseService() => _instance;
  SQLiteDatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'expense_ai_agent.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        accountId INTEGER,
        timestamp INTEGER NOT NULL,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'INR',
        description TEXT,
        credit INTEGER DEFAULT 0,
        merchant TEXT,
        paymentMethod TEXT,
        uploadId TEXT DEFAULT 'unknown',
        category TEXT DEFAULT 'miscellaneous',
        confidence REAL DEFAULT 1.0,
        isRecurring INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        isIgnored INTEGER DEFAULT 0,
        userNote TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        currency TEXT DEFAULT 'INR',
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        balance REAL DEFAULT 0.0,
        institution TEXT,
        accountNumberHash TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        accountId INTEGER NOT NULL,
        category TEXT NOT NULL,
        monthlyLimit REAL NOT NULL,
        periodStart TEXT NOT NULL,
        periodEnd TEXT NOT NULL,
        spentAmount REAL DEFAULT 0.0,
        alertThreshold REAL DEFAULT 0.8,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (accountId) REFERENCES accounts (id)
      )
    ''');
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert('transactions', {
      'accountId': null,
      'timestamp': transaction.timestamp,
      'amount': transaction.amount,
      'currency': transaction.currency,
      'description': transaction.description,
      'credit': transaction.credit ? 1 : 0,
      'merchant': transaction.merchant,
      'paymentMethod': transaction.paymentMethod,
      'uploadId': transaction.uploadId,
      'category': transaction.category,
      'confidence': transaction.confidence,
      'isRecurring': transaction.isRecurring ? 1 : 0,
      'createdAt': transaction.createdAt.millisecondsSinceEpoch,
      'isIgnored': transaction.isIgnored ? 1 : 0,
      'userNote': transaction.userNote,
    });
  }

  Future<List<TransactionModel>> getTransactions({
    int? accountId,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    
    final whereClause = <String>[];
    final whereArgs = <dynamic>[];

    if (accountId != null) {
      whereClause.add('accountId = ?');
      whereArgs.add(accountId);
    }

    if (category != null) {
      whereClause.add('category = ?');
      whereArgs.add(category);
    }

    if (startDate != null) {
      whereClause.add('timestamp >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause.add('timestamp <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause.add('(merchant LIKE ? OR description LIKE ?)');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    final results = await db.query(
      'transactions',
      where: whereClause.isNotEmpty ? whereClause.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => TransactionModel(
      id: map['id'].toString(),
      timestamp: map['timestamp'] as int,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'INR',
      description: map['description'] as String?,
      credit: (map['credit'] as int) == 1,
      merchant: map['merchant'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      uploadId: map['uploadId'] as String? ?? 'unknown',
      category: map['category'] as String? ?? 'miscellaneous',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      isRecurring: (map['isRecurring'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      isIgnored: (map['isIgnored'] as int?) == 1,
      userNote: map['userNote'] as String?,
    )).toList();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      {
        'accountId': null,
        'timestamp': transaction.timestamp,
        'amount': transaction.amount,
        'currency': transaction.currency,
        'description': transaction.description,
        'credit': transaction.credit ? 1 : 0,
        'merchant': transaction.merchant,
        'paymentMethod': transaction.paymentMethod,
        'uploadId': transaction.uploadId,
        'category': transaction.category,
        'confidence': transaction.confidence,
        'isRecurring': transaction.isRecurring ? 1 : 0,
        'isIgnored': transaction.isIgnored ? 1 : 0,
        'userNote': transaction.userNote,
      },
      where: 'id = ?',
      whereArgs: [int.parse(transaction.id)],
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertAccount(Account account) async {
    final db = await database;
    await db.insert('accounts', {
      'name': account.name,
      'type': account.type,
      'currency': account.currency,
      'isActive': account.isActive ? 1 : 0,
      'createdAt': account.createdAt.toIso8601String(),
      'balance': account.balance,
      'institution': account.institution,
      'accountNumberHash': account.accountNumberHash,
    });
  }

  Future<List<Account>> getAccounts({bool? isActive}) async {
    final db = await database;
    
    final results = await db.query(
      'accounts',
      where: isActive != null ? 'isActive = ?' : null,
      whereArgs: isActive != null ? [isActive ? 1 : 0] : null,
      orderBy: 'name ASC',
    );

    return results.map((map) => Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      currency: map['currency'] as String? ?? 'INR',
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      institution: map['institution'] as String?,
      accountNumberHash: map['accountNumberHash'] as String?,
    )).toList();
  }

  Future<Account?> getAccount(int id) async {
    final db = await database;
    final results = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    
    if (results.isEmpty) return null;
    
    final map = results.first;
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      currency: map['currency'] as String? ?? 'INR',
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      institution: map['institution'] as String?,
      accountNumberHash: map['accountNumberHash'] as String?,
    );
  }

  Future<void> updateAccount(Account account) async {
    final db = await database;
    await db.update(
      'accounts',
      {
        'name': account.name,
        'type': account.type,
        'currency': account.currency,
        'isActive': account.isActive ? 1 : 0,
        'balance': account.balance,
        'institution': account.institution,
        'accountNumberHash': account.accountNumberHash,
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteAccount(int id) async {
    final db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    return await db.insert('budgets', {
      'accountId': budget.accountId,
      'category': budget.category,
      'monthlyLimit': budget.monthlyLimit,
      'periodStart': budget.periodStart.toIso8601String(),
      'periodEnd': budget.periodEnd.toIso8601String(),
      'spentAmount': budget.spentAmount,
      'alertThreshold': budget.alertThreshold,
      'isActive': budget.isActive ? 1 : 0,
      'createdAt': budget.createdAt.toIso8601String(),
    });
  }

  Future<List<Budget>> getBudgets({int? accountId, bool? isActive}) async {
    final db = await database;
    
    final whereClause = <String>[];
    final whereArgs = <dynamic>[];

    if (accountId != null) {
      whereClause.add('accountId = ?');
      whereArgs.add(accountId);
    }

    if (isActive != null) {
      whereClause.add('isActive = ?');
      whereArgs.add(isActive ? 1 : 0);
    }

    final results = await db.query(
      'budgets',
      where: whereClause.isNotEmpty ? whereClause.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'category ASC',
    );

    return results.map((map) => Budget(
      id: map['id'] as int?,
      accountId: map['accountId'] as int,
      category: map['category'] as String,
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      periodStart: DateTime.parse(map['periodStart'] as String),
      periodEnd: DateTime.parse(map['periodEnd'] as String),
      spentAmount: (map['spentAmount'] as num?)?.toDouble() ?? 0.0,
      alertThreshold: (map['alertThreshold'] as num?)?.toDouble() ?? 0.8,
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    )).toList();
  }

  Future<Budget?> getBudget(int id) async {
    final db = await database;
    final results = await db.query('budgets', where: 'id = ?', whereArgs: [id]);
    
    if (results.isEmpty) return null;
    
    final map = results.first;
    return Budget(
      id: map['id'] as int?,
      accountId: map['accountId'] as int,
      category: map['category'] as String,
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      periodStart: DateTime.parse(map['periodStart'] as String),
      periodEnd: DateTime.parse(map['periodEnd'] as String),
      spentAmount: (map['spentAmount'] as num?)?.toDouble() ?? 0.0,
      alertThreshold: (map['alertThreshold'] as num?)?.toDouble() ?? 0.8,
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Future<void> updateBudget(Budget budget) async {
    final db = await database;
    await db.update(
      'budgets',
      {
        'accountId': budget.accountId,
        'category': budget.category,
        'monthlyLimit': budget.monthlyLimit,
        'periodStart': budget.periodStart.toIso8601String(),
        'periodEnd': budget.periodEnd.toIso8601String(),
        'spentAmount': budget.spentAmount,
        'alertThreshold': budget.alertThreshold,
        'isActive': budget.isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> deleteBudget(int id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}