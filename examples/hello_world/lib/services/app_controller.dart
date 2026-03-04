import 'package:flutter/foundation.dart';

import '../models/active_workout_draft.dart';
import '../models/workout.dart';
import '../models/workout_session.dart';
import 'workout_history_repository.dart';

enum HomeTab { home, stats, coach, account }

enum WeightUnit { kg, lbs }

class AppController extends ChangeNotifier {
  AppController({WorkoutHistoryRepository? historyRepository})
      : _historyRepository = historyRepository ?? createWorkoutHistoryRepository();

  HomeTab _currentTab = HomeTab.home;
  bool _darkMode = true;
  bool _notificationsEnabled = true;
  WeightUnit _weightUnit = WeightUnit.kg;
  ActiveWorkoutDraft? _activeWorkoutDraft;
  final WorkoutHistoryRepository _historyRepository;
  List<WorkoutSession> _history = const <WorkoutSession>[];
  bool _historyHydrated = false;

  HomeTab get currentTab => _currentTab;
  bool get darkMode => _darkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  WeightUnit get weightUnit => _weightUnit;
  ActiveWorkoutDraft? get activeWorkoutDraft => _activeWorkoutDraft;
  bool get hasActiveWorkout => _activeWorkoutDraft != null;
  List<WorkoutSession> get history => List<WorkoutSession>.unmodifiable(_history);
  bool get historyHydrated => _historyHydrated;

  void startEmptyWorkout() {
    if (_activeWorkoutDraft != null) {
      return;
    }
    _activeWorkoutDraft = ActiveWorkoutDraft(
      id: _newId('ws'),
      startedAt: DateTime.now(),
      exercises: const <WorkoutExerciseDraft>[],
      isActive: true,
      isMinimized: false,
    );
    notifyListeners();
  }

  void updateActiveWorkout(ActiveWorkoutDraft draft) {
    _activeWorkoutDraft = draft;
    notifyListeners();
  }

  void minimizeActiveWorkout() {
    final ActiveWorkoutDraft? draft = _activeWorkoutDraft;
    if (draft == null) {
      return;
    }
    _activeWorkoutDraft = draft.copyWith(isMinimized: true);
    notifyListeners();
  }

  void resumeActiveWorkout() {
    final ActiveWorkoutDraft? draft = _activeWorkoutDraft;
    if (draft == null) {
      return;
    }
    _activeWorkoutDraft = draft.copyWith(isMinimized: false);
    notifyListeners();
  }

  Future<WorkoutSession?> finishActiveWorkout() async {
    final ActiveWorkoutDraft? draft = _activeWorkoutDraft;
    if (draft == null) {
      return null;
    }

    final DateTime endedAt = DateTime.now();
    final int elapsedSeconds = endedAt.difference(draft.startedAt).inSeconds;
    final int durationMinutes = (elapsedSeconds / 60).ceil().clamp(1, 240);
    final int totalSets = draft.exercises.fold<int>(0, (int sum, WorkoutExerciseDraft exercise) {
      return sum + exercise.sets.length;
    });

    final Workout workout = Workout(
      title: 'Fri træning',
      focus: 'Valgfri',
      durationMinutes: durationMinutes,
      exercises: draft.exercises.map((WorkoutExerciseDraft e) => e.name).toList(growable: false),
      scheduledLabel: 'I dag',
    );

    final WorkoutSession session = WorkoutSession(
      title: workout.title,
      focus: workout.focus,
      startedAt: draft.startedAt,
      completedAt: endedAt,
      durationMinutes: durationMinutes,
      totalSets: totalSets,
      exercises: workout.exercises,
      exerciseLogs: draft.exercises
          .map(
            (WorkoutExerciseDraft exercise) => <String, dynamic>{
              'id': exercise.id,
              'name': exercise.name,
              'notes': exercise.notes,
              'sets': exercise.sets
                  .map(
                    (WorkoutSetDraft set) => <String, dynamic>{
                      'id': set.id,
                      'setNumber': set.setNumber,
                      'kg': set.kg,
                      'reps': set.reps,
                      'completed': set.completed,
                      'previousKg': set.previousKg,
                      'previousReps': set.previousReps,
                    },
                  )
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
    );

    _history = <WorkoutSession>[session, ..._history];
    await _historyRepository.writeAll(_history);
    _activeWorkoutDraft = null;
    notifyListeners();
    return session;
  }

  void discardActiveWorkout() {
    if (_activeWorkoutDraft == null) {
      return;
    }
    _activeWorkoutDraft = null;
    notifyListeners();
  }

  Future<void> hydrateHistory() async {
    _history = await _historyRepository.readAll();
    _historyHydrated = true;
    notifyListeners();
  }

  Future<void> addCompletedWorkout({
    required Workout workout,
    required int durationMinutes,
    required int totalSets,
  }) async {
    final DateTime endedAt = DateTime.now();
    final WorkoutSession session = WorkoutSession(
      title: workout.title,
      focus: workout.focus,
      startedAt: endedAt.subtract(Duration(minutes: durationMinutes)),
      completedAt: endedAt,
      durationMinutes: durationMinutes,
      totalSets: totalSets,
      exercises: workout.exercises,
    );

    _history = <WorkoutSession>[session, ..._history];
    await _historyRepository.writeAll(_history);
    notifyListeners();
  }

  void setTab(HomeTab tab) {
    if (_currentTab == tab) {
      return;
    }
    _currentTab = tab;
    notifyListeners();
  }

  void toggleDarkMode(bool value) {
    _darkMode = value;
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void setWeightUnit(WeightUnit unit) {
    if (_weightUnit == unit) {
      return;
    }
    _weightUnit = unit;
    notifyListeners();
  }

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}
