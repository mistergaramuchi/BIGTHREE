import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  static const routeName = '/history';

  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training History'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemBuilder: (context, index) {
          // Placeholder items until Firestore integration is wired.
          return ListTile(
            title: Text('Session ${index + 1}'),
            subtitle: const Text('Metrics coming soon…'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO(history): open session detail view.
            },
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: 3,
      ),
    );
  }
}
