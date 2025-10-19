import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';

final sessionDraftProvider =
    StateNotifierProvider<SessionDraftNotifier, SessionDraft>(
      (ref) => SessionDraftNotifier(),
    );

enum LogSetResult { success, missingExercise, noPendingSets, invalidValues }

class SessionDraftNotifier extends StateNotifier<SessionDraft> {
  SessionDraftNotifier() : super(SessionDraft.empty());

  void reset() {
    state = SessionDraft.empty();
  }

  void loadFromTemplate(SessionTemplate template) {
    if (template.exercises.isEmpty) {
      state = SessionDraft.empty();
      return;
    }

    final entries = template.exercises
        .map(
          (exercise) => SessionExerciseEntry(
            exercise: exercise,
            sets: _seedSetsFor(exercise),
          ),
        )
        .toList();

    state = SessionDraft(exercises: entries);
  }

  void updateExerciseSet(String exerciseId, int setIndex, LiftSet set) {
    final idx = _exerciseIndexFor(exerciseId);
    if (idx == -1) return;
    final entry = state.exercises[idx];
    if (setIndex < 0 || setIndex >= entry.sets.length) return;
    final sets = [...entry.sets];
    sets[setIndex] = set;
    final exercises = [...state.exercises];
    exercises[idx] = entry.copyWith(sets: sets);
    state = state.copyWith(exercises: exercises);
  }

  void updateExerciseDefaultReps(String exerciseId, int reps) {
    final idx = _exerciseIndexFor(exerciseId);
    if (idx == -1) return;
    final entry = state.exercises[idx];
    final exercises = [...state.exercises];
    exercises[idx] = entry.copyWith(
      exercise: entry.exercise.copyWith(userDefaultReps: reps),
    );
    state = state.copyWith(exercises: exercises);
  }

  void replaceExercise(String exerciseId, Exercise newExercise) {
    final idx = _exerciseIndexFor(exerciseId);
    if (idx == -1) return;
    final exercises = [...state.exercises];
    exercises[idx] = SessionExerciseEntry(
      exercise: newExercise,
      sets: _seedSetsFor(newExercise),
    );
    state = state.copyWith(exercises: exercises);
  }

  void addExerciseSet(String exerciseId) {
    final idx = _exerciseIndexFor(exerciseId);
    if (idx == -1) return;
    final entry = state.exercises[idx];
    final exercises = [...state.exercises];
    exercises[idx] = entry.copyWith(
      sets: [...entry.sets, _defaultSetFor(entry.exercise)],
    );
    state = state.copyWith(exercises: exercises);
  }

  void removeExerciseSet(String exerciseId, int setIndex) {
    final idx = _exerciseIndexFor(exerciseId);
    if (idx == -1) return;
    final entry = state.exercises[idx];
    if (setIndex < 0 || setIndex >= entry.sets.length) return;
    final updatedSets = [...entry.sets]..removeAt(setIndex);
    final exercises = [...state.exercises];
    exercises[idx] = entry.copyWith(sets: updatedSets);
    state = state.copyWith(exercises: exercises);
  }

  LogSetResult logNextSet(String exerciseId) {
    final idx = _exerciseIndexFor(exerciseId);
    if (idx == -1) return LogSetResult.missingExercise;
    final entry = state.exercises[idx];
    final nextIndex = entry.currentSetIndex;
    if (nextIndex == -1) return LogSetResult.noPendingSets;
    final candidate = entry.sets[nextIndex];
    final modality = entry.exercise.modality.toLowerCase();
    final requiresLoad = modality != 'bodyweight';

    if (candidate.reps <= 0) return LogSetResult.invalidValues;
    if (requiresLoad && candidate.weightKg <= 0) {
      return LogSetResult.invalidValues;
    }
    if (!requiresLoad && candidate.weightKg < 0) {
      return LogSetResult.invalidValues;
    }

    final updatedSets = [...entry.sets];
    updatedSets[nextIndex] = candidate.copyWith(isLogged: true);
    final exercises = [...state.exercises];
    exercises[idx] = entry.copyWith(sets: updatedSets);
    state = state.copyWith(exercises: exercises);
    return LogSetResult.success;
  }

  void markSetPending(String exerciseId, int setIndex) {
    final idx = _exerciseIndexFor(exerciseId);
    if (idx == -1) return;
    final entry = state.exercises[idx];
    if (setIndex < 0 || setIndex >= entry.sets.length) return;
    final sets = [...entry.sets];
    sets[setIndex] = sets[setIndex].copyWith(isLogged: false);
    final exercises = [...state.exercises];
    exercises[idx] = entry.copyWith(sets: sets);
    state = state.copyWith(exercises: exercises);
  }

  List<LiftSet> _seedSetsFor(Exercise exercise) {
    return List.generate(3, (_) => _defaultSetFor(exercise));
  }

  LiftSet _defaultSetFor(Exercise exercise) {
    return LiftSet(
      weightKg: _defaultWeightFor(exercise),
      reps: exercise.userDefaultReps,
      isLogged: false,
    );
  }

  double _defaultWeightFor(Exercise exercise) {
    final modality = exercise.modality.toLowerCase();
    if (modality == 'bodyweight') return 0;
    if (modality == 'barbell') return 20;
    if (modality == 'dumbbell') return 10;
    if (modality == 'machine') return 15;
    return exercise.isMainLift ? 20 : 10;
  }

  int _exerciseIndexFor(String exerciseId) {
    return state.exercises.indexWhere(
      (entry) => entry.exercise.id == exerciseId,
    );
  }
}
