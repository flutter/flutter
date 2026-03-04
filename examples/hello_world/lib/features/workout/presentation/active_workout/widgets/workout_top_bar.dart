import 'package:flutter/material.dart';

import 'workout_ui_tokens.dart';

class WorkoutTopBar extends StatelessWidget {
  const WorkoutTopBar({
    required this.onMinimize,
    required this.onFinish,
    super.key,
  });

  final VoidCallback onMinimize;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _TopPillButton(label: 'Minimer', onPressed: onMinimize),
        const Spacer(),
        _TopPillButton(label: 'Afslut', onPressed: onFinish),
      ],
    );
  }
}

class _TopPillButton extends StatelessWidget {
  const _TopPillButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: WorkoutUiTokens.textPrimary,
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WorkoutUiTokens.radiusPill)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
