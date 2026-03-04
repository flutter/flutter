import '../models/coach_message.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../models/workout_stats.dart';

const UserProfile mockUserProfile = UserProfile(
  name: 'Lasse',
  age: 29,
  heightCm: 182,
  weightKg: 83.5,
  goal: 'Muskelopbygning',
  experience: 'Øvet',
);

const Workout mockTodayWorkout = Workout(
  title: 'Overkrop Power',
  focus: 'Bryst & ryg',
  durationMinutes: 48,
  exercises: <String>[
    'Incline Dumbbell Press',
    'Chest-Supported Row',
    'Lateral Raise',
    'Triceps Pushdown',
  ],
  scheduledLabel: 'I dag',
);

const Workout mockNextWorkout = Workout(
  title: 'Ben & core',
  focus: 'Ben',
  durationMinutes: 42,
  exercises: <String>[
    'Back Squat',
    'Romanian Deadlift',
    'Split Squat',
    'Plank',
  ],
  scheduledLabel: 'I morgen kl. 17:30',
);

const List<String> mockRecentExercises = <String>[
  'Bænkpres',
  'Lat Pulldown',
  'Bulgarian Split Squat',
  'Seated Cable Row',
];

const WorkoutStats mockStats = WorkoutStats(
  weeklySessions: 4,
  totalMinutesThisWeek: 215,
  latestPr: 'Bænkpres 92.5 kg x 3',
  totalVolumeKg: 24350,
  avgWorkoutMinutes: 54,
  mostTrainedExercise: 'Incline Dumbbell Press',
  weightTrend: <double>[84.2, 84.0, 83.9, 83.7, 83.5],
  strengthTrend: <double>[82.5, 85.0, 87.5, 90.0, 92.5],
);

const List<CoachMessage> mockCoachMessages = <CoachMessage>[
  CoachMessage(
    title: 'Dagens anbefaling',
    message: 'Du har trænet ben 2 gange i denne uge – overvej overkropsfokus i morgen.',
    category: 'Plan',
  ),
  CoachMessage(
    title: 'Progressionstip',
    message: 'Din bænkpres er steget 5% på 4 uger. Hold samme struktur i næste blok.',
    category: 'Progression',
  ),
  CoachMessage(
    title: 'Restitution',
    message: 'Du har haft 4 træningsdage i træk. Prioritér søvn og let aktiv restitution i dag.',
    category: 'Recovery',
  ),
  CoachMessage(
    title: 'Coachens vurdering',
    message: 'Stabil progression, høj konsistens og god volumenbalance mellem pres og træk.',
    category: 'Vurdering',
  ),
  CoachMessage(
    title: 'Næste skridt',
    message: 'Fortsæt 2 uger med samme split og øg vægt i hovedløft når top-reps nås i alle sæt.',
    category: 'Næste skridt',
  ),
];
