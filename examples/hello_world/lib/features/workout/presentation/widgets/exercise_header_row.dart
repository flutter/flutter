import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';

class ExerciseHeaderAction {
  const ExerciseHeaderAction({
    required this.icon,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
}

class ExerciseHeaderRow extends StatelessWidget {
  const ExerciseHeaderRow({
    required this.name,
    this.leadingIcon = Icons.fitness_center,
    this.actions = const <ExerciseHeaderAction>[],
    super.key,
  });

  final String name;
  final IconData leadingIcon;
  final List<ExerciseHeaderAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(leadingIcon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (actions.isNotEmpty)
          Wrap(
            spacing: AppSpacing.xs,
            children: actions
                .map(
                  (ExerciseHeaderAction action) => IconButton(
                    onPressed: action.onTap,
                    tooltip: action.tooltip,
                    icon: Icon(action.icon, size: 20, color: AppColors.textSecondary),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}
