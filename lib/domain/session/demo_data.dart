import 'models.dart';
import 'session_template.dart';

const Exercise squatHighBar = Exercise(
  id: 'squat_high_bar',
  name: 'Back Squat (High-Bar)',
  category: 'Squat',
  modality: 'Barbell',
  tags: ['squat', 'barbell', 'compound'],
  isMainLift: true,
);

const Exercise squatLowBar = Exercise(
  id: 'squat_low_bar',
  name: 'Back Squat (Low-Bar)',
  category: 'Squat',
  modality: 'Barbell',
  tags: ['squat', 'barbell', 'compound'],
  isMainLift: true,
);

const Exercise benchCompetition = Exercise(
  id: 'bench_competition',
  name: 'Bench Press (Competition)',
  category: 'Bench',
  modality: 'Barbell',
  tags: ['bench', 'barbell', 'compound'],
  isMainLift: true,
);

const Exercise deadliftConventional = Exercise(
  id: 'deadlift_conventional',
  name: 'Deadlift (Conventional)',
  category: 'Deadlift',
  modality: 'Barbell',
  tags: ['deadlift', 'barbell', 'compound'],
  isMainLift: true,
);

const Exercise barbellRow = Exercise(
  id: 'barbell_row',
  name: 'Barbell Row',
  category: 'Back',
  modality: 'Barbell',
  tags: ['row', 'back'],
);

const Exercise romanianDeadlift = Exercise(
  id: 'romanian_deadlift',
  name: 'Romanian Deadlift',
  category: 'Posterior Chain',
  modality: 'Barbell',
  tags: ['deadlift', 'hamstrings'],
);

const Exercise pullUp = Exercise(
  id: 'pull_up',
  name: 'Pull-Up',
  category: 'Back',
  modality: 'Bodyweight',
  tags: ['pull', 'bodyweight'],
);

const Exercise dumbbellBench = Exercise(
  id: 'dumbbell_bench',
  name: 'Dumbbell Bench Press',
  category: 'Bench',
  modality: 'Dumbbell',
  tags: ['bench', 'dumbbell'],
);

const Exercise inclineBench = Exercise(
  id: 'incline_bench',
  name: 'Incline Bench Press',
  category: 'Bench',
  modality: 'Barbell',
  tags: ['bench', 'incline'],
);

const Exercise legPress = Exercise(
  id: 'leg_press',
  name: 'Leg Press',
  category: 'Squat Assistance',
  modality: 'Machine',
  tags: ['legs', 'machine'],
);

const Exercise walkingLunge = Exercise(
  id: 'walking_lunge',
  name: 'Walking Lunge',
  category: 'Squat Assistance',
  modality: 'Dumbbell',
  tags: ['legs', 'single_leg'],
);

const Exercise hipThrust = Exercise(
  id: 'hip_thrust',
  name: 'Barbell Hip Thrust',
  category: 'Posterior Chain',
  modality: 'Barbell',
  tags: ['glutes', 'posterior_chain'],
);

const Exercise backExtension = Exercise(
  id: 'back_extension',
  name: 'Back Extension',
  category: 'Posterior Chain',
  modality: 'Bodyweight',
  tags: ['posterior_chain'],
);

const Exercise tricepPushdown = Exercise(
  id: 'tricep_pushdown',
  name: 'Triceps Pushdown',
  category: 'Arms',
  modality: 'Cable',
  tags: ['arms', 'isolation'],
);

const Exercise lateralRaise = Exercise(
  id: 'lateral_raise',
  name: 'Dumbbell Lateral Raise',
  category: 'Shoulders',
  modality: 'Dumbbell',
  tags: ['shoulders', 'isolation'],
);

const List<Exercise> demoSupportExercises = [
  barbellRow,
  romanianDeadlift,
  pullUp,
  dumbbellBench,
  inclineBench,
  legPress,
  walkingLunge,
  hipThrust,
  backExtension,
  tricepPushdown,
  lateralRaise,
];

const demoSessionTemplates = [
  SessionTemplate(
    id: 'session_deadlift',
    name: 'Dead Session',
    mainExercise: deadliftConventional,
    supportExercises: [hipThrust, barbellRow, backExtension],
  ),
  SessionTemplate(
    id: 'session_squat',
    name: 'Squat Session',
    mainExercise: squatLowBar,
    supportExercises: [legPress, walkingLunge, romanianDeadlift],
  ),
  SessionTemplate(
    id: 'session_bench',
    name: 'Bench Session',
    mainExercise: benchCompetition,
    supportExercises: [
      inclineBench,
      dumbbellBench,
      tricepPushdown,
      lateralRaise,
    ],
  ),
];

const demoMainLifts = [
  deadliftConventional,
  squatHighBar,
  squatLowBar,
  benchCompetition,
];
