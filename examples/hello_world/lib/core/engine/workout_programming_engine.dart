import 'exercise_knowledge.dart';
import 'programming_models.dart';
import 'training_profile.dart';

class WorkoutProgrammingEngine {
  const WorkoutProgrammingEngine();

  GeneratedWorkoutPlan generateSimpleWorkout(TrainingProfile profile) {
    final SessionDuration duration = profile.duration;
    final int exerciseCount = switch (duration) {
      SessionDuration.short => 4,
      SessionDuration.normal => 5,
      SessionDuration.long => 6,
    };

    final List<WarmupStep> warmup = _buildWarmup(profile);
    final InSessionProgressionModel progressionModel = _progressionModelForGoal(profile.goal);
    final List<ExercisePrescription> exercises = _buildMainBlock(profile, exerciseCount, progressionModel);

    return GeneratedWorkoutPlan(
      title: _titleForProfile(profile),
      goal: profile.goal,
      level: profile.level,
      equipment: profile.equipment,
      duration: profile.duration,
      warmup: warmup,
      exercises: exercises,
      progressionModel: progressionModel,
      progressionRule: _progressionRule(progressionModel),
      safetyNotes: const <String>[
        'Stop ved skarp smerte eller usædvanlige symptomer.',
        'Sænk vægten hvis teknik eller kontrol bryder sammen.',
        'Brug konservativ progression fra uge til uge.',
        'Ved skader, sygdom eller usikkerhed: få individuel faglig vurdering.',
      ],
    );
  }

  List<WarmupStep> _buildWarmup(TrainingProfile profile) {
    final List<WarmupStep> base = <WarmupStep>[
      const WarmupStep(title: 'Let pulsopvarmning', durationOrReps: '3-5 min'),
      const WarmupStep(title: 'Knee-to-Wall Ankle Mobilization', durationOrReps: '8-10 reps/side'),
      const WarmupStep(title: 'Open Book Stretch', durationOrReps: '6-8 reps/side'),
      const WarmupStep(title: 'Specifikke opvarmningssæt i første øvelse', durationOrReps: '2-4 sæt'),
    ];

    if (profile.goal == TrainingGoal.mobility) {
      return <WarmupStep>[
        const WarmupStep(title: 'Cat-Cow', durationOrReps: '8-10 rolige reps'),
        const WarmupStep(title: 'Lat Stretch on Bench', durationOrReps: '30-40 sek'),
        const WarmupStep(title: 'Clamshell', durationOrReps: '12-15 reps/side'),
      ];
    }
    return base;
  }

  List<ExercisePrescription> _buildMainBlock(
    TrainingProfile profile,
    int exerciseCount,
    InSessionProgressionModel progressionModel,
  ) {
    final List<ExerciseKnowledgeItem> pool = _poolForProfile(profile);
    final List<ExerciseKnowledgeItem> selected = _pickExercises(profile, pool, exerciseCount);
    return selected.map((ExerciseKnowledgeItem item) {
      final _PrescriptionTemplate template = _templateFor(profile.goal, item, progressionModel);
      return ExercisePrescription(
        exerciseId: item.id,
        exerciseName: item.name,
        primaryMuscle: item.primaryMuscle,
        movementPattern: item.movementPattern,
        sets: template.sets,
        reps: template.reps,
        restSeconds: template.restSeconds,
        intensityCue: template.intensityCue,
        note: item.function,
        alternative: item.alternative,
      );
    }).toList(growable: false);
  }

  List<ExerciseKnowledgeItem> _poolForProfile(TrainingProfile profile) {
    final List<EquipmentAccess> acceptedEquipment = switch (profile.equipment) {
      EquipmentAccess.fullGym => <EquipmentAccess>[
          EquipmentAccess.fullGym,
          EquipmentAccess.dumbbells,
          EquipmentAccess.bodyweight,
          EquipmentAccess.homeGym,
        ],
      EquipmentAccess.homeGym => <EquipmentAccess>[
          EquipmentAccess.homeGym,
          EquipmentAccess.dumbbells,
          EquipmentAccess.bodyweight,
        ],
      EquipmentAccess.dumbbells => <EquipmentAccess>[
          EquipmentAccess.dumbbells,
          EquipmentAccess.bodyweight,
        ],
      EquipmentAccess.bodyweight => <EquipmentAccess>[EquipmentAccess.bodyweight],
    };

    return exerciseKnowledge
        .where((ExerciseKnowledgeItem item) => acceptedEquipment.contains(item.equipment))
        .toList(growable: false);
  }

