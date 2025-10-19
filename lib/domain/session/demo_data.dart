import 'models.dart';

final _seedDate = DateTime.utc(2024, 1, 1);

final demoPrograms = <Program>[
  Program(
    id: 'program_5x5',
    name: 'StrongLifts 5×5',
    type: ProgramType.builtIn,
    isActive: true,
    createdAt: _seedDate,
    updatedAt: _seedDate,
  ),
  Program(
    id: 'program_ppl',
    name: 'Push / Pull / Legs',
    type: ProgramType.builtIn,
    createdAt: _seedDate,
    updatedAt: _seedDate,
  ),
  Program(
    id: 'program_nsuns',
    name: 'nSuns LP',
    type: ProgramType.builtIn,
    createdAt: _seedDate,
    updatedAt: _seedDate,
  ),
  Program(
    id: 'program_peak9',
    name: 'Peak-9',
    type: ProgramType.builtIn,
    createdAt: _seedDate,
    updatedAt: _seedDate,
  ),
  Program(
    id: 'program_quick',
    name: 'Quick Sessions',
    type: ProgramType.builtIn,
    createdAt: _seedDate,
    updatedAt: _seedDate,
  ),
];

const Exercise squatHighBar = Exercise(
  id: 'squat_high_bar',
  name: 'Back Squat (High-Bar)',
  category: 'Squat',
  modality: 'Barbell',
  tags: ['squat', 'barbell', 'compound'],
  isMainLift: true,
  defaultReps: 5,
  userDefaultReps: 5,
);

const Exercise squatLowBar = Exercise(
  id: 'squat_low_bar',
  name: 'Back Squat (Low-Bar)',
  category: 'Squat',
  modality: 'Barbell',
  tags: ['squat', 'barbell', 'compound'],
  isMainLift: true,
  defaultReps: 5,
  userDefaultReps: 5,
);

const Exercise frontSquat = Exercise(
  id: 'front_squat',
  name: 'Front Squat',
  category: 'Squat',
  modality: 'Barbell',
  tags: ['squat', 'barbell', 'compound'],
  isMainLift: true,
  defaultReps: 5,
  userDefaultReps: 5,
);

const Exercise benchCompetition = Exercise(
  id: 'bench_competition',
  name: 'Bench Press (Competition)',
  category: 'Bench',
  modality: 'Barbell',
  tags: ['bench', 'barbell', 'compound'],
  isMainLift: true,
  defaultReps: 5,
  userDefaultReps: 5,
);

const Exercise overheadPressStanding = Exercise(
  id: 'overhead_press',
  name: 'Overhead Press',
  category: 'Press',
  modality: 'Barbell',
  tags: ['press', 'barbell', 'compound'],
  isMainLift: true,
  defaultReps: 5,
  userDefaultReps: 5,
);

const Exercise deadliftConventional = Exercise(
  id: 'deadlift_conventional',
  name: 'Deadlift (Conventional)',
  category: 'Deadlift',
  modality: 'Barbell',
  tags: ['deadlift', 'barbell', 'compound'],
  isMainLift: true,
  defaultReps: 3,
  userDefaultReps: 3,
);

const Exercise barbellRow = Exercise(
  id: 'barbell_row',
  name: 'Barbell Row',
  category: 'Back',
  modality: 'Barbell',
  tags: ['row', 'back'],
  defaultReps: 8,
  userDefaultReps: 8,
);

const Exercise romanianDeadlift = Exercise(
  id: 'romanian_deadlift',
  name: 'Romanian Deadlift',
  category: 'Posterior Chain',
  modality: 'Barbell',
  tags: ['deadlift', 'hamstrings'],
  defaultReps: 10,
  userDefaultReps: 10,
);

const Exercise pullUp = Exercise(
  id: 'pull_up',
  name: 'Pull-Up',
  category: 'Back',
  modality: 'Bodyweight',
  tags: ['pull', 'bodyweight'],
  defaultReps: 8,
  userDefaultReps: 8,
);

