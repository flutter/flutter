import 'package:flutter/material.dart';
import '../models/workout.dart';
import 'package:intl/intl.dart';
import '../utils/firebase_service.dart';

class TrainingCalendar extends StatefulWidget {
  final List<Workout> workouts;
  final List<DateTime>? restDays;
  final bool isInstructor;
  final String? clientUsername;
  final bool useIsoWeek;

  const TrainingCalendar({
    super.key,
    required this.workouts,
    this.restDays,
    this.isInstructor = false,
    this.clientUsername,
    this.useIsoWeek = false,
  });

  @override
  State<TrainingCalendar> createState() => _TrainingCalendarState();
}

class _TrainingCalendarState extends State<TrainingCalendar> {
  DateTime _currentMonth = DateTime.now();

  String _canonicalClientValue(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll('micheal', 'michael')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _formatWeight(double? value) {
    if (value == null) return '-';
    final rounded = value.roundToDouble();
    return (rounded - value).abs() < 0.05
        ? rounded.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  String _formatDistance(double value) {
    final rounded = value.roundToDouble();
    return (rounded - value).abs() < 0.05
        ? rounded.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  String _dateKey(DateTime date) {
    // Stable local date key used for calendar grouping.
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _exerciseCalendarDetails(Exercise exercise) {
    final details = <String>[];
    if (exercise.sets != null) {
      details.add('${exercise.sets} sets');
    }

    final repsLabel = exercise.plannedRepsLabel;
    if (repsLabel != '-') {
      details.add('$repsLabel reps');
    }

    if (exercise.weight != null && exercise.weight! > 0) {
      details.add('${_formatWeight(exercise.weight)} kg');
    }

    if (exercise.durationMinutes != null) {
      details.add('${exercise.durationMinutes} min');
    }

    if (exercise.distanceKm != null) {
      details.add('${_formatDistance(exercise.distanceKm!)} km');
    }

    if (details.isEmpty) {
      return 'No exercise details';
    }

    return details.join(' • ');
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

  List<Exercise> _performanceExercises(Workout workout) {
    return workout.exercises.where((exercise) {
      if (exercise.isCardio) return false;
      return exercise.prescribedSets != null ||
          exercise.prescribedReps != null ||
          exercise.prescribedWeight != null ||
          (exercise.setReps != null && exercise.setReps!.isNotEmpty) ||
          (exercise.setWeights != null && exercise.setWeights!.isNotEmpty);
    }).toList();
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

  Widget _buildClientChangesSection(Workout workout) {
    final exercises = _performanceExercises(workout);
    if (exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Client Changes:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFFB45309),
          ),
        ),
        const SizedBox(height: 6),
        ...exercises.map(
          (exercise) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                    if (_exerciseHasClientChanges(exercise))
                      const Text(
                        'Changed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Planned: ${_plannedSummary(exercise)}',
                  style: const TextStyle(
                    color: Color(0xFF78350F),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                Text(
                  'Performed: ${_performedSummary(exercise)}',
                  style: const TextStyle(
                    color: Color(0xFF78350F),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (exercise.setReps != null && exercise.setReps!.isNotEmpty)
                  Text(
                    'Reps by set: ${exercise.setReps!.join(' / ')}',
                    style: const TextStyle(
                      color: Color(0xFF78350F),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                if (exercise.setWeights != null &&
                    exercise.setWeights!.isNotEmpty)
                  Text(
                    'Weight by set: ${exercise.setWeights!.map(_formatWeight).join(' / ')} kg',
                    style: const TextStyle(
                      color: Color(0xFF78350F),
                      fontSize: 12,
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

  List<DateTime> _getDaysInMonth(DateTime month) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    return List.generate(
      daysInMonth,
      (i) => DateTime(month.year, month.month, i + 1),
    );
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  Future<void> _showEditWorkoutDialog(Workout workout) async {
    final nameController = TextEditingController(text: workout.name);
    final date = ValueNotifier<DateTime>(workout.date);
    final type = ValueNotifier<String>(workout.type);
    final notesController = TextEditingController(text: workout.notes ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Workout'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Workout Name'),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<DateTime>(
                valueListenable: date,
                builder: (context, value, _) => Row(
                  children: [
                    Expanded(
                      child: Text('Date: ${DateFormat('yMMMd').format(value)}'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: value,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) date.value = picked;
                      },
                      child: Text('Change'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<String>(
                valueListenable: type,
                builder: (context, value, _) => DropdownButtonFormField<String>(
                  initialValue: value,
                  items: const [
                    DropdownMenuItem(
                      value: 'strength',
                      child: Text('Strength'),
                    ),
                    DropdownMenuItem(value: 'cardio', child: Text('Cardio')),
                    DropdownMenuItem(value: 'hiit', child: Text('HIIT')),
                    DropdownMenuItem(value: 'circuit', child: Text('Circuit')),
                    DropdownMenuItem(
                      value: 'flexibility',
                      child: Text('Flexibility'),
                    ),
                  ],
                  onChanged: (v) => type.value = v ?? 'strength',
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                minLines: 1,
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (result == true) {
      final updatedWorkout = workout.copyWith(
        name: nameController.text.trim(),
        date: date.value,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
      final clientUid = await FirebaseService.getUidForUsername(
        updatedWorkout.clientUsername,
      );
      await FirebaseService.saveWorkout(updatedWorkout.id, {
        'id': updatedWorkout.id,
        'name': updatedWorkout.name,
        'date': updatedWorkout.date.toIso8601String(),
        'exercises': updatedWorkout.exercises.map((e) => e.toJson()).toList(),
        'clientName': updatedWorkout.clientName,
        'clientUsername': updatedWorkout.clientUsername,
        'clientUid': clientUid ?? '',
        'isCompleted': updatedWorkout.isCompleted,
        'isReviewedByInstructor': updatedWorkout.isReviewedByInstructor,
        'isReviewAcknowledged': updatedWorkout.isReviewAcknowledged,
        'type': updatedWorkout.type,
        'notes': updatedWorkout.notes,
      });
      if (mounted) {
        setState(() {
          final idx = widget.workouts.indexWhere(
            (w) => w.id == updatedWorkout.id,
          );
          if (idx != -1) widget.workouts[idx] = updatedWorkout;
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Workout updated.')));
    }
  }

  Future<void> _showReviewDialog(Workout workout) async {
    final reviewController = TextEditingController(
      text: workout.instructorReview ?? '',
    );
    bool sendConfetti = false;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setReviewState) => AlertDialog(
          title: Text('Review: ${workout.name}'),
          content: SizedBox(
            width: 350,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (workout.feedback != null &&
                      workout.feedback!.trim().isNotEmpty) ...[
                    const Text(
                      'Client Review:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFF7C3AED).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xFF7C3AED).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        workout.feedback!,
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (workout.isCompleted &&
                      _performanceExercises(workout).isNotEmpty) ...[
                    _buildClientChangesSection(workout),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Your Review:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reviewController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write feedback for your client...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      StatefulBuilder(
                        builder: (_, setCheckState) => Checkbox(
                          value: sendConfetti,
                          onChanged: (v) {
                            setReviewState(() => sendConfetti = v ?? false);
                          },
                        ),
                      ),
                      const Text('Send with confetti 🎉'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.rate_review),
              label: const Text('Submit Review'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );

    if (submitted == true && mounted) {
      final reviewText = reviewController.text.trim();
      final updatedWorkout = workout.copyWith(
        isReviewedByInstructor: true,
        instructorReview: reviewText,
      );
      final clientUid = await FirebaseService.getUidForUsername(
        updatedWorkout.clientUsername,
      );
      await FirebaseService.saveWorkout(updatedWorkout.id, {
        'id': updatedWorkout.id,
        'name': updatedWorkout.name,
        'date': updatedWorkout.date.toIso8601String(),
        'exercises': updatedWorkout.exercises.map((e) => e.toJson()).toList(),
        'clientName': updatedWorkout.clientName,
        'clientUsername': updatedWorkout.clientUsername,
        'clientUid': clientUid ?? '',
        'isCompleted': updatedWorkout.isCompleted,
        'isReviewedByInstructor': true,
        'instructorReview': reviewText,
        'isReviewAcknowledged': updatedWorkout.isReviewAcknowledged,
        'feedback': updatedWorkout.feedback,
        'type': updatedWorkout.type,
        'notes': updatedWorkout.notes,
      });
      final notifTarget = updatedWorkout.clientUsername.isNotEmpty
          ? updatedWorkout.clientUsername
          : updatedWorkout.clientName;
      await FirebaseService.sendNotification(
        notifTarget,
        'Your instructor reviewed your workout "${updatedWorkout.name}"!',
        celebration: sendConfetti,
      );
      if (mounted) {
        setState(() {
          final idx = widget.workouts.indexWhere(
            (w) => w.id == updatedWorkout.id,
          );
          if (idx != -1) widget.workouts[idx] = updatedWorkout;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Review submitted!'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    reviewController.dispose();
  }

  Future<void> _showViewWorkoutDialog(
    List<Workout> workouts,
    DateTime day,
  ) async {
    final expandedWorkoutIds = <String>{};
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Workouts for ${DateFormat('yMMMd').format(day)}'),
          content: SizedBox(
            width: 350,
            child: workouts.isEmpty
                ? Text('No workouts for this day.')
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: workouts.map((w) {
                        final isExpanded = expandedWorkoutIds.contains(w.id);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(w.name),
                                subtitle: Text(w.type),
                                onTap: () {
                                  setDialogState(() {
                                    if (isExpanded) {
                                      expandedWorkoutIds.remove(w.id);
                                    } else {
                                      expandedWorkoutIds.add(w.id);
                                    }
                                  });
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (w.notes != null && w.notes!.isNotEmpty)
                                      const Icon(
                                        Icons.sticky_note_2,
                                        color: Color(0xFF2563EB),
                                        size: 18,
                                      ),
                                    Icon(
                                      isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: const Color(0xFF6B7280),
                                    ),
                                    if (widget.isInstructor) ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Color(0xFF10B981),
                                        ),
                                        tooltip: 'Edit Workout',
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          await _showEditWorkoutDialog(w);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Color(0xFFEF4444),
                                        ),
                                        tooltip: 'Delete Workout',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                'Delete Workout',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this workout?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(true),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFEF4444,
                                                            ),
                                                      ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await FirebaseService.deleteWorkout(
                                              w.id,
                                            );
                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Workout deleted.',
                                                ),
                                              ),
                                            );
                                            setState(() {
                                              widget.workouts.removeWhere(
                                                (wo) => wo.id == w.id,
                                              );
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isExpanded)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    0,
                                    14,
                                    12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (w.notes != null &&
                                          w.notes!.trim().isNotEmpty) ...[
                                        Text(
                                          w.notes!,
                                          style: const TextStyle(
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      const Text(
                                        'Exercises',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ...w.exercises.map(
                                        (e) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '- ${e.name}',
                                                style: const TextStyle(
                                                  color: Color(0xFF4B5563),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                '  ${_exerciseCalendarDetails(e)}',
                                                style: const TextStyle(
                                                  color: Color(0xFF6B7280),
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (e.notes != null &&
                                                  e.notes!.trim().isNotEmpty)
                                                Text(
                                                  '  Notes: ${e.notes!.trim()}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF6B7280),
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (widget.isInstructor &&
                                          w.isCompleted) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: const [
                                            Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF10B981),
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Completed',
                                              style: TextStyle(
                                                color: Color(0xFF10B981),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (widget.isInstructor &&
                                          w.feedback != null &&
                                          w.feedback!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Client Review:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF7C3AED),
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Color(
                                              0xFF7C3AED,
                                            ).withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Color(
                                                0xFF7C3AED,
                                              ).withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            w.feedback!,
                                            style: const TextStyle(
                                              color: Color(0xFF374151),
                                              height: 1.4,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (widget.isInstructor &&
                                          w.isCompleted &&
                                          _performanceExercises(
                                            w,
                                          ).isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        _buildClientChangesSection(w),
                                      ],
                                      if (w.isReviewedByInstructor &&
                                          w.instructorReview != null &&
                                          w.instructorReview!.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          widget.isInstructor
                                              ? 'Your Review:'
                                              : 'Instructor Review:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2563EB),
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Color(
                                              0xFF2563EB,
                                            ).withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Color(
                                                0xFF2563EB,
                                              ).withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            w.instructorReview!,
                                            style: const TextStyle(
                                              color: Color(0xFF374151),
                                              height: 1.4,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ] else if (widget.isInstructor &&
                                          w.isCompleted &&
                                          !w.isReviewedByInstructor) ...[
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            icon: const Icon(
                                              Icons.rate_review,
                                              size: 16,
                                            ),
                                            label: const Text('Write Review'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFF2563EB,
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              _showReviewDialog(w);
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          actions: [
            if (workouts.isNotEmpty)
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    if (expandedWorkoutIds.length == workouts.length) {
                      expandedWorkoutIds.clear();
                    } else {
                      expandedWorkoutIds
                        ..clear()
                        ..addAll(workouts.map((w) => w.id));
                    }
                  });
                },
                child: Text(
                  expandedWorkoutIds.length == workouts.length
                      ? 'Collapse all'
                      : 'Expand all',
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_currentMonth);
    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);
    final Map<String, List<Workout>> workoutsByDate = {};
    // Workouts are already scoped before being passed into this widget.
    // Re-filtering here can hide legacy records that still belong to the client.
    final filteredWorkouts = widget.workouts;
    for (final workout in filteredWorkouts) {
      final dateKey = _dateKey(workout.date);
      workoutsByDate.putIfAbsent(dateKey, () => []).add(workout);
    }
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: _previousMonth,
                color: Color(0xFF2563EB),
              ),
              Text(
                monthName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: _nextMonth,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              // Sunday-first (existing behavior) or ISO Monday-first.
              final weekdayBase = widget.useIsoWeek ? 6 : 5;
              final weekday = DateFormat.E().format(
                DateTime(2020, 1, i + weekdayBase),
              );
              return Expanded(
                child: Center(
                  child: Text(
                    weekday,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final firstDayOfMonth = days.first;
              final int weekdayOffset = widget.useIsoWeek
                  ? (firstDayOfMonth.weekday - 1)
                  : (firstDayOfMonth.weekday % 7);
              final totalCells = days.length + weekdayOffset;
              final rows = (totalCells / 7).ceil();
              return Column(
                children: List.generate(rows, (rowIdx) {
                  return Row(
                    children: List.generate(7, (colIdx) {
                      final cellIdx = rowIdx * 7 + colIdx;
                      if (cellIdx < weekdayOffset ||
                          cellIdx >= days.length + weekdayOffset) {
                        return Expanded(child: SizedBox(height: 48));
                      }
                      final day = days[cellIdx - weekdayOffset];
                      final dateKey = _dateKey(day);
                      final isToday = DateUtils.isSameDay(day, DateTime.now());
                      final isRestDay =
                          widget.restDays?.any(
                            (d) => DateUtils.isSameDay(d, day),
                          ) ??
                          false;
                      final workouts = workoutsByDate[dateKey] ?? [];
                      return Expanded(
                        child: GestureDetector(
                          onTap: workouts.isNotEmpty
                              ? () => _showViewWorkoutDialog(workouts, day)
                              : null,
                          child: Container(
                            margin: EdgeInsets.all(2),
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Color(0xFFDBEAFE)
                                  : isRestDay
                                  ? Color(0xFFF3F4F6)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isToday
                                    ? Color(0xFF2563EB)
                                    : isRestDay
                                    ? Color(0xFFD1D5DB)
                                    : Color(0xFFE5E7EB),
                                width: isToday ? 2 : 1,
                              ),
                            ),
                            height: 48,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isToday
                                        ? Color(0xFF2563EB)
                                        : isRestDay
                                        ? Color(0xFF9CA3AF)
                                        : Color(0xFF1F2937),
                                  ),
                                ),
                                if (workouts.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: 2.0),
                                    child: Icon(
                                      Icons.fitness_center,
                                      size: 16,
                                      color: widget.isInstructor
                                          ? Color(0xFF10B981)
                                          : Color(0xFF2563EB),
                                    ),
                                  ),
                                if (isRestDay)
                                  Padding(
                                    padding: EdgeInsets.only(top: 2.0),
                                    child: Icon(
                                      Icons.hotel,
                                      size: 14,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
