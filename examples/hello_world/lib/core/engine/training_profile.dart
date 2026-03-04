enum TrainingGoal {
  strength,
  hypertrophy,
  recomposition,
  mobility,
  generalFitness,
}

enum TrainingLevel {
  beginner,
  intermediate,
  advanced,
}

enum EquipmentAccess {
  fullGym,
  dumbbells,
  bodyweight,
  homeGym,
}

enum SessionDuration {
  short,
  normal,
  long,
}

class TrainingProfile {
  const TrainingProfile({
    required this.goal,
    required this.level,
    required this.equipment,
    required this.duration,
    this.focusArea,
    this.daysPerWeek,
  });

  final TrainingGoal goal;
  final TrainingLevel level;
  final EquipmentAccess equipment;
  final SessionDuration duration;
  final String? focusArea;
  final int? daysPerWeek;
}
