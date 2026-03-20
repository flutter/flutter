import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radii.dart';
import '../../../../theme/app_spacing.dart';

class ExerciseTagChips extends StatelessWidget {
  const ExerciseTagChips({
    required this.tags,
    super.key,
  });

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: tags
          .map(
            (String tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.full,
                border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.label_outline, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    tag,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
