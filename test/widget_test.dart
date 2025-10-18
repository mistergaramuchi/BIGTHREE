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

  testWidgets('navigates from overview into log, summary, and history', (
    WidgetTester tester,
  ) async {
    _logWidgetTest('Navigate sessions → overview → log → summary → history');
    await tester.pumpWidget(const ProviderScope(child: LiftingApp()));

    await tester.tap(find.text('Jump into Logging'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Session'), findsOneWidget);
    expect(find.text('Deadlift Session'), findsOneWidget);

    await tester.tap(find.text('Deadlift Session'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Overview'), findsOneWidget);
    expect(find.text('Deadlift (Conventional)'), findsOneWidget);

    final startSessionButton = find.widgetWithText(
      FloatingActionButton,
      'START SESSION',
    );
    await tester.tap(startSessionButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review Summary'));
    await tester.pumpAndSettle();
    expect(find.text('Session Summary'), findsOneWidget);

    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();
    expect(find.text('Training History'), findsOneWidget);
  });

  testWidgets('adds an exercise to the session overview', (
    WidgetTester tester,
  ) async {
    _logWidgetTest('Add exercise from quick catalog');
    await tester.pumpWidget(const ProviderScope(child: LiftingApp()));

    await tester.tap(find.text('Jump into Logging'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Other Session'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('+ Add an exercise'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Romanian Deadlift'));
    await tester.pumpAndSettle();

    expect(find.text('Romanian Deadlift'), findsOneWidget);
  });
}
