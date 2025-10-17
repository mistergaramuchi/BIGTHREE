// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void _logWidgetTest(String message) {
  debugPrint('\n[Widget Test] $message');
}

void main() {
  testWidgets('shows onboarding screen on launch', (WidgetTester tester) async {
    _logWidgetTest('Launch renders onboarding screen with CTA');
    await tester.pumpWidget(const ProviderScope(child: LiftingApp()));

    expect(find.text('Welcome Coach'), findsOneWidget);
    expect(find.text('Jump into Logging'), findsOneWidget);
  });

  testWidgets('navigates through log, summary, and history screens', (
    WidgetTester tester,
  ) async {
    _logWidgetTest('Navigate sessions → log → summary → history flow');
    await tester.pumpWidget(const ProviderScope(child: LiftingApp()));

    await tester.tap(find.text('Jump into Logging'));
    await tester.pumpAndSettle();

    expect(find.text('Training Sessions'), findsOneWidget);
    expect(find.text('Dead Session'), findsOneWidget);

    await tester.tap(find.text('Dead Session'));
    await tester.pumpAndSettle();

    final startSessionButton = find
        .widgetWithText(FilledButton, 'Start Session')
        .first;
    await tester.ensureVisible(startSessionButton);
    final startSessionWidget = tester.widget<FilledButton>(startSessionButton);
    startSessionWidget.onPressed?.call();
    await tester.pumpAndSettle();

    expect(find.text('Support Exercises'), findsOneWidget);

    await tester.tap(find.text('Review Summary'));
    await tester.pumpAndSettle();
    expect(find.text('Session Summary'), findsOneWidget);

    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();
    expect(find.text('Training History'), findsOneWidget);
  });

  testWidgets('creates a new session template via dialog', (
    WidgetTester tester,
  ) async {
    _logWidgetTest('Create new session template from Sessions screen');
    await tester.pumpWidget(const ProviderScope(child: LiftingApp()));

    await tester.tap(find.text('Jump into Logging'));
    await tester.pumpAndSettle();

    expect(find.text('Create New Session'), findsOneWidget);

    await tester.tap(find.text('Create New Session'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'Custom Builder Session',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Custom Builder Session'), findsOneWidget);

    await tester.tap(find.text('Custom Builder Session'));
    await tester.pumpAndSettle();

    expect(find.text('No support exercises yet.'), findsWidgets);
  });
}
