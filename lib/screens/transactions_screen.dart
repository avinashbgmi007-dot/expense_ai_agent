import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../models/transaction.dart';
import '../utils/app_constants.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    var filtered = transactions;

    if (_selectedCategory != 'All') {
      filtered = filtered.where((t) => t.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        final merchant = (t.merchant ?? '').toLowerCase();
        final description = (t.description ?? '').toLowerCase();
        return merchant.contains(query) || description.contains(query);
      }).toList();
    }

    return filtered;
  }

  void _showManualEntryDialog() {
    final amountController = TextEditingController();
    final merchantController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'miscellaneous';
    String selectedPayment = 'Cash';
    bool isCredit = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Transaction',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('Expense'),
                                icon: Icon(Icons.arrow_downward, color: Colors.red),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('Income'),
                                icon: Icon(Icons.arrow_upward, color: Colors.green),
                              ),
                            ],
                            selected: {isCredit},
                            onSelectionChanged: (values) {
                              setSheetState(() => isCredit = values.first);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount (\u20B9)',
                        prefixText: '\u20B9 ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: merchantController,
                      decoration: const InputDecoration(labelText: 'Merchant'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description (optional)'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cat in ['food', 'transport', 'subscriptions', 'shopping', 'utilities', 'healthcare', 'entertainment', 'finance', 'miscellaneous'])
                          FilterChip(
                            label: Text(cat[0].toUpperCase() + cat.substring(1)),
                            selected: selectedCategory == cat,
                            onSelected: (_) {
                              setSheetState(() => selectedCategory = cat);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPayment,
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                        DropdownMenuItem(value: 'Card', child: Text('Card')),
                        DropdownMenuItem(value: 'Net Banking', child: Text('Net Banking')),
                        DropdownMenuItem(value: 'Wallet', child: Text('Wallet')),
                      ],
                      onChanged: (v) => setSheetState(() => selectedPayment = v!),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          final amount = double.tryParse(amountController.text.trim());
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          final merchant = merchantController.text.trim();
                          if (merchant.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a merchant name'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          final txn = TransactionModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            timestamp: DateTime.now().millisecondsSinceEpoch,
                            amount: amount,
                            currency: 'INR',
                            credit: isCredit,
                            merchant: merchant,
                            description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                            category: selectedCategory,
                            paymentMethod: selectedPayment,
                            uploadId: 'manual',
                          );

                          context.read<AnalyticsProvider>().addTransaction(txn);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('\u2705 Transaction added: \u20B9${amount.toStringAsFixed(2)} at $merchant'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Transaction'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showManualEntryDialog,
            tooltip: 'Add Transaction',
          ),
        ],
        bottom: _showSearch
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search merchant or description...',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: Icon(Icons.clear),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          Expanded(child: _buildTransactionList()),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'food', 'transport', 'subscriptions', 'shopping', 'utilities', 'healthcare', 'entertainment', 'finance', 'miscellaneous'];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final label = cat == 'All' ? 'All' : cat[0].toUpperCase() + cat.substring(1);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(label),
              selected: _selectedCategory == cat,
              onSelected: (_) => setState(() => _selectedCategory = cat),
              showCheckmark: false,
              selectedColor: AppTheme.primaryColor.withOpacity(0.12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionList() {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTransactions = provider.getSortedTransactions();
        final filtered = _filterTransactions(allTransactions);

        if (filtered.isEmpty && allTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text('No transactions yet', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Upload a bank statement or add manually', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        if (filtered.isEmpty) {
          return Center(
            child: Text('No matching transactions', style: Theme.of(context).textTheme.bodyLarge),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final txn = filtered[index];
            final categoryColor = AppTheme.categoryColors[txn.category] ?? AppTheme.categoryColors['miscellaneous']!;

            return Dismissible(
              key: Key(txn.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppTheme.dangerColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Transaction'),
                    content: Text('Delete \u20B9${txn.amount.toStringAsFixed(2)} at ${txn.merchant ?? 'Unknown'}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerColor),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) {
                provider.removeTransaction(txn.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Transaction deleted'),
                    backgroundColor: AppTheme.successColor,
                    action: SnackBarAction(label: 'Undo', onPressed: () {
                      provider.addTransaction(txn);
                    }),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.cardOutlineDecoration(),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _categoryIcon(txn.category),
                        color: categoryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            txn.merchant ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (txn.description != null && txn.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                txn.description!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  txn.category.isNotEmpty
                                      ? txn.category[0].toUpperCase() + txn.category.substring(1)
                                      : 'Miscellaneous',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: categoryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (txn.paymentMethod != null && txn.paymentMethod != 'Unknown')
                                Text(
                                  txn.paymentMethod!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              if (txn.paymentMethod != null && txn.paymentMethod != 'Unknown')
                                const SizedBox(width: 8),
                              Text(
                                _formatDate(txn.timestamp),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${txn.credit ? '+' : '-'}\u20B9${txn.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ).copyWith(
                        color: txn.credit ? AppTheme.successColor : AppTheme.dangerColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'food': return Icons.restaurant;
      case 'transport': return Icons.directions_car;
      case 'subscriptions': return Icons.autorenew;
      case 'shopping': return Icons.shopping_bag;
      case 'utilities': return Icons.bolt;
      case 'healthcare': return Icons.medical_services;
      case 'finance': return Icons.account_balance;
      case 'entertainment': return Icons.movie;
      case 'bills': return Icons.receipt_long;
      case 'mobile': return Icons.phone_android;
      case 'income': return Icons.south_west;
      case 'transfers': return Icons.swap_horiz;
      default: return Icons.category;
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }
}
