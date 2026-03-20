import 'dart:async';

import 'package:flutter/material.dart';

import '../features/workout/presentation/active_workout/data/exercise_library_repository.dart';
import '../features/workout/presentation/active_workout/models/exercise_library_item.dart';
import '../models/active_workout_draft.dart';
import '../models/workout_session.dart';
import '../services/app_controller.dart';
import 'workout/widgets/add_exercise_button.dart';
import 'workout/widgets/exercise_picker_sheet.dart';
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
  final ExerciseLibraryRepository _exerciseLibraryRepository = ExerciseLibraryRepository();
  late ActiveWorkoutDraft _draft;
  List<ExerciseLibraryItem> _exerciseLibrary = const <ExerciseLibraryItem>[];

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

    _loadExerciseLibrary();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds.value = DateTime.now().difference(_draft.startedAt).inSeconds;
    });
  }

  Future<void> _loadExerciseLibrary() async {
    final List<ExerciseLibraryItem> library = await _exerciseLibraryRepository.loadAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _exerciseLibrary = List<ExerciseLibraryItem>.from(library)
        ..sort((ExerciseLibraryItem a, ExerciseLibraryItem b) => a.navnDa.compareTo(b.navnDa));
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

  Future<void> _addExercise() async {
    if (_exerciseLibrary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke indlæse øvelsesbiblioteket endnu. Prøv igen om et øjeblik.')),
      );
      return;
    }
    final ExerciseLibraryItem? selected = await _showExercisePicker();
    if (selected == null) {
      return;
    }

    final WorkoutExerciseDraft exercise = _createExerciseDraft(selected.navnDa);

    final List<WorkoutExerciseDraft> exercises = List<WorkoutExerciseDraft>.from(_draft.exercises)..add(exercise);
    _saveDraft(_draft.copyWith(exercises: exercises));
  }

  WorkoutExerciseDraft _createExerciseDraft(String name) {
    return WorkoutExerciseDraft(
      id: 'ex-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      notes: '',
      sets: <WorkoutSetDraft>[_createSetDraft(setNumber: 1)],
    );
  }

  WorkoutSetDraft _createSetDraft({required int setNumber}) {
    return WorkoutSetDraft(
      id: 'set-${DateTime.now().microsecondsSinceEpoch}',
      setNumber: setNumber,
      reps: 10,
      kg: 0,
    );
  }

  Future<ExerciseLibraryItem?> _showExercisePicker() {
    return showModalBottomSheet<ExerciseLibraryItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => ExercisePickerSheet(exercises: _exerciseLibrary),
    );
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
      ..add(_createSetDraft(setNumber: nextSet));

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
                  onNameChanged: (String value) => _updateExercise(
                    exerciseIndex,
                    _draft.exercises[exerciseIndex].copyWith(name: value),
                  ),
                  onNotesChanged: (String value) => _updateExercise(
                    exerciseIndex,
                    _draft.exercises[exerciseIndex].copyWith(notes: value),
                  ),
                  onAddSet: () => _addSet(exerciseIndex),
                  onDeleteExercise: () => _deleteExercise(exerciseIndex),
                  onSetKgChanged: (int setIndex, String value) {
                    _updateSet(exerciseIndex, setIndex, kg: _parseKg(value));
                  },
                  onSetRepsChanged: (int setIndex, String value) {
                    _updateSet(exerciseIndex, setIndex, reps: _parseReps(value));
                  },
                  onSetCompletionChanged: (int setIndex, bool value) {
                    _updateSet(exerciseIndex, setIndex, completed: value);
                  },
                  onDeleteSet: (int setIndex) => _deleteSet(exerciseIndex, setIndex),
                ),
                const SizedBox(height: 14),
              ],
              AddExerciseButton(
                label: 'Tilføj øvelse',
                onPressed: _addExercise,
                filled: true,
              ),
            ],
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

  double _parseKg(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  int _parseReps(String value) {
    return int.tryParse(value) ?? 0;
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
