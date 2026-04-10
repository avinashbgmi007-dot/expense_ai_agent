import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_ai_agent/models/budget.dart';
import 'package:expense_ai_agent/providers/budget_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadBudgets();
    });
  }

  void _showAddBudgetDialog() {
    String selectedCategory = _categories.first;
    final limitController = TextEditingController();
    int? selectedAccountId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Budget'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category[0].toUpperCase() + category.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategory = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: limitController,
                decoration: const InputDecoration(
                  labelText: 'Monthly Limit',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final limit = double.tryParse(limitController.text);
              if (limit != null && limit > 0) {
                final now = DateTime.now();
                final budget = Budget(
                  accountId: selectedAccountId ?? 1,
                  category: selectedCategory,
                  monthlyLimit: limit,
                  periodStart: DateTime(now.year, now.month, 1),
                  periodEnd: DateTime(now.year, now.month + 1, 0),
                  createdAt: now,
                );
                context.read<BudgetProvider>().addBudget(budget);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBudgetDialog,
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 64),
                  const SizedBox(height: 16),
                  const Text('No budgets yet'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showAddBudgetDialog,
                    child: const Text('Add Budget'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildSummaryCard(provider),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.budgets.length,
                  itemBuilder: (context, index) {
                    final budget = provider.budgets[index];
                    return _BudgetCard(
                      budget: budget,
                      onEdit: () => _showEditBudgetDialog(budget),
                      onDelete: () => _confirmDelete(budget),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BudgetProvider provider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Budget'),
                Text(
                  '₹${provider.totalBudgeted.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Spent'),
                Text(
                  '₹${provider.totalSpent.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: provider.totalSpent > provider.totalBudgeted
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: provider.overallProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                provider.overallProgress > 1.0 ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(provider.overallProgress * 100).toStringAsFixed(1)}% used',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBudgetDialog(Budget budget) {
    final limitController = TextEditingController(
      text: budget.monthlyLimit.toString(),
    );
    String selectedCategory = budget.category;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Budget'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category[0].toUpperCase() + category.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategory = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: limitController,
                decoration: const InputDecoration(
                  labelText: 'Monthly Limit',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final limit = double.tryParse(limitController.text);
              if (limit != null && limit > 0) {
                final updatedBudget = budget.copyWith(
                  category: selectedCategory,
                  monthlyLimit: limit,
                );
                context.read<BudgetProvider>().updateBudget(updatedBudget);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete the ${budget.category} budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (budget.id != null) {
                context.read<BudgetProvider>().deleteBudget(budget.id!);
              }
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.budget,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = budget.spentPercentage.clamp(0.0, 1.0);
    final progressColor = budget.isOverBudget
        ? Colors.red
        : budget.shouldAlert
            ? Colors.orange
            : Colors.blue;

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
                  budget.category[0].toUpperCase() + budget.category.substring(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Spent: ₹${budget.spentAmount.toStringAsFixed(2)}'),
                Text('Limit: ₹${budget.monthlyLimit.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(budget.spentPercentage * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  budget.isOverBudget
                      ? 'Over budget!'
                      : 'Remaining: ₹${budget.remainingAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: budget.isOverBudget ? Colors.red : Colors.green,
                    fontWeight: budget.isOverBudget ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}