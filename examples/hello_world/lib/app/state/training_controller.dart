import 'package:flutter/foundation.dart';
import '../../core/data/in_memory_training_repository.dart';
import '../../core/engine/workout_programming_engine.dart';
import '../../core/engine/training_profile.dart';
import '../../core/engine/programming_models.dart';
import '../../core/storage/session_storage.dart';
import '../../features/programs/domain/program.dart';
import '../../features/workout/domain/exercise.dart';
import '../../features/workout/domain/session_log.dart';
import '../../features/workout/domain/workout_template.dart';

class TrainingController extends ChangeNotifier {
  TrainingController({
    required InMemoryTrainingRepository repository,
    required SessionStorage storage,
  })  : _programs = repository.loadPrograms(),
        _storage = storage {
    _activeProgram = _programs.first;
    _activeProgramId = _activeProgram.id;
  }

  final List<Program> _programs;
  final SessionStorage _storage;
  final WorkoutProgrammingEngine _programmingEngine = const WorkoutProgrammingEngine();
  final List<SessionLog> _sessionHistory = <SessionLog>[];
  final Map<String, int> _setCounts = <String, int>{};

  late Program _activeProgram;
  late String _activeProgramId;
  WorkoutTemplate? _activeWorkout;
  DateTime? _sessionStartedAt;

  List<Program> get programs => List<Program>.unmodifiable(_programs);
  Program get activeProgram => _activeProgram;
  WorkoutTemplate get nextWorkout => _activeProgram.workouts.first;
  WorkoutTemplate? get activeWorkout => _activeWorkout;
  DateTime? get sessionStartedAt => _sessionStartedAt;
  Duration get activeSessionDuration {
    final DateTime? startedAt = _sessionStartedAt;
    if (startedAt == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(startedAt);
  }
  int get activeSessionSetCount {
    return _setCounts.values.fold<int>(0, (int total, int value) => total + value);
  }
  int get suggestedSessionSetTarget {
    final WorkoutTemplate template = _activeWorkout ?? nextWorkout;
    return template.exercises.length * 3;
  }
  List<SessionLog> get sessionHistory => List<SessionLog>.unmodifiable(_sessionHistory);
  List<SessionLog> get recentSessionHistory {
    final sorted = List<SessionLog>.from(_sessionHistory)
      ..sort((SessionLog a, SessionLog b) => b.completedAt.compareTo(a.completedAt));
    return List<SessionLog>.unmodifiable(sorted);
  }

  int setsForExercise(String exerciseId) => _setCounts[exerciseId] ?? 0;

  int get completedSessionsThisWeek {
    final now = DateTime.now();
    final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return _sessionHistory.where((SessionLog log) => log.completedAt.isAfter(startOfWeek)).length;
  }

  int get totalSetsLogged {
    return _sessionHistory.fold<int>(
      0,
      (int total, SessionLog log) =>
          total + log.setsByExercise.values.fold<int>(0, (int sum, int sets) => sum + sets),
    );
  }

  Map<String, int> get topExercisesBySets {
    final exerciseNameById = <String, String>{
      for (final Program program in _programs)
        for (final WorkoutTemplate workout in program.workouts)
          for (final Exercise exercise in workout.exercises) exercise.id: exercise.name,
    };

    final totals = <String, int>{};
    for (final SessionLog log in _sessionHistory) {
      log.setsByExercise.forEach((String exerciseId, int sets) {
        final String name = exerciseNameById[exerciseId] ?? exerciseId;
        totals[name] = (totals[name] ?? 0) + sets;
      });
    }

    final List<MapEntry<String, int>> sorted = totals.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value));

