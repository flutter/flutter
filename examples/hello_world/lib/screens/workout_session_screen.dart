import 'dart:async';

import 'package:flutter/material.dart';

import '../models/active_workout_draft.dart';
import '../models/workout_session.dart';
import '../services/app_controller.dart';
import 'workout/widgets/add_exercise_button.dart';
import 'workout/widgets/workout_exercise_card.dart';
import 'workout/widgets/workout_header_bar.dart';
import 'workout/widgets/workout_ui_tokens.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late final Timer _timer;
  late final ValueNotifier<int> _elapsedSeconds;
  late ActiveWorkoutDraft _draft;

  @override
  void initState() {
    super.initState();
    final ActiveWorkoutDraft? active = widget.controller.activeWorkoutDraft;
    _draft = active ??
        ActiveWorkoutDraft(
          id: 'ws-${DateTime.now().microsecondsSinceEpoch}',
          startedAt: DateTime.now(),
          exercises: const <WorkoutExerciseDraft>[],
          isActive: true,
          isMinimized: false,
        );

    _elapsedSeconds = ValueNotifier<int>(DateTime.now().difference(_draft.startedAt).inSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds.value = DateTime.now().difference(_draft.startedAt).inSeconds;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _elapsedSeconds.dispose();
    super.dispose();
  }

  void _saveDraft(ActiveWorkoutDraft draft) {
    setState(() {
      _draft = draft;
    });
    widget.controller.updateActiveWorkout(draft);
  }

  void _addExercise() {
    final int index = _draft.exercises.length + 1;
    final WorkoutExerciseDraft exercise = WorkoutExerciseDraft(
      id: 'ex-${DateTime.now().microsecondsSinceEpoch}',
      name: 'Øvelse $index',
      notes: '',
      sets: <WorkoutSetDraft>[
        WorkoutSetDraft(
          id: 'set-${DateTime.now().microsecondsSinceEpoch}',
          setNumber: 1,
          reps: 10,
          kg: 0,
        ),
      ],
    );

    final List<WorkoutExerciseDraft> exercises = List<WorkoutExerciseDraft>.from(_draft.exercises)..add(exercise);
    _saveDraft(_draft.copyWith(exercises: exercises));
  }

  void _updateExercise(int exerciseIndex, WorkoutExerciseDraft updatedExercise) {
    final List<WorkoutExerciseDraft> exercises = List<WorkoutExerciseDraft>.from(_draft.exercises);
    exercises[exerciseIndex] = updatedExercise;
    _saveDraft(_draft.copyWith(exercises: exercises));
  }

  void _deleteExercise(int exerciseIndex) {
    final List<WorkoutExerciseDraft> exercises = List<WorkoutExerciseDraft>.from(_draft.exercises)..removeAt(exerciseIndex);
    _saveDraft(_draft.copyWith(exercises: exercises));
  }

  void _addSet(int exerciseIndex) {
    final WorkoutExerciseDraft exercise = _draft.exercises[exerciseIndex];
    final int nextSet = exercise.sets.length + 1;

    final List<WorkoutSetDraft> sets = List<WorkoutSetDraft>.from(exercise.sets)
      ..add(
        WorkoutSetDraft(
          id: 'set-${DateTime.now().microsecondsSinceEpoch}',
          setNumber: nextSet,
          reps: 10,
          kg: 0,
        ),
      );

    _updateExercise(exerciseIndex, exercise.copyWith(sets: sets));
  }

  void _deleteSet(int exerciseIndex, int setIndex) {
    final WorkoutExerciseDraft exercise = _draft.exercises[exerciseIndex];
    if (exercise.sets.length <= 1) {
      return;
    }
    final List<WorkoutSetDraft> sets = List<WorkoutSetDraft>.from(exercise.sets)..removeAt(setIndex);
    final List<WorkoutSetDraft> resequenced = <WorkoutSetDraft>[
      for (int i = 0; i < sets.length; i++) sets[i].copyWith(setNumber: i + 1),
    ];
    _updateExercise(exerciseIndex, exercise.copyWith(sets: resequenced));
  }

  void _updateSet(
    int exerciseIndex,
    int setIndex, {
    int? reps,
    double? kg,
    bool? completed,
  }) {
    final WorkoutExerciseDraft exercise = _draft.exercises[exerciseIndex];
    final List<WorkoutSetDraft> sets = List<WorkoutSetDraft>.from(exercise.sets);
    sets[setIndex] = sets[setIndex].copyWith(
      reps: reps,
      kg: kg,
      completed: completed,
    );
    _updateExercise(exerciseIndex, exercise.copyWith(sets: sets));
  }

  Future<void> _finishWorkout() async {
    final WorkoutSession? session = await widget.controller.finishActiveWorkout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Træning gemt • ${session?.durationMinutes ?? 0} min • ${session?.totalSets ?? 0} sæt',
        ),
      ),
    );
  }

  void _minimizeWorkout() {
    widget.controller.minimizeActiveWorkout();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _draft.exercises.isEmpty;

    return Scaffold(
      backgroundColor: WorkoutUiTokens.pageBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: <Widget>[
            ValueListenableBuilder<int>(
              valueListenable: _elapsedSeconds,
              builder: (BuildContext context, int value, Widget? child) {
                return WorkoutHeaderBar(
                  elapsed: _formatDuration(value),
                  onMinimize: _minimizeWorkout,
                  onFinish: _finishWorkout,
                );
              },
            ),
            const SizedBox(height: 16),
            if (isEmpty)
              _EmptyWorkoutState(onAddExercise: _addExercise)
            else ...<Widget>[
              for (int exerciseIndex = 0; exerciseIndex < _draft.exercises.length; exerciseIndex) ...<Widget>[
                WorkoutExerciseCard(
                  exercise: _draft.exercises[exerciseIndex],
                  onNameChanged: (String value) =>
                      _updateExercise(exerciseIndex, _draft.exercises[exerciseIndex].copyWith(name: value)),
                  onNotesChanged: (String value) =>
                      _updateExercise(exerciseIndex, _draft.exercises[exerciseIndex].copyWith(notes: value)),
                  onAddSet: () => _addSet(exerciseIndex),
                  onDeleteExercise: () => _deleteExercise(exerciseIndex),
                  onSetKgChanged: (int setIndex, String value) {
                    _updateSet(exerciseIndex, setIndex, kg: double.tryParse(value.replaceAll(',', '.')) ?? 0);
                  },
                  onSetRepsChanged: (int setIndex, String value) {
                    _updateSet(exerciseIndex, setIndex, reps: int.tryParse(value) ?? 0);
                  },
                  onSetCompletionChanged: (int setIndex, bool value) {
                    _updateSet(exerciseIndex, setIndex, completed: value);
                  },
                  onDeleteSet: (int setIndex) => _deleteSet(exerciseIndex, setIndex),
                ),
                const SizedBox(height: 14),
              ],
            ],
            AddExerciseButton(
              label: 'Tilføj øvelse',
              onPressed: _addExercise,
              filled: true,
            ),
            const SizedBox(height: 10),
            AddExerciseButton(
              label: 'Tilføj øvelse nederst',
              onPressed: _addExercise,
              filled: false,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _EmptyWorkoutState extends StatelessWidget {
  const _EmptyWorkoutState({required this.onAddExercise});

  final VoidCallback onAddExercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: WorkoutUiTokens.softShadow(),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          const Icon(Icons.fitness_center, size: 30),
          const SizedBox(height: 10),
          Text(
            'Din træning er startet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Tilføj din første øvelse for at begynde at logge sæt, kg og reps.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: WorkoutUiTokens.textSecondary),
          ),
          const SizedBox(height: 16),
          AddExerciseButton(
            label: 'Tilføj øvelse',
            onPressed: onAddExercise,
          ),
        ],
      ),
    );
  }
}