  List<ExerciseKnowledgeItem> _pickExercises(
    TrainingProfile profile,
    List<ExerciseKnowledgeItem> pool,
    int count,
  ) {
    final List<ExerciseKnowledgeItem> ordered = <ExerciseKnowledgeItem>[];

    final List<String> preferredTags = switch (profile.goal) {
      TrainingGoal.strength => <String>['strength_main', 'strength_support', 'general_support'],
      TrainingGoal.hypertrophy => <String>['hypertrophy_main', 'hypertrophy_support', 'hypertrophy_accessory'],
      TrainingGoal.recomposition => <String>['general_main', 'general_support', 'hypertrophy_support'],
      TrainingGoal.mobility => <String>['mobility', 'mobility_support', 'rehab_friendly'],
      TrainingGoal.generalFitness => <String>['general_main', 'general_support', 'bodyweight_main'],
    };

    for (final String tag in preferredTags) {
      for (final ExerciseKnowledgeItem item in pool) {
        if (ordered.length >= count) {
          break;
        }
        if (item.tags.contains(tag) && !ordered.contains(item)) {
          ordered.add(item);
        }
      }
    }

    if (ordered.length < count) {
      for (final ExerciseKnowledgeItem item in pool) {
        if (ordered.length >= count) {
          break;
        }
        if (!ordered.contains(item)) {
          ordered.add(item);
        }
      }
    }

    return ordered.take(count).toList(growable: false);
  }

  InSessionProgressionModel _progressionModelForGoal(TrainingGoal goal) {
    return switch (goal) {
      TrainingGoal.strength => InSessionProgressionModel.topSetBackoff,
      TrainingGoal.hypertrophy => InSessionProgressionModel.doubleProgression,
      TrainingGoal.recomposition => InSessionProgressionModel.straightSets,
      TrainingGoal.mobility => InSessionProgressionModel.techniqueQuality,
      TrainingGoal.generalFitness => InSessionProgressionModel.straightSets,
    };
  }

  _PrescriptionTemplate _templateFor(
    TrainingGoal goal,
    ExerciseKnowledgeItem item,
    InSessionProgressionModel model,
  ) {
    if (model == InSessionProgressionModel.topSetBackoff && item.tags.contains('strength_main')) {
      return const _PrescriptionTemplate(
        sets: 4,
        reps: '1 top set 3-6 + 3 back-off sæt 4-6',
        restSeconds: 150,
        intensityCue: 'Top set omkring RPE 8, back-off med høj teknisk kvalitet',
      );
    }

    if (goal == TrainingGoal.hypertrophy && item.tags.contains('hypertrophy_accessory')) {
      return const _PrescriptionTemplate(
        sets: 3,
        reps: '12-20',
        restSeconds: 60,
        intensityCue: 'Afslut med 1-2 reps i reserve',
      );
    }

    if (goal == TrainingGoal.mobility || item.tags.contains('mobility')) {
      return const _PrescriptionTemplate(
        sets: 2,
        reps: '8-12 kontrollerede reps eller 30-45 sek',
        restSeconds: 45,
        intensityCue: 'Rolig tempo, stop før smerte',
      );
    }

    if (goal == TrainingGoal.strength) {
      return const _PrescriptionTemplate(
        sets: 3,
        reps: '5-8',
        restSeconds: 120,
        intensityCue: 'Hold 1-3 reps i reserve',
      );
    }

    if (goal == TrainingGoal.hypertrophy) {
      return const _PrescriptionTemplate(
        sets: 3,
        reps: '8-12',
        restSeconds: 75,
        intensityCue: 'Arbejd tæt på teknisk udmattelse med god kontrol',
      );
    }

    return const _PrescriptionTemplate(
      sets: 3,
      reps: '8-12',
      restSeconds: 90,
      intensityCue: 'Vælg vægt med ca. 1-3 reps i reserve',
    );
  }

  String _titleForProfile(TrainingProfile profile) {
    final String goal = switch (profile.goal) {
      TrainingGoal.strength => 'Styrke',
      TrainingGoal.hypertrophy => 'Muskelopbygning',
      TrainingGoal.recomposition => 'Recomposition',
      TrainingGoal.mobility => 'Mobilitet',
      TrainingGoal.generalFitness => 'Generel fitness',
    };
    final String? focus = profile.focusArea?.trim();
    if (focus == null || focus.isEmpty) {
      return 'AI $goal pas';
    }
    return 'AI $goal - $focus';
  }

  String _progressionRule(InSessionProgressionModel model) {
    return switch (model) {
      InSessionProgressionModel.topSetBackoff =>
        'Byg op til et top set. Når top set og back-off rammer målet med god teknik, øges vægten næste pas.',
      InSessionProgressionModel.doubleProgression =>
        'Hold vægten fast indtil alle sæt rammer top af rep-intervallet; øg derefter vægten minimalt.',
      InSessionProgressionModel.straightSets =>
        'Brug samme vægt på tværs af sæt. Øg først reps, derefter vægt i små spring.',
      InSessionProgressionModel.density =>
        'Bevar kvalitet og belastning, og reducer pauser gradvist når teknikken forbliver stabil.',
      InSessionProgressionModel.techniqueQuality =>
        'Progrediér via bedre ROM, kontrol og stabilitet før ekstra belastning.',
    };
  }
}

class _PrescriptionTemplate {
  const _PrescriptionTemplate({
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.intensityCue,
  });

  final int sets;
  final String reps;
  final int restSeconds;
  final String intensityCue;
}
