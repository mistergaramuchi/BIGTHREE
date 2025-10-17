import 'package:flutter/material.dart';

import '../sessions/sessions_screen.dart';

class OnboardingScreen extends StatelessWidget {
  static const routeName = '/onboarding';

  const OnboardingScreen({super.key});

  void _startSession(BuildContext context) {
    Navigator.of(context).pushNamed(SessionsScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Coach'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Let’s get your lifter profile dialed in.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'We’ll capture goals, experience, weekly cadence, constraints, and primary focus so the AI coach can tailor your sessions.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => _startSession(context),
              child: const Text('Jump into Logging'),
            ),
          ],
        ),
      ),
    );
  }
}
