class WorkoutSetDraft {
  const WorkoutSetDraft({
    required this.id,
    required this.setNumber,
    required this.reps,
    required this.kg,
    this.completed = false,
    this.previousReps,
    this.previousKg,
  });

  final String id;
  final int setNumber;
  final int reps;
  final double kg;
  final bool completed;
  final int? previousReps;
  final double? previousKg;

  WorkoutSetDraft copyWith({
    String? id,
    int? setNumber,
    int? reps,
    double? kg,
    bool? completed,
    int? previousReps,
    bool clearPreviousReps = false,
    double? previousKg,
    bool clearPreviousKg = false,
  }) {
    return WorkoutSetDraft(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      kg: kg ?? this.kg,
      completed: completed ?? this.completed,
      previousReps: clearPreviousReps ? null : (previousReps ?? this.previousReps),
      previousKg: clearPreviousKg ? null : (previousKg ?? this.previousKg),
    );
  }
}

class WorkoutExerciseDraft {
  const WorkoutExerciseDraft({
    required this.id,
    required this.name,
    required this.sets,
    this.notes = '',
  });

  final String id;
  final String name;
  final List<WorkoutSetDraft> sets;
  final String notes;

  WorkoutExerciseDraft copyWith({
    String? id,
    String? name,
    List<WorkoutSetDraft>? sets,
    String? notes,
  }) {
    return WorkoutExerciseDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }
}

class ActiveWorkoutDraft {
  const ActiveWorkoutDraft({
    required this.id,
    required this.startedAt,
    required this.exercises,
    this.endedAt,
    this.isActive = true,
    this.isMinimized = false,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isActive;
  final bool isMinimized;
  final List<WorkoutExerciseDraft> exercises;

  ActiveWorkoutDraft copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    bool clearEndedAt = false,
    bool? isActive,
    bool? isMinimized,
    List<WorkoutExerciseDraft>? exercises,
  }) {
    return ActiveWorkoutDraft(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      isActive: isActive ?? this.isActive,
      isMinimized: isMinimized ?? this.isMinimized,
      exercises: exercises ?? this.exercises,
    );
  }
}
