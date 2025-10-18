import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'session_template.dart';

final sessionDraftProvider =
    StateNotifierProvider<SessionDraftNotifier, SessionDraft>(
      (ref) => SessionDraftNotifier(),
    );

class SessionDraftNotifier extends StateNotifier<SessionDraft> {
  SessionDraftNotifier() : super(SessionDraft.empty());

  void reset() {
    state = SessionDraft.empty();
  }

  void loadFromTemplate(SessionTemplate template) {
    state = SessionDraft(
      mainLift: template.mainExercise,
      mainLiftSets: _seedSetsFor(template.mainExercise),
      supports: template.supportExercises
          .map((e) => SupportExerciseEntry(exercise: e, sets: _seedSetsFor(e)))
          .toList(),
    );
  }

  void setMainLift(Exercise exercise) {
    final sameLift = state.mainLift?.id == exercise.id;
    state = state.copyWith(
      mainLift: exercise,
      mainLiftSets: sameLift && state.mainLiftSets.isNotEmpty
          ? state.mainLiftSets
          : _seedSetsFor(exercise),
    );
  }

  void clearMainLift() {
    state = state.copyWith(mainLift: null, mainLiftSets: <LiftSet>[]);
  }

  void addMainLiftSet(LiftSet set) {
    state = state.copyWith(mainLiftSets: [...state.mainLiftSets, set]);
  }

  void updateMainLiftSet(int index, LiftSet set) {
    if (index < 0 || index >= state.mainLiftSets.length) return;
    final updatedSets = [...state.mainLiftSets];
    updatedSets[index] = set;
    state = state.copyWith(mainLiftSets: updatedSets);
  }

  void removeMainLiftSet(int index) {
    if (index < 0 || index >= state.mainLiftSets.length) return;
    final updatedSets = [...state.mainLiftSets]..removeAt(index);
    state = state.copyWith(mainLiftSets: updatedSets);
  }

  void updateMainLiftDefaultReps(int reps) {
    final lift = state.mainLift;
    if (lift == null) return;
    state = state.copyWith(mainLift: lift.copyWith(userDefaultReps: reps));
  }

  void upsertSupportExercise(Exercise exercise) {
    final idx = _supportIndexFor(exercise.id);
    if (idx != -1) {
      final supports = [...state.supports];
      supports[idx] = supports[idx].copyWith(exercise: exercise);
      state = state.copyWith(supports: supports);
      return;
    }

    state = state.copyWith(
      supports: [
        ...state.supports,
        SupportExerciseEntry(exercise: exercise, sets: _seedSetsFor(exercise)),
      ],
    );
  }

  void removeSupportExercise(String exerciseId) {
    final idx = _supportIndexFor(exerciseId);
    if (idx == -1) return;
    final updatedSupports = [...state.supports]..removeAt(idx);
    state = state.copyWith(supports: updatedSupports);
  }

  void updateSupportDefaultReps(String exerciseId, int reps) {
    final idx = _supportIndexFor(exerciseId);
    if (idx == -1) return;
    final supports = [...state.supports];
    final entry = supports[idx];
    supports[idx] = entry.copyWith(
      exercise: entry.exercise.copyWith(userDefaultReps: reps),
    );
    state = state.copyWith(supports: supports);
  }

  void replaceSupportExercise(String exerciseId, Exercise newExercise) {
    final idx = _supportIndexFor(exerciseId);
    if (idx == -1) return;
    final supports = [...state.supports];
    supports[idx] = SupportExerciseEntry(
      exercise: newExercise,
      sets: _seedSetsFor(newExercise),
    );
    state = state.copyWith(supports: supports);
  }

  void addSupportSet(String exerciseId, LiftSet set) {
    final idx = _supportIndexFor(exerciseId);
    if (idx == -1) {
      throw ArgumentError(
        'Support exercise with id $exerciseId not found; call upsertSupportExercise first.',
      );
    }
    final supports = [...state.supports];
    final entry = supports[idx];
    supports[idx] = entry.copyWith(sets: [...entry.sets, set]);
    state = state.copyWith(supports: supports);
  }

  void updateSupportSet(String exerciseId, int setIndex, LiftSet set) {
    final idx = _supportIndexFor(exerciseId);
    if (idx == -1) return;
    final entry = state.supports[idx];
    if (setIndex < 0 || setIndex >= entry.sets.length) return;
    final sets = [...entry.sets];
    sets[setIndex] = set;
    final supports = [...state.supports];
    supports[idx] = entry.copyWith(sets: sets);
    state = state.copyWith(supports: supports);
  }

  void removeSupportSet(String exerciseId, int setIndex) {
    final idx = _supportIndexFor(exerciseId);
    if (idx == -1) return;
    final entry = state.supports[idx];
    if (setIndex < 0 || setIndex >= entry.sets.length) return;
    final sets = [...entry.sets]..removeAt(setIndex);

    final supports = [...state.supports];
    if (sets.isEmpty) {
      supports.removeAt(idx);
    } else {
      supports[idx] = entry.copyWith(sets: sets);
    }
    state = state.copyWith(supports: supports);
  }

  List<LiftSet> _seedSetsFor(Exercise exercise) {
    return List.generate(3, (_) => _defaultSetFor(exercise));
  }

  LiftSet _defaultSetFor(Exercise exercise) {
    return LiftSet(weightKg: 0, reps: exercise.userDefaultReps);
  }

  int _supportIndexFor(String exerciseId) {
    return state.supports.indexWhere(
      (entry) => entry.exercise.id == exerciseId,
    );
  }
}
