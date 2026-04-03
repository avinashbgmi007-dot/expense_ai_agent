import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';

class LeaksScreen extends StatefulWidget {
  const LeaksScreen({super.key});

  @override
  State<LeaksScreen> createState() => _LeaksScreenState();
}

class _LeaksScreenState extends State<LeaksScreen> {
  bool _showSubscriptions = true;

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
      appBar: AppBar(title: const Text('Spending Leaks')),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          final leaks = provider.getLeaks();
          final subscriptions = provider.getSubscriptions();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subscriptions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Switch(
                            value: _showSubscriptions,
                            onChanged: (value) {
                              setState(() => _showSubscriptions = value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_showSubscriptions) ...[
                        ...subscriptions.map(
                          (sub) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(sub['name'] ?? 'Unknown'),
                                Text(
                                  '₹${(sub['price'] ?? 0).toStringAsFixed(2)}/mo',
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Monthly Impact:'),
                              Chip(
                                label: Text(
                                  '₹${(leaks['subscriptions'] ?? 0).toStringAsFixed(2)}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Small Transactions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: ₹${(leaks['smallTransactions'] ?? 0).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
