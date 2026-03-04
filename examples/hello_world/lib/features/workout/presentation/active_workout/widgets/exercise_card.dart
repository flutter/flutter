import 'package:flutter/material.dart';

import '../models/active_workout_models.dart';
import 'action_chip.dart';
import 'set_row.dart';
import 'workout_ui_tokens.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    required this.exercise,
    required this.onSetCompleted,
    required this.onSetKgChanged,
    required this.onSetRepsChanged,
    required this.onNoteChanged,
    required this.onAddSet,
    super.key,
  });

  final ActiveWorkoutExercise exercise;
  final void Function(int setIndex, bool completed) onSetCompleted;
  final void Function(int setIndex, String value) onSetKgChanged;
  final void Function(int setIndex, String value) onSetRepsChanged;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onAddSet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WorkoutUiTokens.cardPadding),
      decoration: BoxDecoration(
        color: WorkoutUiTokens.cardBackground,
        borderRadius: BorderRadius.circular(WorkoutUiTokens.radiusCard),
        boxShadow: WorkoutUiTokens.cardShadow,
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WorkoutUiTokens.softBlue,
                ),
                child: const Icon(Icons.fitness_center_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: WorkoutUiTokens.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: WorkoutUiTokens.softBlue,
                  borderRadius: BorderRadius.circular(WorkoutUiTokens.radiusPill),
                ),
                child: Text(exercise.durationChip),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
                style: IconButton.styleFrom(backgroundColor: WorkoutUiTokens.chipBackground),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: exercise.quickActions
                .map((String label) => ActionChipButton(label: label, onTap: () {}))
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: WorkoutUiTokens.chipBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextFormField(
              initialValue: exercise.notes,
              onChanged: onNoteChanged,
              minLines: 1,
              maxLines: 3,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Add notes here…',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: WorkoutUiTokens.chipBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.timer_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pause mellem sæt: ${exercise.restLabel}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: WorkoutUiTokens.textSecondary),
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('Vis indsigt')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SetHeaderRow(),
          const SizedBox(height: 6),
          for (int index = 0; index < exercise.sets.length; index++)
            SetRow(
              index: index,
              previous: exercise.sets[index].previous,
              kg: exercise.sets[index].kg,
              reps: exercise.sets[index].reps,
              completed: exercise.sets[index].completed,
              onKgChanged: (String value) => onSetKgChanged(index, value),
              onRepsChanged: (String value) => onSetRepsChanged(index, value),
              onCompletedChanged: (bool done) => onSetCompleted(index, done),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onAddSet,
              style: OutlinedButton.styleFrom(
                foregroundColor: WorkoutUiTokens.textPrimary,
                side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('+ Add Set'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: WorkoutUiTokens.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        );

    return Row(
      children: <Widget>[
        const SizedBox(width: 30, child: Text('SET')),
        const SizedBox(width: 10),
        Expanded(flex: 3, child: Text('PREVIOUS', style: style)),
        const SizedBox(width: 8),
        SizedBox(width: 54, child: Text('+KG', textAlign: TextAlign.center, style: style)),
        const SizedBox(width: 8),
        SizedBox(width: 54, child: Text('REPS', textAlign: TextAlign.center, style: style)),
        const SizedBox(width: 8),
        SizedBox(width: 30, child: Text('', style: style)),
      ],
    );
  }
}
