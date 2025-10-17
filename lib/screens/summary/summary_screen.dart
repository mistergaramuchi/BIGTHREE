import 'package:flutter/material.dart';

import '../history/history_screen.dart';

class SummaryScreen extends StatelessWidget {
  static const routeName = '/summary';

  const SummaryScreen({super.key});

  void _viewHistory(BuildContext context) {
    Navigator.of(context).pushNamed(HistoryScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Summary'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimated 1RM', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: Text(
                  '— kg',
                  style: textTheme.headlineSmall,
                ),
                subtitle: const Text('Computed via Epley formula'),
              ),
            ),
            const SizedBox(height: 24),
            Text('Total Volume', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: Text(
                  '— kg',
                  style: textTheme.headlineSmall,
                ),
                subtitle: const Text('Main + support lifts'),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                // TODO(coach): trigger AI coach function.
              },
              child: const Text('Get Coach Feedback'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _viewHistory(context),
              child: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }
}