    return Map<String, int>.fromEntries(sorted);
  }

  String workoutNameById(String workoutTemplateId) {
    for (final Program program in _programs) {
      for (final WorkoutTemplate workout in program.workouts) {
        if (workout.id == workoutTemplateId) {
          return workout.name;
        }
      }
    }
    return workoutTemplateId;
  }

  String get weeklyConsistencyText {
    const weeklyTarget = 4;
    final int done = completedSessionsThisWeek;
    return '$done of $weeklyTarget planned sessions completed';
  }

  String get coachProposalPreview {
    if (_activeProgram.workouts.isEmpty) {
      return 'No program loaded yet.';
    }
    final WorkoutTemplate firstWorkout = _activeProgram.workouts.first;
    if (firstWorkout.exercises.isEmpty) {
      return 'No exercise to swap in the next workout.';
    }
    final Exercise firstExercise = firstWorkout.exercises.first;
    if (firstExercise.name == 'Incline Dumbbell Press') {
      return 'Next workout already starts with Incline Dumbbell Press.';
    }
    return 'Swap ${firstExercise.name} with Incline Dumbbell Press in ${firstWorkout.name}.';
  }

  GeneratedWorkoutPlan generateWorkoutPlan(TrainingProfile profile) {
    return _programmingEngine.generateSimpleWorkout(profile);
  }

  Program createProgramFromGeneratedPlan({
    required TrainingProfile profile,
    String? routineName,
  }) {
    final GeneratedWorkoutPlan plan = _programmingEngine.generateSimpleWorkout(profile);
    final String seed = DateTime.now().microsecondsSinceEpoch.toString();
    final String finalRoutineName = routineName?.trim().isNotEmpty == true
        ? routineName!.trim()
        : plan.title;

    final List<Exercise> generatedExercises = plan.exercises
        .map(
          (ExercisePrescription spec) => Exercise(
            id: '${spec.exerciseId}_$seed',
            name: spec.exerciseName,
            primaryMuscle: spec.primaryMuscle,
          ),
        )
        .toList(growable: false);

    final WorkoutTemplate workout = WorkoutTemplate(
      id: 'ai_workout_$seed',
      name: plan.title,
      exercises: generatedExercises,
    );

    final Program program = Program(
      id: 'ai_program_$seed',
      name: finalRoutineName,
      currentWeek: 1,
      totalWeeks: 4,
      workouts: <WorkoutTemplate>[workout],
    );

    _programs.add(program);
    _activeProgram = program;
    _activeProgramId = program.id;
    _activeWorkout = null;
    _setCounts.clear();
    _sessionStartedAt = null;
    _persistSnapshot();
    notifyListeners();

    return program;
  }

  void selectProgram(String programId) {
    final Program selectedProgram = _programs.firstWhere((Program program) => program.id == programId);
    _activeProgramId = selectedProgram.id;
    _activeProgram = selectedProgram;
    _activeWorkout = null;
    _setCounts.clear();
    _sessionStartedAt = null;
    _persistSnapshot();
    notifyListeners();
  }

  void startWorkout([WorkoutTemplate? workoutTemplate]) {
    final WorkoutTemplate template = workoutTemplate ?? nextWorkout;
    _activeWorkout = template;
    _setCounts.clear();
    _sessionStartedAt = DateTime.now();
    for (final Exercise exercise in template.exercises) {
      _setCounts[exercise.id] = 0;
    }
    notifyListeners();
  }

  void logSet(String exerciseId) {
    if (_activeWorkout == null) {
      return;
    }
    _setCounts[exerciseId] = (_setCounts[exerciseId] ?? 0) + 1;
    notifyListeners();
  }

  void removeSet(String exerciseId) {
    if (_activeWorkout == null) {
      return;
    }
    final int current = _setCounts[exerciseId] ?? 0;
    if (current == 0) {
      return;
    }
    _setCounts[exerciseId] = current - 1;
    notifyListeners();
  }

  void finishWorkout() {
    final WorkoutTemplate? workout = _activeWorkout;
    final DateTime? startedAt = _sessionStartedAt;
    if (workout == null || startedAt == null) {
      return;
    }

    _sessionHistory.add(
      SessionLog(
        workoutTemplateId: workout.id,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        setsByExercise: Map<String, int>.from(_setCounts),
      ),
    );

    _activeWorkout = null;
    _setCounts.clear();
    _sessionStartedAt = null;
    _persistSnapshot();
    notifyListeners();
  }

  void applyCoachProposal() {
    if (_activeProgram.workouts.isEmpty || _activeProgram.workouts.first.exercises.isEmpty) {
      return;
    }

    final WorkoutTemplate firstWorkout = _activeProgram.workouts.first;
    final Exercise firstExercise = firstWorkout.exercises.first;
    if (firstExercise.name == 'Incline Dumbbell Press') {
      return;
    }

    final updatedExercises = <Exercise>[
      const Exercise(
        id: 'incline_db_press',
        name: 'Incline Dumbbell Press',
        primaryMuscle: 'Chest',
      ),
      ...firstWorkout.exercises.skip(1),
    ];

    final WorkoutTemplate updatedWorkout = firstWorkout.copyWith(exercises: updatedExercises);
    final updatedWorkouts = <WorkoutTemplate>[
      updatedWorkout,
      ..._activeProgram.workouts.skip(1),
    ];

    _activeProgram = _activeProgram.copyWith(workouts: updatedWorkouts);

    final int index = _programs.indexWhere((Program program) => program.id == _activeProgramId);
    _programs[index] = _activeProgram;
    _persistSnapshot();
    notifyListeners();
  }

  void createRoutineWithWorkout({
    required String routineName,
    required String workoutName,
    required List<Exercise> exercises,
  }) {
    final String normalizedRoutineName = routineName.trim().isEmpty ? 'Ny rutine' : routineName.trim();
    final String normalizedWorkoutName = workoutName.trim().isEmpty ? 'Ny træning' : workoutName.trim();
    final now = DateTime.now();
    final seed = now.microsecondsSinceEpoch.toString();

    final program = Program(
      id: 'custom_program_$seed',
      name: normalizedRoutineName,
      currentWeek: 1,
      totalWeeks: 1,
      workouts: <WorkoutTemplate>[
        WorkoutTemplate(
          id: 'custom_workout_$seed',
          name: normalizedWorkoutName,
          exercises: List<Exercise>.unmodifiable(exercises),
        ),
      ],
    );

    _programs.add(program);
    _activeProgram = program;
    _activeProgramId = program.id;
    _activeWorkout = null;
    _setCounts.clear();
    _sessionStartedAt = null;
    _persistSnapshot();
    notifyListeners();
  }

  void updateRoutineWithWorkout({
    required String programId,
    required String routineName,
    required String workoutName,
    required List<Exercise> exercises,
  }) {
    final int index = _programs.indexWhere((Program program) => program.id == programId);
    if (index < 0) {
      return;
    }

    final Program existingProgram = _programs[index];
    final String normalizedRoutineName = routineName.trim().isEmpty ? existingProgram.name : routineName.trim();
    final String normalizedWorkoutName = workoutName.trim().isEmpty
        ? (existingProgram.workouts.isNotEmpty ? existingProgram.workouts.first.name : 'Ny træning')
        : workoutName.trim();

    final WorkoutTemplate updatedWorkout = existingProgram.workouts.isNotEmpty
        ? existingProgram.workouts.first.copyWith(
            name: normalizedWorkoutName,
            exercises: List<Exercise>.unmodifiable(exercises),
          )
        : WorkoutTemplate(
            id: 'custom_workout_${DateTime.now().microsecondsSinceEpoch}',
            name: normalizedWorkoutName,
            exercises: List<Exercise>.unmodifiable(exercises),
          );

    final updatedWorkouts = existingProgram.workouts.isNotEmpty
        ? <WorkoutTemplate>[updatedWorkout, ...existingProgram.workouts.skip(1)]
        : <WorkoutTemplate>[updatedWorkout];

    final Program updatedProgram = existingProgram.copyWith(
      name: normalizedRoutineName,
      workouts: updatedWorkouts,
    );

    _programs[index] = updatedProgram;

    if (_activeProgramId == programId) {
      _activeProgram = updatedProgram;
      if (_activeWorkout != null && _activeWorkout!.id == updatedWorkout.id) {
        _activeWorkout = updatedWorkout;
      }
    }

    _persistSnapshot();
    notifyListeners();
  }

  bool removeRoutine(String programId) {
    if (_programs.length <= 1) {
      return false;
    }

    final int index = _programs.indexWhere((Program program) => program.id == programId);
    if (index < 0) {
      return false;
    }

    final wasActive = _activeProgramId == programId;
    _programs.removeAt(index);

    if (wasActive) {
      _activeProgram = _programs.first;
      _activeProgramId = _activeProgram.id;
      _activeWorkout = null;
      _setCounts.clear();
      _sessionStartedAt = null;
    }

    _persistSnapshot();
    notifyListeners();
    return true;
  }

  Future<void> hydrate() async {
    final SessionSnapshot? snapshot = await _storage.read();
    if (snapshot == null) {
      return;
    }

    final int programIndex = _programs.indexWhere(
      (Program program) => program.id == snapshot.activeProgramId,
    );
    if (programIndex >= 0) {
      _activeProgram = _programs[programIndex];
      _activeProgramId = _activeProgram.id;
    }

    _sessionHistory
      ..clear()
      ..addAll(snapshot.logs);
    notifyListeners();
  }

  void _persistSnapshot() {
    _storage.write(
      SessionSnapshot(
        activeProgramId: _activeProgramId,
        logs: List<SessionLog>.from(_sessionHistory),
      ),
    );
  }
}
