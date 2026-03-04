enum IntensityLevel { let, normal, meget }

enum CrowdLevel { faa, normal, mange }

extension IntensityLevelLabel on IntensityLevel {
  String get label {
    switch (this) {
      case IntensityLevel.let:
        return 'Let';
      case IntensityLevel.normal:
        return 'Normal';
      case IntensityLevel.meget:
        return 'Meget';
    }
  }
}

extension CrowdLevelLabel on CrowdLevel {
  String get label {
    switch (this) {
      case CrowdLevel.faa:
        return 'Få';
      case CrowdLevel.normal:
        return 'Normal';
      case CrowdLevel.mange:
        return 'Mange';
    }
  }
}

class ActiveWorkoutSet {
  const ActiveWorkoutSet({
    required this.previous,
    required this.kg,
    required this.reps,
    this.completed = false,
  });

  final String previous;
  final String kg;
  final String reps;
  final bool completed;

  ActiveWorkoutSet copyWith({
    String? previous,
    String? kg,
    String? reps,
    bool? completed,
  }) {
    return ActiveWorkoutSet(
      previous: previous ?? this.previous,
      kg: kg ?? this.kg,
      reps: reps ?? this.reps,
      completed: completed ?? this.completed,
    );
  }
}

class ActiveWorkoutExercise {
  const ActiveWorkoutExercise({
    required this.id,
    required this.title,
    required this.durationChip,
    required this.restLabel,
    required this.quickActions,
    required this.sets,
    this.notes = '',
  });

  final String id;
  final String title;
  final String durationChip;
  final String restLabel;
  final String notes;
  final List<String> quickActions;
  final List<ActiveWorkoutSet> sets;

  ActiveWorkoutExercise copyWith({
    String? id,
    String? title,
    String? durationChip,
    String? restLabel,
    String? notes,
    List<String>? quickActions,
    List<ActiveWorkoutSet>? sets,
  }) {
    return ActiveWorkoutExercise(
      id: id ?? this.id,
      title: title ?? this.title,
      durationChip: durationChip ?? this.durationChip,
      restLabel: restLabel ?? this.restLabel,
      notes: notes ?? this.notes,
      quickActions: quickActions ?? this.quickActions,
      sets: sets ?? this.sets,
    );
  }
}

class ActiveWorkoutViewModel {
  const ActiveWorkoutViewModel({
    required this.title,
    required this.exercises,
  });

  final String title;
  final List<ActiveWorkoutExercise> exercises;

  ActiveWorkoutViewModel copyWith({
    String? title,
    List<ActiveWorkoutExercise>? exercises,
  }) {
    return ActiveWorkoutViewModel(
      title: title ?? this.title,
      exercises: exercises ?? this.exercises,
    );
  }
}
