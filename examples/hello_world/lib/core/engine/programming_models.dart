import 'training_profile.dart';

enum InSessionProgressionModel {
  topSetBackoff,
  straightSets,
  doubleProgression,
  density,
  techniqueQuality,
}

class ExercisePrescription {
  const ExercisePrescription({
    required this.exerciseId,
    required this.exerciseName,
    required this.primaryMuscle,
    required this.movementPattern,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.intensityCue,
    required this.note,
    this.alternative,
  });

  final String exerciseId;
  final String exerciseName;
  final String primaryMuscle;
  final String movementPattern;
  final int sets;
  final String reps;
  final int restSeconds;
  final String intensityCue;
  final String note;
  final String? alternative;
}

class WarmupStep {
  const WarmupStep({required this.title, required this.durationOrReps});

  final String title;
  final String durationOrReps;
}

class GeneratedWorkoutPlan {
  const GeneratedWorkoutPlan({
    required this.title,
    required this.goal,
    required this.level,
    required this.equipment,
    required this.duration,
    required this.warmup,
    required this.exercises,
    required this.progressionModel,
    required this.progressionRule,
    required this.safetyNotes,
  });

  final String title;
  final TrainingGoal goal;
  final TrainingLevel level;
  final EquipmentAccess equipment;
  final SessionDuration duration;
  final List<WarmupStep> warmup;
  final List<ExercisePrescription> exercises;
  final InSessionProgressionModel progressionModel;
  final String progressionRule;
  final List<String> safetyNotes;
}
