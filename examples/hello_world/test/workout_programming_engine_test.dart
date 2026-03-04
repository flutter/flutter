import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/app/state/training_controller.dart';
import 'package:hello_world/core/data/in_memory_training_repository.dart';
import 'package:hello_world/core/engine/training_profile.dart';
import 'package:hello_world/core/engine/programming_models.dart';
import 'package:hello_world/core/engine/workout_programming_engine.dart';
import 'package:hello_world/core/storage/session_storage_stub.dart';

void main() {
  group('WorkoutProgrammingEngine', () {
    const WorkoutProgrammingEngine engine = WorkoutProgrammingEngine();

    test('creates normal workout with 5 exercises and warmup', () {
      const TrainingProfile profile = TrainingProfile(
        goal: TrainingGoal.generalFitness,
        level: TrainingLevel.beginner,
        equipment: EquipmentAccess.fullGym,
        duration: SessionDuration.normal,
      );

      final plan = engine.generateSimpleWorkout(profile);

      expect(plan.exercises.length, 5);
      expect(plan.warmup, isNotEmpty);
      expect(plan.safetyNotes.length, greaterThanOrEqualTo(3));
    });

    test('uses top set back-off model for strength goal', () {
      const TrainingProfile profile = TrainingProfile(
        goal: TrainingGoal.strength,
        level: TrainingLevel.intermediate,
        equipment: EquipmentAccess.fullGym,
        duration: SessionDuration.normal,
      );

      final plan = engine.generateSimpleWorkout(profile);

      expect(plan.progressionModel, InSessionProgressionModel.topSetBackoff);
      expect(plan.progressionRule.toLowerCase(), contains('top set'));
    });

    test('uses double progression for hypertrophy goal', () {
      const TrainingProfile profile = TrainingProfile(
        goal: TrainingGoal.hypertrophy,
        level: TrainingLevel.intermediate,
        equipment: EquipmentAccess.dumbbells,
        duration: SessionDuration.short,
      );

      final plan = engine.generateSimpleWorkout(profile);

      expect(plan.progressionModel, InSessionProgressionModel.doubleProgression);
      expect(plan.exercises.length, 4);
    });
  });

  group('TrainingController engine integration', () {
    test('creates and activates program from generated plan', () {
      final controller = TrainingController(
        repository: InMemoryTrainingRepository(),
        storage: createSessionStorageImpl(),
      );

      final initialCount = controller.programs.length;

      const TrainingProfile profile = TrainingProfile(
        goal: TrainingGoal.recomposition,
        level: TrainingLevel.beginner,
        equipment: EquipmentAccess.homeGym,
        duration: SessionDuration.normal,
      );

      final generated = controller.createProgramFromGeneratedPlan(profile: profile);

      expect(controller.programs.length, initialCount + 1);
      expect(controller.activeProgram.id, generated.id);
      expect(controller.activeProgram.workouts.first.exercises, isNotEmpty);
    });
  });
}
