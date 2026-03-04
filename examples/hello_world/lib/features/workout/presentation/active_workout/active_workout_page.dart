import 'package:flutter/material.dart';

import 'active_workout_controls_page.dart';
import 'data/active_workout_mock_data.dart';
import 'data/exercise_library_repository.dart';
import 'models/active_workout_models.dart';
import 'widgets/exercise_card.dart';
import 'widgets/workout_top_bar.dart';
import 'widgets/workout_ui_tokens.dart';

class ActiveWorkoutPage extends StatefulWidget {
  const ActiveWorkoutPage({super.key});

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  final ExerciseLibraryRepository _libraryRepository = ExerciseLibraryRepository();
  String _title = 'Øvelser i træning';
  List<ActiveWorkoutExercise> _exercises = <ActiveWorkoutExercise>[];

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  Future<void> _loadWorkoutData() async {
    try {
      final library = await _libraryRepository.loadAll();
      final ActiveWorkoutViewModel model = ActiveWorkoutMockData.sessionFromLibrary(library);
      if (!mounted) {
        return;
      }
      setState(() {
        _title = model.title;
        _exercises = model.exercises;
      });
    } catch (_) {
      final ActiveWorkoutViewModel fallback = ActiveWorkoutMockData.session();
      if (!mounted) {
        return;
      }
      setState(() {
        _title = fallback.title;
        _exercises = fallback.exercises;
      });
    }
  }

  void _updateExercise(int exerciseIndex, ActiveWorkoutExercise updated) {
    setState(() {
      _exercises = List<ActiveWorkoutExercise>.from(_exercises)..[exerciseIndex] = updated;
    });
  }

  void _onAddSet(int exerciseIndex) {
    final ActiveWorkoutExercise exercise = _exercises[exerciseIndex];
    final List<ActiveWorkoutSet> sets = List<ActiveWorkoutSet>.from(exercise.sets)
      ..add(const ActiveWorkoutSet(previous: '--', kg: '', reps: ''));
    _updateExercise(exerciseIndex, exercise.copyWith(sets: sets));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutUiTokens.pageBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            WorkoutUiTokens.sidePadding,
            12,
            WorkoutUiTokens.sidePadding,
            24,
          ),
          children: <Widget>[
            WorkoutTopBar(
              onMinimize: () => Navigator.of(context).maybePop(),
              onFinish: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 18),
            Text(
              _title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: WorkoutUiTokens.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            for (int exerciseIndex = 0; exerciseIndex < _exercises.length; exerciseIndex++) ...<Widget>[
              ExerciseCard(
                exercise: _exercises[exerciseIndex],
                onSetCompleted: (int setIndex, bool completed) {
                  final ActiveWorkoutExercise exercise = _exercises[exerciseIndex];
                  final List<ActiveWorkoutSet> sets = List<ActiveWorkoutSet>.from(exercise.sets);
                  sets[setIndex] = sets[setIndex].copyWith(completed: completed);
                  _updateExercise(exerciseIndex, exercise.copyWith(sets: sets));
                },
                onSetKgChanged: (int setIndex, String value) {
                  final ActiveWorkoutExercise exercise = _exercises[exerciseIndex];
                  final List<ActiveWorkoutSet> sets = List<ActiveWorkoutSet>.from(exercise.sets);
                  sets[setIndex] = sets[setIndex].copyWith(kg: value);
                  _updateExercise(exerciseIndex, exercise.copyWith(sets: sets));
                },
                onSetRepsChanged: (int setIndex, String value) {
                  final ActiveWorkoutExercise exercise = _exercises[exerciseIndex];
                  final List<ActiveWorkoutSet> sets = List<ActiveWorkoutSet>.from(exercise.sets);
                  sets[setIndex] = sets[setIndex].copyWith(reps: value);
                  _updateExercise(exerciseIndex, exercise.copyWith(sets: sets));
                },
                onNoteChanged: (String note) {
                  final ActiveWorkoutExercise exercise = _exercises[exerciseIndex];
                  _updateExercise(exerciseIndex, exercise.copyWith(notes: note));
                },
                onAddSet: () => _onAddSet(exerciseIndex),
              ),
              const SizedBox(height: 14),
            ],
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ActiveWorkoutControlsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Åbn kontrolpanel'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: WorkoutUiTokens.accentGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
