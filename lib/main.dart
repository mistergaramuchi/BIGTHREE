import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/history/history_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/programs/programs_screen.dart';
import 'screens/summary/summary_screen.dart';

void main() {
  runApp(const ProviderScope(child: LiftingApp()));
}

class LiftingApp extends StatelessWidget {
  const LiftingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Project Phys',
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      routes: {
        OnboardingScreen.routeName: (_) => const OnboardingScreen(),
        ProgramsScreen.routeName: (_) => const ProgramsScreen(),
        SummaryScreen.routeName: (_) => const SummaryScreen(),
        HistoryScreen.routeName: (_) => const HistoryScreen(),
      },
      home: const OnboardingScreen(),
    );
  }
}
