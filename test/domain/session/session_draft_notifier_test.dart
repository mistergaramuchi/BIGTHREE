import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/domain/session/demo_data.dart';
import 'package:flutter_application_1/domain/session/models.dart';
import 'package:flutter_application_1/domain/session/session_draft_notifier.dart';

void _logTest(String message) {
  debugPrint('\n[Test] $message');
}

void main() {
  group('SessionDraftNotifier', () {
    late SessionDraftNotifier notifier;
    const squat = Exercise(
      id: 'squat_high_bar',
      name: 'Back Squat (High-Bar)',
      category: 'squat',
      modality: 'barbell',
      tags: ['squat', 'barbell', 'compound'],
      isMainLift: true,
    );
    const bench = Exercise(
      id: 'bench_comp',
      name: 'Competition Bench Press',
      category: 'bench',
      modality: 'barbell',
      tags: ['bench', 'barbell', 'compound'],
      isMainLift: true,
    );
    const row = Exercise(
      id: 'barbell_row',
      name: 'Barbell Row',
      category: 'back',
      modality: 'barbell',
      tags: ['row', 'back'],
    );

    setUp(() {
      notifier = SessionDraftNotifier();
    });

    test('loadFromTemplate seeds main lift and supports', () {
      _logTest('SessionDraftNotifier > loadFromTemplate seeds draft');
      final template = demoSessionTemplates.first;
      notifier.loadFromTemplate(template);

      expect(notifier.state.mainLift?.id, template.mainExercise.id);
      expect(notifier.state.supports.length, template.supportExercises.length);
      expect(notifier.state.mainLiftSets, isEmpty);
    });

    test('selecting a new main lift clears existing main lift sets', () {
      _logTest('SessionDraftNotifier > selecting a new main lift clears sets');
      notifier.setMainLift(squat);
      notifier.addMainLiftSet(const LiftSet(weightKg: 150, reps: 5, rir: 1));
      expect(notifier.state.mainLiftSets.length, 1);

      notifier.setMainLift(bench);
      expect(notifier.state.mainLift?.id, bench.id);
      expect(notifier.state.mainLiftSets, isEmpty);
    });

    test('computes e1RM and volume for main lift sets', () {
      _logTest('SessionDraftNotifier > computes e1RM and volume aggregates');
      notifier.setMainLift(squat);
      notifier
        ..addMainLiftSet(const LiftSet(weightKg: 150, reps: 5))
        ..addMainLiftSet(const LiftSet(weightKg: 160, reps: 3));

      expect(notifier.state.mainLiftVolumeKg, 1230);
      expect(notifier.state.estimated1RmKg, closeTo(176.0, 0.01));
    });

    test('manages support exercise sets and drops empty entries', () {
      _logTest('SessionDraftNotifier > manages support sets and pruning');
      notifier.setMainLift(squat);
      notifier.addMainLiftSet(const LiftSet(weightKg: 150, reps: 5));
      notifier.upsertSupportExercise(row);
      notifier.addSupportSet(row.id, const LiftSet(weightKg: 80, reps: 10));

      expect(notifier.state.supports.single.sets.length, 1);
      expect(notifier.state.supportVolumeKg, 800);

      notifier.updateSupportSet(
        row.id,
        0,
        const LiftSet(weightKg: 85, reps: 10),
      );
      expect(notifier.state.supportVolumeKg, 850);

      notifier.removeSupportSet(row.id, 0);
      expect(notifier.state.supports, isEmpty);
      expect(notifier.state.totalVolumeKg, 750);
    });

    test('removing support exercise without sets is a no-op', () {
      _logTest('SessionDraftNotifier > removing empty support is no-op');
      notifier.upsertSupportExercise(row);
      notifier.removeSupportExercise(row.id);
      expect(notifier.state.supports, isEmpty);
    });
  });
}
