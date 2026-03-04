import 'package:flutter/material.dart';

import '../../../models/active_workout_draft.dart';
import 'workout_ui_tokens.dart';

class WorkoutSetRow extends StatelessWidget {
  const WorkoutSetRow({
    required this.set,
    required this.onKgChanged,
    required this.onRepsChanged,
    required this.onCompletionChanged,
    required this.onDelete,
    super.key,
  });

  final WorkoutSetDraft set;
  final ValueChanged<String> onKgChanged;
  final ValueChanged<String> onRepsChanged;
  final ValueChanged<bool> onCompletionChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: set.completed ? WorkoutUiTokens.primaryGreen.withValues(alpha: 0.10) : WorkoutUiTokens.setRowBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 24,
            child: Text(
              '${set.setNumber}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              set.previousKg != null || set.previousReps != null
                  ? '${set.previousKg?.toStringAsFixed(0) ?? '--'}kg × ${set.previousReps ?? '--'}'
                  : '--',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: WorkoutUiTokens.textSecondary),
            ),
          ),
          SizedBox(
            width: 62,
            child: TextFormField(
              initialValue: set.kg % 1 == 0 ? set.kg.toInt().toString() : set.kg.toStringAsFixed(1),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: onKgChanged,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: 'Kg'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 62,
            child: TextFormField(
              initialValue: set.reps.toString(),
              keyboardType: TextInputType.number,
              onChanged: onRepsChanged,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: 'Reps'),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => onCompletionChanged(!set.completed),
            borderRadius: BorderRadius.circular(99),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: set.completed ? WorkoutUiTokens.primaryGreen : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: set.completed ? WorkoutUiTokens.primaryGreen : Colors.black.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(Icons.check, size: 18, color: set.completed ? Colors.white : Colors.transparent),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Slet set',
          ),
        ],
      ),
    );
  }
}
