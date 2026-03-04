import 'package:flutter/material.dart';

import 'workout_ui_tokens.dart';

class WorkoutHeaderBar extends StatelessWidget {
  const WorkoutHeaderBar({
    required this.elapsed,
    required this.onMinimize,
    required this.onFinish,
    super.key,
  });

  final String elapsed;
  final VoidCallback onMinimize;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _PillButton(label: 'Minimer', onPressed: onMinimize),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(WorkoutUiTokens.radiusPill),
            boxShadow: WorkoutUiTokens.softShadow(),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.timer_outlined, size: 18),
              const SizedBox(width: 6),
              Text(
                elapsed,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: WorkoutUiTokens.textPrimary,
                    ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _PillButton(label: 'Afslut', onPressed: onFinish),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WorkoutUiTokens.radiusPill)),
        minimumSize: const Size(84, 44),
      ),
      child: Text(label),
    );
  }
}
