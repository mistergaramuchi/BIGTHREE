import 'models.dart';

class SessionTemplate {
  const SessionTemplate({
    required this.id,
    required this.name,
    required this.mainExercise,
    this.supportExercises = const [],
  });

  final String id;
  final String name;
  final Exercise mainExercise;
  final List<Exercise> supportExercises;

  SessionTemplate copyWith({
    String? id,
    String? name,
    Exercise? mainExercise,
    List<Exercise>? supportExercises,
  }) {
    return SessionTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      mainExercise: mainExercise ?? this.mainExercise,
      supportExercises: supportExercises ?? this.supportExercises,
    );
  }
}
