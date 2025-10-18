import 'dart:math';

/// Represents a single catalog exercise. For now this is a minimal model so we
/// can wire UI and state; data can be expanded once the Firestore catalog
/// lands.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    this.category = '',
    this.modality = '',
    this.tags = const [],
    this.isMainLift = false,
    this.defaultReps = 6,
    this.userDefaultReps = 6,
  });

  final String id;
  final String name;
  final String category;
  final String modality;
  final List<String> tags;
  final bool isMainLift;
  final int defaultReps;
  final int userDefaultReps;

  Exercise copyWith({
    String? id,
    String? name,
    String? category,
    String? modality,
    List<String>? tags,
    bool? isMainLift,
    int? defaultReps,
    int? userDefaultReps,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      modality: modality ?? this.modality,
      tags: tags ?? this.tags,
      isMainLift: isMainLift ?? this.isMainLift,
      defaultReps: defaultReps ?? this.defaultReps,
      userDefaultReps: userDefaultReps ?? this.userDefaultReps,
    );
  }
}

/// A single set entry for either the main lift or a support exercise.
class LiftSet {
  const LiftSet({required this.weightKg, required this.reps, this.rir});

  final double weightKg;
  final int reps;
  final int? rir;

  double get volumeKg => weightKg * reps;

  double get epleyEstimate {
    if (reps <= 0) return weightKg;
    return weightKg * (1 + reps / 30);
  }

  LiftSet copyWith({double? weightKg, int? reps, int? rir}) {
    return LiftSet(
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
    );
  }
}

/// Collection of support exercise sets.
class SupportExerciseEntry {
  const SupportExerciseEntry({required this.exercise, this.sets = const []});

  final Exercise exercise;
  final List<LiftSet> sets;

  double get volumeKg => sets.fold(0, (running, set) => running + set.volumeKg);

  SupportExerciseEntry copyWith({Exercise? exercise, List<LiftSet>? sets}) {
    return SupportExerciseEntry(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
    );
  }
}

/// A mutable draft of the session surface (main lift + supports).
class SessionDraft {
  const SessionDraft({
    this.mainLift,
    this.mainLiftSets = const [],
    this.supports = const [],
  });

  factory SessionDraft.empty() => const SessionDraft();

  final Exercise? mainLift;
  final List<LiftSet> mainLiftSets;
  final List<SupportExerciseEntry> supports;

  bool get hasMainLift => mainLift != null;

  double get mainLiftVolumeKg =>
      mainLiftSets.fold(0, (running, set) => running + set.volumeKg);

  double get supportVolumeKg =>
      supports.fold(0, (running, entry) => running + entry.volumeKg);

  double get totalVolumeKg => mainLiftVolumeKg + supportVolumeKg;

  double get estimated1RmKg {
    if (mainLiftSets.isEmpty) return 0;
    return mainLiftSets.fold<double>(
      0,
      (currentMax, set) => max(currentMax, set.epleyEstimate),
    );
  }

  SessionDraft copyWith({
    Exercise? mainLift,
    List<LiftSet>? mainLiftSets,
    List<SupportExerciseEntry>? supports,
  }) {
    return SessionDraft(
      mainLift: mainLift ?? this.mainLift,
      mainLiftSets: mainLiftSets ?? this.mainLiftSets,
      supports: supports ?? this.supports,
    );
  }
}