const Exercise dumbbellBench = Exercise(
  id: 'dumbbell_bench',
  name: 'Dumbbell Bench Press',
  category: 'Bench',
  modality: 'Dumbbell',
  tags: ['bench', 'dumbbell'],
  defaultReps: 10,
  userDefaultReps: 10,
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

const Exercise lateralRaise = Exercise(
  id: 'lateral_raise',
  name: 'Dumbbell Lateral Raise',
  category: 'Shoulders',
  modality: 'Dumbbell',
  tags: ['shoulders', 'isolation'],
);

const Exercise seatedCableRow = Exercise(
  id: 'seated_cable_row',
  name: 'Seated Cable Row',
  category: 'Back',
  modality: 'Cable',
  tags: ['row', 'back'],
  defaultReps: 12,
  userDefaultReps: 12,
);

const Exercise latPulldown = Exercise(
  id: 'lat_pulldown',
  name: 'Lat Pulldown',
  category: 'Back',
  modality: 'Cable',
  tags: ['pulldown', 'back'],
  defaultReps: 12,
  userDefaultReps: 12,
);

const Exercise legCurl = Exercise(
  id: 'leg_curl',
  name: 'Leg Curl',
  category: 'Hamstrings',
  modality: 'Machine',
  tags: ['hamstrings', 'machine'],
  defaultReps: 12,
  userDefaultReps: 12,
);

const Exercise dumbbellShoulderPress = Exercise(
  id: 'dumbbell_shoulder_press',
  name: 'Dumbbell Shoulder Press',
  category: 'Shoulders',
  modality: 'Dumbbell',
  tags: ['shoulders', 'dumbbell'],
  defaultReps: 10,
  userDefaultReps: 10,
);

const Exercise tricepPushdown = Exercise(
  id: 'tricep_pushdown',
  name: 'Triceps Pushdown',
  category: 'Arms',
  modality: 'Cable',
  tags: ['arms', 'isolation'],
);

const Exercise hammerCurl = Exercise(
  id: 'hammer_curl',
  name: 'Hammer Curl',
  category: 'Arms',
  modality: 'Dumbbell',
  tags: ['biceps', 'forearms'],
  defaultReps: 12,
  userDefaultReps: 12,
);

const Exercise farmerCarry = Exercise(
  id: 'farmer_carry',
  name: 'Farmer Carry',
  category: 'Conditioning',
  modality: 'Dumbbell',
  tags: ['grip', 'conditioning'],
  defaultReps: 40,
  userDefaultReps: 40,
);

final demoSessionTemplates = <SessionTemplate>[
  // StrongLifts 5×5
  SessionTemplate(
    id: 'template_5x5_a',
    programId: 'program_5x5',
    name: 'Workout A',
    status: SessionStatus.active,
    exercises: const [
      squatLowBar,
      benchCompetition,
      barbellRow,
    ],
  ),
  SessionTemplate(
    id: 'template_5x5_b',
    programId: 'program_5x5',
    name: 'Workout B',
    status: SessionStatus.active,
    exercises: const [
      squatLowBar,
      overheadPressStanding,
      deadliftConventional,
    ],
  ),
  // Push / Pull / Legs
  SessionTemplate(
    id: 'template_ppl_push',
    programId: 'program_ppl',
    name: 'Push Day',
    status: SessionStatus.active,
    exercises: const [
      benchCompetition,
      inclineBench,
      dumbbellShoulderPress,
      tricepPushdown,
    ],
  ),
  SessionTemplate(
    id: 'template_ppl_pull',
    programId: 'program_ppl',
    name: 'Pull Day',
    status: SessionStatus.active,
    exercises: const [
      barbellRow,
      seatedCableRow,
      latPulldown,
      hammerCurl,
    ],
  ),
  SessionTemplate(
    id: 'template_ppl_legs',
    programId: 'program_ppl',
    name: 'Leg Day',
    status: SessionStatus.active,
    exercises: const [
      squatLowBar,
      legPress,
      romanianDeadlift,
      legCurl,
    ],
  ),
  // nSuns LP (Upper/Lower split)
  SessionTemplate(
    id: 'template_nsuns_upper',
    programId: 'program_nsuns',
    name: 'Upper Volume',
    status: SessionStatus.active,
    exercises: const [
      benchCompetition,
      overheadPressStanding,
      barbellRow,
      pullUp,
    ],
  ),
  SessionTemplate(
    id: 'template_nsuns_lower',
    programId: 'program_nsuns',
    name: 'Lower Volume',
    status: SessionStatus.active,
    exercises: const [
      squatHighBar,
      deadliftConventional,
      legPress,
      hipThrust,
    ],
  ),
  // Peak-9 (intensity / power / volume)
  SessionTemplate(
    id: 'template_peak9_intensity',
    programId: 'program_peak9',
    name: 'Intensity Day',
    status: SessionStatus.active,
    exercises: const [
      deadliftConventional,
      benchCompetition,
      barbellRow,
    ],
  ),
  SessionTemplate(
    id: 'template_peak9_power',
    programId: 'program_peak9',
    name: 'Power Day',
    status: SessionStatus.active,
    exercises: const [
      squatHighBar,
      overheadPressStanding,
      pullUp,
    ],
  ),
  SessionTemplate(
    id: 'template_peak9_volume',
    programId: 'program_peak9',
    name: 'Volume Day',
    status: SessionStatus.active,
    exercises: const [
      frontSquat,
      dumbbellBench,
      seatedCableRow,
      farmerCarry,
    ],
  ),
];

const demoMainLifts = [
  deadliftConventional,
  squatHighBar,
  squatLowBar,
  benchCompetition,
  overheadPressStanding,
];

const demoExerciseCatalog = [
  barbellRow,
  romanianDeadlift,
  pullUp,
  dumbbellBench,
  inclineBench,
  legPress,
  hipThrust,
  backExtension,
  lateralRaise,
  seatedCableRow,
  latPulldown,
  legCurl,
  dumbbellShoulderPress,
  tricepPushdown,
  hammerCurl,
  farmerCarry,
];
