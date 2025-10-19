import 'dart:math';

enum SessionStatus { draft, active, done }

enum ProgramType { builtIn, user }

class Program {
  const Program({
    required this.id,
    required this.name,
    required this.type,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final ProgramType type;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Program copyWith({
    String? id,
    String? name,
    ProgramType? type,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Program(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

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

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final defaultReps = json['defaultReps'] as int? ?? 6;
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? '',
      modality: json['modality'] as String? ?? '',
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList() ??
          const [],
      isMainLift: json['isMainLift'] as bool? ?? false,
      defaultReps: defaultReps,
      userDefaultReps: json['userDefaultReps'] as int? ?? defaultReps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'modality': modality,
      'tags': tags,
      'isMainLift': isMainLift,
      'defaultReps': defaultReps,
      'userDefaultReps': userDefaultReps,
    };
  }
}

class SessionTemplate {
  SessionTemplate({
    required this.id,
    required this.programId,
    required this.name,
    required this.status,
    this.exercises = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String programId;
  final String name;
  final SessionStatus status;
  final List<Exercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  SessionTemplate copyWith({
    String? id,
    String? programId,
    String? name,
    SessionStatus? status,
    List<Exercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionTemplate(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      name: name ?? this.name,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TrainingSession {
  const TrainingSession({
    required this.id,
    this.programId,
    this.templateId,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? programId;
  final String? templateId;
  final String name;
  final SessionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainingSession copyWith({
    String? id,
    String? programId,
    String? templateId,
    String? name,
    SessionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LiftSet {
  const LiftSet({
    required this.weightKg,
    required this.reps,
    this.rir,
    this.isLogged = false,
  });

  final double weightKg;
  final int reps;
  final int? rir;
  final bool isLogged;

  double get volumeKg => weightKg * reps;

  double get epleyEstimate {
    if (reps <= 0) return weightKg;
    return weightKg * (1 + reps / 30);
  }

  LiftSet copyWith({double? weightKg, int? reps, int? rir, bool? isLogged}) {
    return LiftSet(
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      isLogged: isLogged ?? this.isLogged,
    );
  }
}

class SessionExerciseEntry {
  const SessionExerciseEntry({
    required this.exercise,
    this.sets = const [],
  });

  final Exercise exercise;
  final List<LiftSet> sets;

  int get currentSetIndex => sets.indexWhere((set) => !set.isLogged);

  LiftSet? get currentSet =>
      currentSetIndex == -1 ? null : sets[currentSetIndex];

  bool get isComplete => currentSetIndex == -1;

  double get loggedVolumeKg => sets.fold<double>(
    0,
    (running, set) => running + (set.isLogged ? set.volumeKg : 0),
  );

  SessionExerciseEntry copyWith({
    Exercise? exercise,
    List<LiftSet>? sets,
  }) {
    return SessionExerciseEntry(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
    );
  }
}

class SessionDraft {
  const SessionDraft({this.exercises = const []});

  factory SessionDraft.empty() => const SessionDraft();

  final List<SessionExerciseEntry> exercises;

  bool get hasExercises => exercises.isNotEmpty;

  SessionExerciseEntry? get primaryExercise =>
      exercises.isEmpty ? null : exercises.first;

  double get totalVolumeKg =>
      exercises.fold(0, (running, entry) => running + entry.loggedVolumeKg);

  double get estimated1RmKg {
    final primary = primaryExercise;
    if (primary == null) return 0;
    final loggedSets = primary.sets
        .where((set) => set.isLogged)
        .toList(growable: false);
    if (loggedSets.isEmpty) return 0;
    return loggedSets.fold<double>(
      0,
      (currentMax, set) => max(currentMax, set.epleyEstimate),
    );
  }

  SessionExerciseEntry? exerciseById(String exerciseId) {
    for (final entry in exercises) {
      if (entry.exercise.id == exerciseId) return entry;
    }
    return null;
  }

  SessionDraft copyWith({List<SessionExerciseEntry>? exercises}) {
    return SessionDraft(exercises: exercises ?? this.exercises);
  }
}
