import 'package:flutter/material.dart';

import 'workout_ui_tokens.dart';

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WorkoutUiTokens.cardPadding),
      decoration: BoxDecoration(
        color: WorkoutUiTokens.cardBackground,
        borderRadius: BorderRadius.circular(WorkoutUiTokens.radiusCard),
        boxShadow: WorkoutUiTokens.cardShadow,
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: WorkoutUiTokens.textPrimary,
                      ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
