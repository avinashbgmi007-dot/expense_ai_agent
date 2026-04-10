import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_ai_agent/models/transaction.dart';
import 'package:expense_ai_agent/providers/transaction_provider.dart';

class TransactionReviewScreen extends StatefulWidget {
  const TransactionReviewScreen({super.key});

  @override
  State<TransactionReviewScreen> createState() => _TransactionReviewScreenState();
}

class _TransactionReviewScreenState extends State<TransactionReviewScreen> {
  late List<TransactionModel> _editableTransactions;
  bool _isSaving = false;
  bool _hasChanges = false;

  final List<String> _categories = [
    'food',
    'transport',
    'utilities',
    'subscriptions',
    'shopping',
    'health',
    'education',
    'entertainment',
    'miscellaneous',
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<TransactionProvider>();
    _editableTransactions = List.from(provider.transactions);
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _updateMerchant(int index, String merchant) {
    setState(() {
      _editableTransactions[index] = _editableTransactions[index].copyWith(
        merchant: merchant,
      );
      _markChanged();
    });
  }

  void _updateCategory(int index, String category) {
    setState(() {
      _editableTransactions[index] = _editableTransactions[index].copyWith(
        category: category,
      );
      _markChanged();
    });
  }

  Future<void> _saveAllChanges() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = context.read<TransactionProvider>();
      
      for (final transaction in _editableTransactions) {
        await provider.updateTransaction(transaction);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All changes saved successfully')),
        );
        setState(() {
          _hasChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving changes: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Transactions'),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveAllChanges,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save All'),
            ),
        ],
      ),
      body: _editableTransactions.isEmpty
          ? const Center(
              child: Text('No transactions to review'),
            )
          : ListView.builder(
              itemCount: _editableTransactions.length,
              itemBuilder: (context, index) {
                final transaction = _editableTransactions[index];
                return _TransactionEditCard(
                  transaction: transaction,
                  categories: _categories,
                  onMerchantChanged: (value) => _updateMerchant(index, value),
                  onCategoryChanged: (value) => _updateCategory(index, value),
                );
              },
            ),
    );
  }
}

class _TransactionEditCard extends StatelessWidget {
  final TransactionModel transaction;
  final List<String> categories;
  final ValueChanged<String> onMerchantChanged;
  final ValueChanged<String> onCategoryChanged;

  const _TransactionEditCard({
    required this.transaction,
    required this.categories,
    required this.onMerchantChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction.formattedDateTime,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '₹${transaction.formattedAmount}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: transaction.credit ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: transaction.merchant ?? ''),
              decoration: const InputDecoration(
                labelText: 'Merchant',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: onMerchantChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: transaction.category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category[0].toUpperCase() + category.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onCategoryChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}