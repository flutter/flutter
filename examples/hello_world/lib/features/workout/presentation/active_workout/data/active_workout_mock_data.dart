import '../models/active_workout_models.dart';
import '../models/exercise_library_item.dart';

class ActiveWorkoutMockData {
  static ActiveWorkoutViewModel sessionFromLibrary(List<ExerciseLibraryItem> library) {
    ExerciseLibraryItem? bySlug(String slug) {
      for (final ExerciseLibraryItem item in library) {
        if (item.slug == slug) {
          return item;
        }
      }
      return null;
    }

    final ExerciseLibraryItem? abWheel = bySlug('ab-wheel-rollout');
    final ExerciseLibraryItem? backExtension = bySlug('rygekstension');

    return ActiveWorkoutViewModel(
      title: 'Øvelser i træning',
      exercises: <ActiveWorkoutExercise>[
        ActiveWorkoutExercise(
          id: abWheel?.slug ?? 'ab-wheel-rollout',
          title: abWheel?.navnDa ?? 'Ab wheel rollout',
          durationChip: '2m',
          restLabel: '2m',
          notes: '',
          quickActions: const <String>['Note', 'Ubehag'],
          sets: const <ActiveWorkoutSet>[
            ActiveWorkoutSet(previous: '10 kg × 12', kg: '10', reps: '12'),
            ActiveWorkoutSet(previous: '10 kg × 10', kg: '10', reps: '10'),
            ActiveWorkoutSet(previous: '8 kg × 12', kg: '8', reps: '12'),
          ],
        ),
        ActiveWorkoutExercise(
          id: backExtension?.slug ?? 'rygekstension',
          title: backExtension?.navnDa ?? 'Rygekstension',
          durationChip: '90s',
          restLabel: '90s',
          notes: '',
          quickActions: const <String>['Note', 'Ubehag'],
          sets: const <ActiveWorkoutSet>[
            ActiveWorkoutSet(previous: 'BW × 15', kg: '0', reps: '15'),
            ActiveWorkoutSet(previous: 'BW × 12', kg: '0', reps: '12'),
            ActiveWorkoutSet(previous: 'BW × 12', kg: '0', reps: '12'),
          ],
        ),
      ],
    );
  }

  static ActiveWorkoutViewModel session() {
    return const ActiveWorkoutViewModel(
      title: 'Øvelser i træning',
      exercises: <ActiveWorkoutExercise>[
        ActiveWorkoutExercise(
          id: 'ab-wheel',
          title: 'Ab Wheel',
          durationChip: '2m',
          restLabel: '2m',
          notes: '',
          quickActions: <String>['Note', 'Ubehag'],
          sets: <ActiveWorkoutSet>[
            ActiveWorkoutSet(previous: '10 kg × 12', kg: '10', reps: '12'),
            ActiveWorkoutSet(previous: '10 kg × 10', kg: '10', reps: '10'),
            ActiveWorkoutSet(previous: '8 kg × 12', kg: '8', reps: '12'),
          ],
        ),
        ActiveWorkoutExercise(
          id: 'back-extension',
          title: 'Back Extension',
          durationChip: '90s',
          restLabel: '90s',
          notes: '',
          quickActions: <String>['Note', 'Ubehag'],
          sets: <ActiveWorkoutSet>[
            ActiveWorkoutSet(previous: 'BW × 15', kg: '0', reps: '15'),
            ActiveWorkoutSet(previous: 'BW × 12', kg: '0', reps: '12'),
            ActiveWorkoutSet(previous: 'BW × 12', kg: '0', reps: '12'),
          ],
        ),
      ],
    );
  }

  static List<String> durationTags() {
    return const <String>[
      'Ab Wheel: 5 sæt',
      'Back Extension: 4 sæt',
    ];
  }
}
