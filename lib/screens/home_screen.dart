import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../services/file_upload_service.dart';
import '../services/csv_parser_service.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FileUploadService _fileUploadService = FileUploadService();
  final CSVParserService _csvParserService = CSVParserService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadData();
    });
  }

  Future<void> _handleFileUpload() async {
    try {
      setState(() => _isUploading = true);

      final file = await _fileUploadService.pickFile();
      if (file == null) {
        setState(() => _isUploading = false);
        return;
      }

      // Handle CSV parsing
      if (file.path.endsWith('.csv')) {
        final transactions = await _csvParserService.parseCSV(file);
        if (!mounted) return;

        if (transactions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No valid transactions found in CSV'),
            ),
          );
          if (mounted) setState(() => _isUploading = false);
          return;
        }

        // Initialize database and save each transaction
        await _databaseService.initialize();

        for (var transaction in transactions) {
          // Save to database
          await _databaseService.insertTransaction(transaction);
        }

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Successfully loaded ${transactions.length} transactions from CSV',
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Reload analytics with new data
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.read<AnalyticsProvider>().loadData();
        }
      } else if (file.path.endsWith('.pdf')) {
        // PDF Support: Better approach
        // Proper PDF text extraction requires external libraries
        // Recommended: Export PDF as CSV from your bank for 99%+ accuracy
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📋 PDF Note: Export bank statement as CSV for 99%+ extraction accuracy '
              'with AI categorization. CSV files are supported.',
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
        if (mounted) setState(() => _isUploading = false);
      }

      if (mounted) {
        setState(() => _isUploading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Expense AI Agent'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                '₹ INR',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            );
          }

          final totalSpend = provider.data['totalSpend'] as double? ?? 0.0;
          final txnCount = provider.data['transactionCount'] as int? ?? 0;

          // Convert maps from dynamic to proper types
          final spendByCategoryRaw =
              provider.data['spendByCategory'] as Map? ?? {};
          final spendByCategory = <String, double>{};
          spendByCategoryRaw.forEach((key, value) {
            spendByCategory[key.toString()] = (value is num)
                ? value.toDouble()
                : 0.0;
          });

          final spendByMerchantRaw =
              provider.data['spendByMerchant'] as Map? ?? {};
          final spendByMerchant = <String, double>{};
          spendByMerchantRaw.forEach((key, value) {
            spendByMerchant[key.toString()] = (value is num)
                ? value.toDouble()
                : 0.0;
          });

          final leaks = provider.data['leaks'] as Map<String, dynamic>? ?? {};
          final subscriptions =
              provider.data['subscriptions'] as List<dynamic>? ?? [];

          // Calculate empty state
          final isEmpty = txnCount == 0;

          return isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.upload_file,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No Transactions Yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tap the Upload button below to import your bank statement (CSV format)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Sample CSV Format:\nDate,Amount,Merchant,Description\n2024-01-15,500,Swiggy,Food Order',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header
                    Text(
                      '📊 Analytics Dashboard',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    // Total Spend Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Spend',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${totalSpend.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Transactions: $txnCount',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Spend by Category
                    if (spendByCategory.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📁 Spending by Category',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              ...spendByCategory.entries.map((entry) {
                                final percentage =
                                    (entry.value /
                                    (totalSpend > 0 ? totalSpend : 1) *
                                    100);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            entry.key.toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '₹${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percentage / 100,
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Top Merchants
                    if (spendByMerchant.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🏪 Top Merchants',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              ...spendByMerchant.entries
                                  .toList()
                                  .take(5)
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${entry.key + 1}. ${entry.value.key}',
                                          ),
                                          Text(
                                            '₹${entry.value.value.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Subscriptions & Leaks
                    if (subscriptions.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🔄 Recurring Charges (Subscriptions)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              for (
                                int i = 0;
                                i <
                                    (subscriptions.length > 5
                                        ? 5
                                        : subscriptions.length);
                                i++
                              )
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          subscriptions[i]['merchant'] ??
                                              'Unknown',
                                        ),
                                      ),
                                      Text(
                                        '₹${(subscriptions[i]['amount'] ?? 0).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Total Leaks Summary
                    if (leaks.isNotEmpty)
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⚠️ Potential Leaks Summary',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: Colors.orange.shade700),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Monthly Subscriptions:'),
                                  Text(
                                    '₹${(leaks['subscriptions'] ?? 0).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Small Transactions:'),
                                  Text(
                                    '₹${(leaks['smallTransactions'] ?? 0).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _handleFileUpload,
        icon: _isUploading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.upload_file),
        label: Text(_isUploading ? 'Uploading...' : 'Upload CSV/PDF'),
        tooltip: 'Upload bank statement or invoice (CSV/PDF)',
      ),
    );
  }
}
