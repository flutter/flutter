import 'package:flutter/material.dart';

import 'workout_ui_tokens.dart';

class AddExerciseButton extends StatelessWidget {
  const AddExerciseButton({
    required this.label,
    required this.onPressed,
    this.filled = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = filled
        ? FilledButton.styleFrom(
            backgroundColor: WorkoutUiTokens.primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: WorkoutUiTokens.textPrimary,
            side: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );

    return filled
        ? FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: const Icon(Icons.add),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: const Icon(Icons.add),
            label: Text(label),
          );
  }
}
