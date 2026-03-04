import 'package:flutter/material.dart';

import 'workout_ui_tokens.dart';

class ActionChipButton extends StatelessWidget {
  const ActionChipButton({
    required this.label,
    this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WorkoutUiTokens.radiusPill),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: WorkoutUiTokens.chipBackground,
            borderRadius: BorderRadius.circular(WorkoutUiTokens.radiusPill),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: WorkoutUiTokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
