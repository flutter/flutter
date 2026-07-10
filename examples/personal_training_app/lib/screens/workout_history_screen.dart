import 'package:flutter/material.dart';
import '../models/workout.dart';
import 'package:intl/intl.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  final List<Workout> workouts;

  const WorkoutHistoryScreen({super.key, required this.workouts});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  late List<Workout> workouts;
  final Map<String, TextEditingController> feedbackControllers = {};

  String _formatWeight(double? value) {
    if (value == null) return '-';
    final rounded = value.roundToDouble();
    return (rounded - value).abs() < 0.05
        ? rounded.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  String? _normalizeRepRange(String rawInput) {
    final match = RegExp(
      r'^(\d{1,3})\s*-\s*(\d{1,3})$',
    ).firstMatch(rawInput.trim());
    if (match == null) {
      return null;
    }
    final lower = int.tryParse(match.group(1)!);
    final upper = int.tryParse(match.group(2)!);
    if (lower == null || upper == null || lower > upper) {
      return null;
    }
    return '$lower-$upper';
  }

  int _performedSetCount(Exercise exercise) {
    if (exercise.setReps != null && exercise.setReps!.isNotEmpty) {
      return exercise.setReps!.length;
    }
    if (exercise.setWeights != null && exercise.setWeights!.isNotEmpty) {
      return exercise.setWeights!.length;
    }
    return exercise.sets ?? exercise.prescribedSets ?? 0;
  }

  bool _sameWeight(double? left, double? right) {
    if (left == null && right == null) return true;
    if (left == null || right == null) return false;
    return (left - right).abs() < 0.05;
  }

  bool _hasPerformanceData(Exercise exercise) {
    if (exercise.isCardio) return false;
    return exercise.prescribedSets != null ||
        exercise.prescribedReps != null ||
        exercise.prescribedWeight != null ||
        (exercise.setReps != null && exercise.setReps!.isNotEmpty) ||
        (exercise.setWeights != null && exercise.setWeights!.isNotEmpty);
  }

  bool _exerciseHasClientChanges(Exercise exercise) {
    final plannedSets = exercise.prescribedSets;
    final plannedReps = exercise.prescribedReps;
    final plannedWeight = exercise.prescribedWeight;

    if (plannedSets != null && plannedSets != _performedSetCount(exercise)) {
      return true;
    }
    if (plannedReps != null) {
      if (exercise.reps != plannedReps) return true;
      if (exercise.setReps?.any((rep) => rep != plannedReps) ?? false) {
        return true;
      }
    }
    if (plannedWeight != null) {
      if (!_sameWeight(exercise.weight, plannedWeight)) return true;
      if (exercise.setWeights?.any(
            (weight) => !_sameWeight(weight, plannedWeight),
          ) ??
          false) {
        return true;
      }
    }
    return false;
  }

  String _plannedSummary(Exercise exercise) {
    final plannedSets = exercise.prescribedSets ?? exercise.sets;
    final plannedRepsLabel = exercise.repRange?.trim().isNotEmpty == true
        ? exercise.repRange!.trim()
        : (exercise.prescribedReps ?? exercise.reps)?.toString() ?? '-';
    final plannedWeight = exercise.prescribedWeight ?? exercise.weight;
    final weightLabel = plannedWeight == null
        ? '-'
        : '${_formatWeight(plannedWeight)} kg';
    return '${plannedSets ?? '-'} sets x $plannedRepsLabel reps @ $weightLabel';
  }

  String _performedSummary(Exercise exercise) {
    final performedSets = _performedSetCount(exercise);
    final repsLabel = exercise.reps?.toString() ?? exercise.plannedRepsLabel;
    final weightLabel = exercise.weight == null
        ? '-'
        : '${_formatWeight(exercise.weight)} kg';
    return '$performedSets sets x $repsLabel reps @ $weightLabel';
  }

  Widget _buildPerformanceSummary(Workout workout) {
    final exercises = workout.exercises.where(_hasPerformanceData).toList();
    if (exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client Changes',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFFB45309),
          ),
        ),
        const SizedBox(height: 8),
        ...exercises.map(
          (exercise) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                    if (_exerciseHasClientChanges(exercise))
                      Text(
                        'Changed',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Planned: ${_plannedSummary(exercise)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF78350F),
                    height: 1.35,
                  ),
                ),
                Text(
                  'Performed: ${_performedSummary(exercise)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF78350F),
                    height: 1.35,
                  ),
                ),
                if (exercise.setReps != null && exercise.setReps!.isNotEmpty)
                  Text(
                    'Reps by set: ${exercise.setReps!.join(' / ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF78350F),
                      height: 1.35,
                    ),
                  ),
                if (exercise.setWeights != null &&
                    exercise.setWeights!.isNotEmpty)
                  Text(
                    'Weight by set: ${exercise.setWeights!.map(_formatWeight).join(' / ')} kg',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF78350F),
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    workouts = widget.workouts.where((w) => w.isCompleted).toList();
    for (var workout in workouts) {
      feedbackControllers[workout.id] = TextEditingController(
        text: workout.feedback ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (var controller in feedbackControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showAddExerciseDialog(BuildContext context, Workout workout) {
    final nameController = TextEditingController();
    final setsController = TextEditingController();
    final repRangeController = TextEditingController();
    final weightController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Exercise'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sets',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repRangeController,
                decoration: const InputDecoration(
                  labelText: 'Rep Range',
                  hintText: 'e.g., 8-12',
                  helperText: 'Guide: Strength 3-6, Hypertrophy 8-12, Endurance 12-20',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final setsText = setsController.text.trim();
              final repRangeText = repRangeController.text.trim();
              final weightText = weightController.text.trim();

              if (name.isEmpty ||
                  setsText.isEmpty ||
                  repRangeText.isEmpty ||
                  weightText.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                  ),
                );
                return;
              }

              try {
                final sets = int.parse(setsText);
                final repRange = _normalizeRepRange(repRangeText);
                final reps = Exercise.repsFromRange(repRange);
                final weight = double.parse(weightText);

                if (repRange == null || reps == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Rep range must look like 8-12')),
                  );
                  return;
                }

                final newExercise = Exercise(
                  name: name,
                  type: 'strength',
                  sets: sets,
                  reps: reps,
                  repRange: repRange,
                  weight: weight,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                );

                final updatedExercises = [...workout.exercises, newExercise];
                final updatedWorkout = workout.copyWith(
                  exercises: updatedExercises,
                );

                setState(() {
                  final index = workouts.indexWhere((w) => w.id == workout.id);
                  if (index != -1) {
                    workouts[index] = updatedWorkout;
                  }
                });

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exercise added successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Error adding exercise: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedWorkouts = List<Workout>.from(workouts)
      ..sort((a, b) => b.date.compareTo(a.date));

    final archivedByMonth = <String, List<Workout>>{};
    for (final workout in sortedWorkouts) {
      final monthKey = DateFormat('MMMM yyyy').format(workout.date);
      archivedByMonth.putIfAbsent(monthKey, () => []).add(workout);
    }

    final acknowledgedReviews = sortedWorkouts
        .where(
          (w) =>
              w.isReviewedByInstructor &&
              w.isReviewAcknowledged &&
              w.instructorReview != null &&
              w.instructorReview!.isNotEmpty,
        )
        .toList();

    Widget buildWorkoutCard(Workout workout) {
      final dateStr = DateFormat('MMM d, yyyy').format(workout.date);

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ExpansionTile(
          title: Text(workout.name),
          subtitle: Text(dateStr),
          trailing: Chip(
            label: Text('${workout.exercises.length} exercises'),
            backgroundColor: Colors.blue[100],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (workout.warmUp != null && workout.warmUp!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Warm-up',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            workout.warmUp!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (workout.coolDown != null &&
                      workout.coolDown!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cool-down',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            workout.coolDown!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Exercises',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...workout.exercises.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final exercise = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${idx + 1}. ${exercise.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Vol: ${exercise.totalVolume.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${exercise.sets} sets × ${exercise.plannedRepsLabel} reps @ ${exercise.weight} kg',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (exercise.notes != null &&
                              exercise.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Notes: ${exercise.notes}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  if (workout.exercises.any(_hasPerformanceData)) ...[
                    const SizedBox(height: 8),
                    _buildPerformanceSummary(workout),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddExerciseDialog(context, workout),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Exercise'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Total Sets',
                        value: '${workout.totalSets}',
                      ),
                      _StatItem(
                        label: 'Total Reps',
                        value: '${workout.totalReps}',
                      ),
                      _StatItem(
                        label: 'Total Volume',
                        value:
                            '${workout.estimatedVolume.toStringAsFixed(0)} kg',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Feedback & Comments',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: feedbackControllers[workout.id],
                    maxLines: 3,
                    onChanged: (value) {
                      // Feedback can be updated and saved
                    },
                    decoration: InputDecoration(
                      hintText:
                          'Add your feedback or comments about this workout...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (acknowledgedReviews.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acknowledged Reviews',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                ...acknowledgedReviews
                    .take(5)
                    .map(
                      (workout) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${workout.name} • ${DateFormat('MMM d, yyyy').format(workout.date)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
        ...archivedByMonth.entries.expand((entry) {
          final monthLabel = entry.key;
          final monthWorkouts = entry.value;

          return [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Row(
                children: [
                  Text(
                    monthLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${monthWorkouts.length})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            ...monthWorkouts.map(buildWorkoutCard),
          ];
        }),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
