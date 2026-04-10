import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../utils/app_constants.dart';

class LeaksScreen extends StatefulWidget {
  const LeaksScreen({super.key});

  @override
  State<LeaksScreen> createState() => _LeaksScreenState();
}

class _LeaksScreenState extends State<LeaksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spending Leaks',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          final leaks = provider.getLeaks();
          final subscriptions = leaks['subscriptions'] as List<dynamic>? ?? [];
          final smallTxns = leaks['smallTransactions'] as List<dynamic>? ?? [];
          final totalMonthly = (leaks['totalMonthly'] ?? 0.0).toDouble();
          final subMonthly = (leaks['subscriptionMonthly'] ?? 0.0).toDouble();
          final smallMonthly = (leaks['smallMonthly'] ?? 0.0).toDouble();
          final suggestions = leaks['suggestions'] as List<dynamic>? ?? [];

          return RefreshIndicator(
            onRefresh: provider.loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(context, totalMonthly, subMonthly, smallMonthly),
                const SizedBox(height: 16),

                if (subscriptions.isNotEmpty) ...[
                  _buildSubscriptionsCard(context, subscriptions),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildNoSubscriptionsCard(context),
                  const SizedBox(height: 16),
                ],

                if (smallMonthly > 0) ...[
                  _buildSmallTransactionsCard(context, smallTxns, smallMonthly),
                  const SizedBox(height: 16),
                ],

                if (suggestions.isNotEmpty) ...[
                  _buildSuggestionsCard(context, suggestions),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double total, double sub, double small) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE85D75), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40E85D75),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Monthly Leak Summary',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estimated potential waste per month',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryPill(
                  'Subscriptions',
                  '₹${sub.toStringAsFixed(0)}/mo',
                  Icons.autorenew,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryPill(
                  'Small Spends',
                  '₹${small.toStringAsFixed(0)} total',
                  Icons.receipt_long,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsCard(BuildContext context, List<dynamic> subscriptions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.autorenew, size: 20, color: AppTheme.secondaryColor),
              ),
              const SizedBox(width: 12),
              Text(
                'Recurring Subscriptions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Text(
                '${subscriptions.length} found',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...subscriptions.map((sub) => _subscriptionItem(context, sub)),
        ],
      ),
    );
  }

  Widget _subscriptionItem(BuildContext context, Map<String, dynamic> sub) {
    final category = sub['category'] as String? ?? 'miscellaneous';
    final color = AppTheme.categoryColors[category] ?? AppTheme.primaryColor;
    final frequency = sub['frequency'] as String? ?? 'unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _categoryIcon(category),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub['merchant'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        frequency[0].toUpperCase() + frequency.substring(1),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '₹${(sub['amount'] as num).toStringAsFixed(2)} × ${sub['occurrences']} times',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₹${(sub['monthlyEstimate'] as num).toStringAsFixed(0)}/mo',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle, color: AppTheme.successColor, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No recurring subscriptions detected',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Your spending doesn\'t show clear recurring patterns. Good job!',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTransactionsCard(BuildContext context, List<dynamic> smallTxns, double total) {
    // Group by category
    final byCategory = <String, List<dynamic>>{};
    for (final txn in smallTxns) {
      final cat = txn['category'] as String;
      byCategory.putIfAbsent(cat, () => []).add(txn);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up, size: 20, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Text(
                'Small Transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Text(
                '₹${total.toStringAsFixed(0)} total',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category breakdown
          for (final entry in byCategory.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.categoryColors[entry.key] ?? AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.key[0].toUpperCase() + entry.key.substring(1)} (${entry.value.length} txns)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Text(
                      entry.value.take(5).map((t) =>
                        '${t['merchant']} ₹${(t['amount'] as num).toStringAsFixed(0)}'
                      ).join('\n'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                        height: 1.6,
                      ),
                    ),
                  ),
                  if (entry.value.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(left: 18, top: 4),
                      child: Text(
                        '+${entry.value.length - 5} more',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard(BuildContext context, List<dynamic> suggestions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_outline, size: 20, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              const Text(
                'Suggestions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('\u2022  '),
                  Expanded(
                    child: Text(
                      s.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      default: return Icons.category;
    }
  }
}
