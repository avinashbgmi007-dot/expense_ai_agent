import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analytics_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
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
      appBar: AppBar(title: const Text('Analytics')),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                MonthlySummaryCard(provider: provider),
                TopMerchantsList(provider: provider),
                InsightsPanel(provider: provider),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MonthlySummaryCard extends StatelessWidget {
  final AnalyticsProvider provider;

  const MonthlySummaryCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final leaks = provider.getLeaks();
    final totalLeak =
        (leaks['subscriptions'] ?? 0.0) + (leaks['smallTransactions'] ?? 0.0);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Total Spending Leaks: ₹${totalLeak.toStringAsFixed(2)}'),
            Text('Recurring Subscriptions: ₹${leaks['subscriptions'] ?? 0}'),
            Text('Small Transactions: ₹${leaks['smallTransactions'] ?? 0}'),
          ],
        ),
      ),
    );
  }
}

class TopMerchantsList extends StatelessWidget {
  final AnalyticsProvider provider;

  const TopMerchantsList({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final merchants = provider.getTopMerchants();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Merchants',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...merchants.map(
              (m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m['name'] ?? 'Unknown'),
                    Text('₹${m['amount']?.toStringAsFixed(2) ?? "0.00"}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InsightsPanel extends StatelessWidget {
  final AnalyticsProvider provider;

  const InsightsPanel({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final insights = provider.getInsights();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Insights', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...insights.map(
              (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Text('• '),
                    Expanded(child: Text(i.toString())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
