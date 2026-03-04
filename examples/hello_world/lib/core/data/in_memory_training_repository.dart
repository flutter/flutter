import '../../features/programs/domain/program.dart';
import '../../features/workout/domain/exercise.dart';
import '../../features/workout/domain/workout_template.dart';

class InMemoryTrainingRepository {
  List<Program> loadPrograms() {
    return <Program>[
      const Program(
        id: 'foundation_strength',
        name: 'Foundation Strength',
        currentWeek: 2,
        totalWeeks: 8,
        workouts: <WorkoutTemplate>[
          WorkoutTemplate(
            id: 'upper_strength',
            name: 'Upper Strength',
            exercises: <Exercise>[
              Exercise(id: 'bench_press', name: 'Bench Press', primaryMuscle: 'Chest'),
              Exercise(id: 'barbell_row', name: 'Barbell Row', primaryMuscle: 'Back'),
              Exercise(
                id: 'overhead_press',
                name: 'Overhead Press',
                primaryMuscle: 'Shoulders',
              ),
            ],
          ),
          WorkoutTemplate(
            id: 'lower_strength',
            name: 'Lower Strength',
            exercises: <Exercise>[
              Exercise(id: 'back_squat', name: 'Back Squat', primaryMuscle: 'Legs'),
              Exercise(id: 'rdl', name: 'Romanian Deadlift', primaryMuscle: 'Hamstrings'),
              Exercise(id: 'split_squat', name: 'Split Squat', primaryMuscle: 'Legs'),
            ],
          ),
        ],
      ),
      const Program(
        id: 'hypertrophy_block',
        name: 'Hypertrophy Block',
        currentWeek: 1,
        totalWeeks: 6,
        workouts: <WorkoutTemplate>[
          WorkoutTemplate(
            id: 'push_volume',
            name: 'Push Volume',
            exercises: <Exercise>[
              Exercise(id: 'incline_db', name: 'Incline Dumbbell Press', primaryMuscle: 'Chest'),
              Exercise(id: 'lateral_raise', name: 'Lateral Raise', primaryMuscle: 'Shoulders'),
              Exercise(id: 'triceps_pushdown', name: 'Triceps Pushdown', primaryMuscle: 'Triceps'),
            ],
          ),
          WorkoutTemplate(
            id: 'pull_volume',
            name: 'Pull Volume',
            exercises: <Exercise>[
              Exercise(id: 'lat_pulldown', name: 'Lat Pulldown', primaryMuscle: 'Back'),
              Exercise(id: 'seated_row', name: 'Seated Cable Row', primaryMuscle: 'Back'),
              Exercise(id: 'db_curl', name: 'Dumbbell Curl', primaryMuscle: 'Biceps'),
            ],
          ),
        ],
      ),
    ];
  }
}
