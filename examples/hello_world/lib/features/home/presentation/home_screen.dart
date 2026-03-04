import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../app/state/training_scope.dart';
import '../../../app/state/training_controller.dart';
import '../../../core/engine/training_profile.dart';
import '../../programs/domain/program.dart';
import '../../workout/domain/workout_template.dart';
import '../../workout/domain/exercise.dart';
import '../../workout/presentation/workout_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TrainingController controller = TrainingScope.of(context);
    final WorkoutTemplate nextWorkout = controller.nextWorkout;
    final WorkoutTemplate? activeWorkout = controller.activeWorkout;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final formattedDate = '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)}';

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerLowest),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Træning', style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: <Widget>[
                    _TopActionPill(
                      label: 'Handlinger',
                      icon: Icons.tune,
                      onTap: () => _showSmartProgrammingSheet(context, controller),
                    ),
                    const SizedBox(height: 8),
                    _TopActionPill(
                      label: 'Skift',
                      icon: Icons.grid_view_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _startWorkoutFromHome(context, controller, nextWorkout),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: colorScheme.onSurface.withValues(alpha: 0.82),
                        child: const Icon(Icons.add, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              activeWorkout == null ? 'Start tom træning' : 'Fortsæt træning',
                              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activeWorkout == null
                                  ? 'Ingen øvelser valgt endnu'
                                  : '${activeWorkout.exercises.length} øvelser i gang',
                              style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: <Widget>[
                Text('Rutines', style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  onPressed: () => _showCreateRoutineSheet(context, controller),
                  icon: const Icon(Icons.note_add_outlined),
                  tooltip: 'Tilføj',
                ),
              ],
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF24A96B), Color(0xFF4FB184)],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showCreateRoutineSheet(context, controller),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.add_circle, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Ny rutine',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...controller.programs.map(
              (program) => _RoutineRow(
                title: program.name,
                subtitle: '${program.workouts.length} workouts',
                onTap: () {
                  controller.selectProgram(program.id);
                  _startWorkoutFromHome(context, controller, controller.nextWorkout);
                },
                onEdit: () => _showCreateRoutineSheet(context, controller, existingProgram: program),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              controller.weeklyConsistencyText,
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _weekday(int weekday) {
    const names = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  String _month(int month) {
    const names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  Future<void> _showCreateRoutineSheet(
    BuildContext context,
    TrainingController controller, {
    Program? existingProgram,
  }) async {
    final WorkoutTemplate? firstWorkout =
        existingProgram != null && existingProgram.workouts.isNotEmpty ? existingProgram.workouts.first : null;

    final routineController = TextEditingController(text: existingProgram?.name ?? '');
    final workoutController = TextEditingController(text: firstWorkout?.name ?? 'Ny træning');
    final exerciseNameController = TextEditingController();
    final primaryMuscleController = TextEditingController();
    final exercises = firstWorkout == null ? <Exercise>[] : List<Exercise>.from(firstWorkout.exercises);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        final ColorScheme colorScheme = Theme.of(sheetContext).colorScheme;
        final TextTheme textTheme = Theme.of(sheetContext).textTheme;

        return StatefulBuilder(
          builder: (BuildContext innerContext, StateSetter setModalState) {
            void addExercise() {
              final String name = exerciseNameController.text.trim();
              final String muscle = primaryMuscleController.text.trim();
              if (name.isEmpty || muscle.isEmpty) {
                return;
              }
              final id = 'custom_${DateTime.now().microsecondsSinceEpoch}_${exercises.length}';
              setModalState(() {
                exercises.add(Exercise(id: id, name: name, primaryMuscle: muscle));
                exerciseNameController.clear();
                primaryMuscleController.clear();
              });
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(innerContext).viewInsets.bottom + 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(innerContext).size.height * 0.82),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Text(
                    existingProgram == null ? 'Ny rutine' : 'Rediger rutine',
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: routineController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Rutinenavn',
                      hintText: 'Fx Full body A',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: workoutController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Workout navn',
                      hintText: 'Fx Dag 1',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Tom workout', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        if (exercises.isEmpty)
                          Text(
                            'Ingen øvelser endnu. Tilføj første øvelse nedenfor.',
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                          )
                        else
                          ...exercises.map(
                            (Exercise exercise) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(exercise.name),
                              subtitle: Text(exercise.primaryMuscle),
                              trailing: IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    exercises.remove(exercise);
                                  });
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: exerciseNameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Øvelse', hintText: 'Fx Squat'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: primaryMuscleController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => addExercise(),
                          decoration: const InputDecoration(labelText: 'Muskel', hintText: 'Fx Ben'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: addExercise,
                      icon: const Icon(Icons.add),
                      label: const Text('Tilføj øvelse'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: exercises.isEmpty
                          ? null
                          : () {
                              if (existingProgram == null) {
                                controller.createRoutineWithWorkout(
                                  routineName: routineController.text,
                                  workoutName: workoutController.text,
                                  exercises: List<Exercise>.from(exercises),
                                );
                                Navigator.of(innerContext).pop();
                                _startWorkoutFromHome(context, controller, controller.nextWorkout);
                              } else {
                                controller.updateRoutineWithWorkout(
                                  programId: existingProgram.id,
                                  routineName: routineController.text,
                                  workoutName: workoutController.text,
                                  exercises: List<Exercise>.from(exercises),
                                );
                                Navigator.of(innerContext).pop();
                              }
                            },
                      child: Text(existingProgram == null ? 'Opret rutine' : 'Gem ændringer'),
                    ),
                  ),
                  if (existingProgram != null) ...<Widget>[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          final bool deleted = controller.removeRoutine(existingProgram.id);
                          Navigator.of(innerContext).pop();
                          if (!deleted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Du skal have mindst én rutine.')),
                            );
                          }
                        },
                        icon: Icon(Icons.delete_outline, color: colorScheme.error),
                        label: Text(
                          'Slet rutine',
                          style: textTheme.titleMedium?.copyWith(color: colorScheme.error),
                        ),
                      ),
                    ),
                  ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

  }

  Future<void> _startWorkoutFromHome(
    BuildContext context,
    TrainingController controller,
    WorkoutTemplate workout,
  ) async {
    controller.startWorkout(workout);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Workout')),
          body: const WorkoutScreen(),
        ),
      ),
    );
  }

  Future<void> _showSmartProgrammingSheet(
    BuildContext context,
    TrainingController controller,
  ) async {
    TrainingGoal selectedGoal = TrainingGoal.hypertrophy;
    TrainingLevel selectedLevel = TrainingLevel.beginner;
    EquipmentAccess selectedEquipment = EquipmentAccess.fullGym;
    SessionDuration selectedDuration = SessionDuration.normal;
    final TextEditingController focusController = TextEditingController();
    final TextEditingController routineNameController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        final ColorScheme colorScheme = Theme.of(sheetContext).colorScheme;
        final TextTheme textTheme = Theme.of(sheetContext).textTheme;

        return StatefulBuilder(
          builder: (BuildContext innerContext, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(innerContext).viewInsets.bottom + 18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Smart Træning',
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vælg rammer, så opretter AI en enkel og progressiv rutine.',
                      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<TrainingGoal>(
                      initialValue: selectedGoal,
                      decoration: const InputDecoration(labelText: 'Mål'),
                      items: TrainingGoal.values
                          .map(
                            (TrainingGoal value) => DropdownMenuItem<TrainingGoal>(
                              value: value,
                              child: Text(_goalLabel(value)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (TrainingGoal? value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() {
                          selectedGoal = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<TrainingLevel>(
                      initialValue: selectedLevel,
                      decoration: const InputDecoration(labelText: 'Niveau'),
                      items: TrainingLevel.values
                          .map(
                            (TrainingLevel value) => DropdownMenuItem<TrainingLevel>(
                              value: value,
                              child: Text(_levelLabel(value)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (TrainingLevel? value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() {
                          selectedLevel = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<EquipmentAccess>(
                      initialValue: selectedEquipment,
                      decoration: const InputDecoration(labelText: 'Udstyr'),
                      items: EquipmentAccess.values
                          .map(
                            (EquipmentAccess value) => DropdownMenuItem<EquipmentAccess>(
                              value: value,
                              child: Text(_equipmentLabel(value)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (EquipmentAccess? value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() {
                          selectedEquipment = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<SessionDuration>(
                      initialValue: selectedDuration,
                      decoration: const InputDecoration(labelText: 'Varighed'),
                      items: SessionDuration.values
                          .map(
                            (SessionDuration value) => DropdownMenuItem<SessionDuration>(
                              value: value,
                              child: Text(_durationLabel(value)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (SessionDuration? value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() {
                          selectedDuration = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: focusController,
                      decoration: const InputDecoration(
                        labelText: 'Fokusområde (valgfrit)',
                        hintText: 'Fx overkrop, ben eller core',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: routineNameController,
                      decoration: const InputDecoration(
                        labelText: 'Routinenavn (valgfrit)',
                        hintText: 'Fx Smart blok uge 1',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          final TrainingProfile profile = TrainingProfile(
                            goal: selectedGoal,
                            level: selectedLevel,
                            equipment: selectedEquipment,
                            duration: selectedDuration,
                            focusArea: focusController.text.trim(),
                          );

                          final Program program = controller.createProgramFromGeneratedPlan(
                            profile: profile,
                            routineName: routineNameController.text,
                          );

                          Navigator.of(innerContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('AI-rutine oprettet: ${program.name}'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Opret smart rutine'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    focusController.dispose();
    routineNameController.dispose();
  }

  String _goalLabel(TrainingGoal goal) {
    return switch (goal) {
      TrainingGoal.strength => 'Styrke',
      TrainingGoal.hypertrophy => 'Muskelopbygning',
      TrainingGoal.recomposition => 'Recomposition',
      TrainingGoal.mobility => 'Mobilitet',
      TrainingGoal.generalFitness => 'Generel fitness',
    };
  }

  String _levelLabel(TrainingLevel level) {
    return switch (level) {
      TrainingLevel.beginner => 'Nybegynder',
      TrainingLevel.intermediate => 'Let øvet',
      TrainingLevel.advanced => 'Øvet',
    };
  }

  String _equipmentLabel(EquipmentAccess equipment) {
    return switch (equipment) {
      EquipmentAccess.fullGym => 'Fuldt fitnesscenter',
      EquipmentAccess.dumbbells => 'Håndvægte',
      EquipmentAccess.bodyweight => 'Kropsvægt',
      EquipmentAccess.homeGym => 'Hjemmegym',
    };
  }

  String _durationLabel(SessionDuration duration) {
    return switch (duration) {
      SessionDuration.short => '20-30 min',
      SessionDuration.normal => '30-45 min',
      SessionDuration.long => '45-60 min',
    };
  }
}

class _TopActionPill extends StatelessWidget {
  const _TopActionPill({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      shape: StadiumBorder(side: BorderSide(color: colorScheme.outlineVariant)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({required this.title, required this.subtitle, required this.onTap, required this.onEdit});

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                '$title (${subtitle.split(' ').first})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant),
              tooltip: 'Rediger rutine',
            ),
          ],
        ),
      ),
    );
  }
}
