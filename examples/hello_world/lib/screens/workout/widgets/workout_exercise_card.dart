import 'package:flutter/material.dart';

import '../../../models/active_workout_draft.dart';
import 'workout_set_row.dart';
import 'workout_ui_tokens.dart';

class WorkoutExerciseCard extends StatelessWidget {
  const WorkoutExerciseCard({
    required this.exercise,
    required this.onNameChanged,
    required this.onNotesChanged,
    required this.onAddSet,
    required this.onDeleteExercise,
    required this.onSetKgChanged,
    required this.onSetRepsChanged,
    required this.onSetCompletionChanged,
    required this.onDeleteSet,
    super.key,
  });

  final WorkoutExerciseDraft exercise;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onAddSet;
  final VoidCallback onDeleteExercise;
  final void Function(int setIndex, String value) onSetKgChanged;
  final void Function(int setIndex, String value) onSetRepsChanged;
  final void Function(int setIndex, bool value) onSetCompletionChanged;
  final void Function(int setIndex) onDeleteSet;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WorkoutUiTokens.cardBackground,
        borderRadius: BorderRadius.circular(WorkoutUiTokens.radiusCard),
        boxShadow: WorkoutUiTokens.softShadow(),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  initialValue: exercise.name,
                  onChanged: onNameChanged,
                  decoration: const InputDecoration(
                    hintText: 'Navn på øvelse',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(onPressed: onDeleteExercise, icon: const Icon(Icons.delete_outline)),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: WorkoutUiTokens.chipBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextFormField(
              initialValue: exercise.notes,
              onChanged: onNotesChanged,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Noter (valgfrit)',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const SizedBox(width: 24, child: Text('Set')),
              const Expanded(child: Text('Prev')),
              const SizedBox(width: 62, child: Text('Kg', textAlign: TextAlign.center)),
              const SizedBox(width: 8),
              const SizedBox(width: 62, child: Text('Reps', textAlign: TextAlign.center)),
              const SizedBox(width: 74),
            ],
          ),
          const SizedBox(height: 8),
          for (int index = 0; index < exercise.sets.length; index)
            WorkoutSetRow(
              key: ValueKey<String>('${exercise.id}-${exercise.sets[index].id}'),
              set: exercise.sets[index],
              onKgChanged: (String value) => onSetKgChanged(index, value),
              onRepsChanged: (String value) => onSetRepsChanged(index, value),
              onCompletionChanged: (bool value) => onSetCompletionChanged(index, value),
              onDelete: () => onDeleteSet(index),
            ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: onAddSet,
            icon: const Icon(Icons.add),
            label: const Text('Tilføj set'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
