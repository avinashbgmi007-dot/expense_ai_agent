import 'dart:io';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';
import 'package:expense_ai_agent/services/analytics_provider.dart';
import 'package:expense_ai_agent/services/database_service.dart';
import 'package:expense_ai_agent/models/transaction.dart';

/// Comprehensive validation and debugging tool
/// Tests all components: PDF parsing, database, analytics, UI data flow
Future<void> main() async {
  print('🔍 COMPREHENSIVE DEBUG VALIDATION');
  print('===============================');
  print('Starting full system validation...');
  print('');

  // Test 1: PDF Parsing Deep Dive
  print('📄 TEST 1: PDF PARSING VALIDATION');
  print('-' * 50);

  final pdfParser = PDFParserService();
  final testFiles = [
    'C:\\Users\\Avinash-Pro\\Downloads\\HDFC-till 24.pdf',
    'C:\\Users\\Avinash-Pro\\Documents\\Union_Bank.pdf',
  ];

  for (final filePath in testFiles) {
    final file = File(filePath);
    if (await file.exists()) {
      print('🔹 Testing file: ${file.path.split('/').last}');
      try {
        final transactions = await pdfParser.parsePDF(file);
        print('  ✅ Transactions parsed: ${transactions.length}');

        if (transactions.isEmpty) {
          print('  ❌ CRITICAL: No transactions found - parsing failed!');
          print('     This indicates HDFC/Union parsing logic is broken');
          print('');
          continue;
        }

        // Validate transaction data quality
        int validCount = 0;
        int mismatchCount = 0;
        int missingMerchantCount = 0;
        int amountIssues = 0;

        for (var txn in transactions) {
          if (txn.amount <= 0) amountIssues++;
          if (txn.merchant == 'Unknown' || txn.merchant.isEmpty)
            missingMerchantCount++;
          if (txn.description.isNotEmpty &&
              !txn.description.contains(RegExp(r'\d{2}/\d{2}/\d{2}'))) {
            mismatchCount++;
          }
          if (txn.amount > 0 && txn.merchant != 'Unknown') validCount++;
        }

        print('  📊 Transaction Data Quality Analysis:');
        print('     - Valid transactions: $validCount/${transactions.length}');
        print('     - Missing merchants: $missingMerchantCount');
        print('     - Amount issues: $amountIssues');
        print('     - Format mismatches: $mismatchCount');
        print('');

        if (validCount < transactions.length * 0.9) {
          print('  ❌ WARNING: Data quality below 90% threshold!');
          print('     Needs significant logic improvement');
        } else {
          print('  ✅ Data quality acceptable');
        }
      } catch (e, stackTrace) {
        print('  ❌ EXCEPTION CAUGHT: $e');
        print('     Stack trace: $stackTrace');
      }
    } else {
      print('⚠️  File not found: $filePath');
    }
  }
  print('');

  // Test 2: Database Map Casting Validation
  print('💾 TEST 2: DATABASE MAP CASTING');
  print('-' * 50);

  final dbService = DatabaseService();
  try {
    await dbService.initialize();

    // Test transaction storage/retrieval
    final testTxn = TransactionModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      amount: 100.50,
      currency: 'INR',
      description: 'Test transaction for casting validation',
      credit: true,
      merchant: 'Test Merchant',
      paymentMethod: 'UPI',
      uploadId: 'debug_test',
      createdAt: DateTime.now(),
      category: 'test',
    );

    print('🔹 Testing database transaction round-trip...');
    await dbService.insertTransaction(testTxn);

    final retrieved = dbService.getTransactions();
    final found = retrieved.firstWhere(
      (t) => t.id == testTxn.id,
      orElse: () => TransactionModel.empty(),
    );

    if (found.id == 'empty') {
      print('  ❌ CRITICAL: Transaction not found after insert!');
      print('     Database save/retrieval completely broken');
    } else if (found.merchant != 'Test Merchant') {
      print('  ❌ CRITICAL: Data corruption detected!');
      print('     Expected: "Test Merchant"');
      print('     Got: "${found.merchant}"');
      print('     This proves Map<dynamic,dynamic> casting is still broken');
    } else {
      print('  ✅ Database round-trip successful');
      print('     Map casting appears fixed');
    }
    print('');
  } catch (e, stackTrace) {
    print('  ❌ EXCEPTION in database: $e');
    print('     $stackTrace');
  }
  print('');

  // Test 3: Analytics Provider Map Validation
  print('📊 TEST 3: ANALYTICS PROVIDER VALIDATION');
  print('-' * 50);

  final analytics = AnalyticsProvider();

  try {
    print('🔹 Testing analytics data structure...');

    // Create test data with problem maps
    final List<TransactionModel> testData = [
      TransactionModel(
        id: 'anal_test_1',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        amount: 500.0,
        currency: 'INR',
        description: 'Test analytics',
        credit: true,
        merchant: 'Analytics Test Merchant',
        paymentMethod: 'NEFT',
        uploadId: 'debug',
        createdAt: DateTime.now(),
      ),
    ];

    // Simulate loading with current data
    await analytics.loadData();

    final analyticsData = analytics.data;

    print('  🔍 Current analytics data structure:');
    print('     - totalSpend: ${analyticsData['totalSpend']}');
    print('     - transactionCount: ${analyticsData['transactionCount']}');
    print(
        '     - spendByMerchant type: ${analyticsData['spendByMerchant'].runtimeType}');
    print(
        '     - spendByCategory type: ${analyticsData['spendByCategory'].runtimeType}');
    print('     - leaks type: ${analyticsData['leaks'].runtimeType}');

    // Check for remaining Map casting issues
    bool hasMapIssues = false;
    if (analyticsData['spendByMerchant']
        .runtimeType
        .toString()
        .contains('_Map')) {
      print('  ❌ FOUND: _Map<dynamic,dynamic> in spendByMerchant!');
      hasMapIssues = true;
    }
    if (analyticsData['spendByCategory']
        .runtimeType
        .toString()
        .contains('_Map')) {
      print('  ❌ FOUND: _Map<dynamic,dynamic> in spendByCategory!');
      hasMapIssues = true;
    }
    if (analyticsData['leaks'].runtimeType.toString().contains('_Map')) {
      print('  ❌ FOUND: _Map<dynamic,dynamic> in leaks!');
      hasMapIssues = true;
    }

    if (hasMapIssues) {
      print('  ❌ CRITICAL: Map casting STILL NOT FIXED!');
      print('     UI will break when trying to display this data');
    } else {
      print('  ✅ No remaining _Map<dynamic,dynamic> issues found');
      print('     Map casting errors appear resolved');
    }
  } catch (e, stackTrace) {
    print('  ❌ EXCEPTION in analytics: $e');
    print('     $stackTrace');
  }
  print('');

  // Test 4: PDF Content Analysis for Diagnostic
  print('🔍 TEST 4: PDF CONTENT ANALYSIS');
  print('-' * 50);

  print('🔹 Reading actual PDF file content for pattern analysis...');
  for (final filePath in testFiles) {
    final file = File(filePath);
    if (await file.exists()) {
      try {
        final contents = await file.readAsBytes();
        final text = String.fromCharCodes(contents);

        print('📝 File content analysis: ${file.path.split('/').last}');
        print('  - Total characters: ${text.length}');
        print('  - Lines: ${text.split('\n').length}');
        print('');
        print('  🔎 Content sample (first 1000 chars):');
        print('  ' + '-' * 48);
        print('  ${text.substring(0, 1000).replaceAll('\n', '\\n')}');
        print('  ' + '-' * 48);
        print('');
        print('  🔍 Format detection patterns:');
        print(
            '    - HDFC format: ${text.contains('HDFC') || text.contains('Chq./Ref.No.') || text.contains(' statement') ? '✅ DETECTED' : '❌ NOT FOUND'}');
        print(
            '    - Union format: ${text.contains('UPIAR') || text.contains('UPIAB') || text.contains('UPOS') ? '✅ DETECTED' : '❌ NOT FOUND'}');
        print(
            '    - CAPGEMINI: ${text.contains('CAPGEMINI') ? '✅ FOUND' : '❌ NOT FOUND'}');
        print('');

        // Specific pattern analysis
        final datePatterns = [
          r'\d{2}/\d{2}/\d{2}',
          r'\d{2}-\d{2}-\d{4}',
        ];
        final amountPatterns = [
          r'[0-9,.]+\.?\d{0,2}\s+[Dd][Rr]',
          r'[0-9,.]+\.?\d{0,2}\s+[Cc][Rr]',
        ];

        print('  🔎 Pattern matches:');
        for (final pattern in datePatterns) {
          final matches = RegExp(pattern).allMatches(text);
          print('    - Date pattern $pattern: ${matches.length} matches');
        }
        for (final pattern in amountPatterns) {
          final matches = RegExp(pattern).allMatches(text);
          print('    - Amount pattern $pattern: ${matches.length} matches');
        }
      } catch (e) {
        print('  ❌ Error reading file: $e');
      }
    }
  }

  print('');
  print('📋 COMPREHENSIVE SOLUTION ROADMAP');
  print('===============================');
  print('Based on findings, here is the specific fix plan:');

  print('');
  print('🔧 STEP 1: FIX PDF PARSING');
  print('📌 If transactions are 0:');
  print('   • Fix _parseHDFCStatement() to handle compact single-line format');
  print(
      '   • Add specific CAPGEMINI recognition: "CR-SCBL.*CHaudhary" pattern');
  print('   • Ensure date extraction handles DD/MM/YY vs DD-MM-YYYY');
  print('');

  print('🔧 STEP 2: SIMPLE DEBUGGING');
  print('📌 Add comprehensive logging:');
  print('   final debugFile = File(\'parser_debug.log\');');
  print(
      '   debugFile.writeAsStringSync(\'Text sample:\\n${text.substring(0, 5000)}\\n\\n\');');
  print('   if (transactions.isEmpty) {');
  print(
      '     debugFile.writeAsStringSync(\'ERROR: No transactions\\n\', mode: append);');
  print(
      '     debugFile.writeAsStringSync(\'Full text length: ${text.length}\\n\', mode: append);');
  print('   }');
  print('');

  print('🔧 STEP 3: MANUAL VALIDATION');
  print('📌 Compare PDF vs App output side-by-side using:');
  print('   if (transactions.isNotEmpty) {');
  print(
      '     debugFile.writeAsStringSync(\'Transaction extraction validation:\\n\', mode: append);');
  print('     int lineNum = 0;');
  print('     for (var line in text.split(\'\\n\')) {');
  print('       if (line.contains(\'NEMA RAM\') ||');
  print('           line.contains(\'CAPGEMINI\') ||');
  print('           line.contains(\'115,929.00\')) {');
  print(
      '         debugFile.writeAsStringSync(\'Line $lineNum: $line\\n\', mode: append);');
  print('       }');
  print('       lineNum++;');
  print('     }');
  print(
      '     debugFile.writeAsStringSync(\'\\nExtracted transactions:\\n\', mode: append);');
  print('     for (var txn in transactions) {');
  print(
      '       debugFile.writeAsStringSync(\'${txn.merchant}: ₹${txn.amount}\\n\', mode: append);');
  print('     }');
  print('   }');
  print('');

  print('🔧 STEP 4: FIX SPECIFIC MAPPING');
  print('📌 CAPGEMINI salary parsing:');
  print('   if (text.contains(\'CAPGEMINI\') && text.contains(\'SALARY\')) {');
  print(
      '     final salaryMatch = RegExp(r\'(CR-\\S+).*CAPGEMINI.*SALARY.*(\\d{1,3}(,\\d{3})*(\\.\\d{2})?)\')');
  print('     if (salaryMatch.hasMatch(text)) {}');
  print('   }');
  print('');

  print('🔧 STEP 5: UI BROKEN DIAGNOSTIC');
  print('📌 Check for remaining UI issues:');
  print('   1. Test analytics_provider.dart with real PDF data');
  print('   2. Add null handling for: transactionCount as int ??');
  print('   3. Verify _safeCastMap() handles all map types correctly');
  print('');

  print('🎯 TARGET: 97.69% accuracy, 98.3% efficiency');
  print('✅ Send log files after running this debug tool');
  print('🔍 I will analyze actual patterns and provide precise regex fixes');
}
