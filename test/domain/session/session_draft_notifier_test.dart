import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/domain/session/demo_data.dart';
import 'package:flutter_application_1/domain/session/models.dart';
import 'package:flutter_application_1/domain/session/session_draft_notifier.dart';

void main() {
  group('SessionDraftNotifier', () {
    late SessionDraftNotifier notifier;

    setUp(() {
      notifier = SessionDraftNotifier();
    });

    test('loadFromTemplate seeds exercises with primary first', () {
      final template = demoSessionTemplates.first;
      notifier.loadFromTemplate(template);

      final exercises = notifier.state.exercises;
      expect(exercises.length, template.exercises.length);
      expect(exercises.first.exercise.id, template.exercises.first.id);
      expect(exercises.first.sets.length, 3);
    });

    test('updateExerciseSet persists changes', () {
      notifier.loadFromTemplate(demoSessionTemplates.first);
      final primary = notifier.state.exercises.first;
      final mainId = primary.exercise.id;
      notifier.updateExerciseSet(
        mainId,
        1,
        primary.sets[1].copyWith(weightKg: 120, reps: 8),
      );

      final updated = notifier.state.exerciseById(mainId)!;
      expect(updated.sets[1].weightKg, 120);
      expect(updated.sets[1].reps, 8);
      expect(updated.sets[1].isLogged, isFalse);
    });

    test('logNextSet uses seeded defaults and updates aggregates', () {
      notifier.loadFromTemplate(demoSessionTemplates.first);
      final mainEntry = notifier.state.exercises.first;
      final mainId = mainEntry.exercise.id;

      final result = notifier.logNextSet(mainId);
      expect(result, LogSetResult.success);

      final updatedPrimary = notifier.state.exercises.first;
      expect(updatedPrimary.sets[0].isLogged, isTrue);
      expect(updatedPrimary.currentSetIndex, 1);
      expect(updatedPrimary.sets[0].weightKg, greaterThan(0));
      expect(notifier.state.totalVolumeKg, greaterThan(0));
      expect(notifier.state.estimated1RmKg, greaterThan(0));
    });

    test('replaceExercise swaps exercise and resets sets', () {
      notifier.loadFromTemplate(demoSessionTemplates.first);
      final primary = notifier.state.exercises.first;
      final replacement = demoExerciseCatalog.firstWhere(
        (exercise) => exercise.id != primary.exercise.id,
      );

      notifier.updateExerciseSet(
        primary.exercise.id,
        0,
        primary.sets[0].copyWith(weightKg: 100),
      );

      notifier.replaceExercise(primary.exercise.id, replacement);

      final updated = notifier.state.exercises.first;
      expect(updated.exercise.id, replacement.id);
      expect(updated.sets.first.weightKg, isNot(100));
      expect(
        updated.sets.every((set) => set.reps == replacement.userDefaultReps),
        isTrue,
      );
      expect(updated.sets.every((set) => set.weightKg >= 0), isTrue);
      expect(updated.sets.every((set) => set.isLogged == false), isTrue);
    });

    test('addExerciseSet appends a pending set with defaults', () {
      notifier.loadFromTemplate(demoSessionTemplates.first);
      final mainEntry = notifier.state.exercises.first;
      final mainId = mainEntry.exercise.id;
      notifier.addExerciseSet(mainId);

      final updated = notifier.state.exerciseById(mainId)!;
      expect(updated.sets.length, mainEntry.sets.length + 1);
      final newSet = updated.sets.last;
      expect(newSet.isLogged, isFalse);
      expect(newSet.reps, mainEntry.exercise.userDefaultReps);
    });

    test('removeExerciseSet drops the target set', () {
      notifier.loadFromTemplate(demoSessionTemplates.first);
      final mainEntry = notifier.state.exercises.first;
      final mainId = mainEntry.exercise.id;
      notifier.removeExerciseSet(mainId, 1);

      final updated = notifier.state.exerciseById(mainId)!;
      expect(updated.sets.length, mainEntry.sets.length - 1);
    });

    test('updates user default reps when requested', () {
      notifier.loadFromTemplate(demoSessionTemplates.first);
      final exercises = notifier.state.exercises;
      final primaryId = exercises.first.exercise.id;
      notifier.updateExerciseDefaultReps(primaryId, 8);
      expect(notifier.state.exercises.first.exercise.userDefaultReps, 8);

      final accessory = exercises[1];
      notifier.updateExerciseDefaultReps(accessory.exercise.id, 12);
      expect(
        notifier.state
            .exerciseById(accessory.exercise.id)
            ?.exercise
            .userDefaultReps,
        12,
      );
    });
  });
}
