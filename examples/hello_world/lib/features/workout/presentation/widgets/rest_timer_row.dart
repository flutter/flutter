import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radii.dart';
import '../../../../theme/app_spacing.dart';

class RestTimerRow extends StatelessWidget {
  const RestTimerRow({
    required this.label,
    this.trailingLabel,
    this.onTrailingTap,
    super.key,
  });

  final String label;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.input,
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailingLabel != null)
            TextButton(
              onPressed: onTrailingTap,
              child: Text(trailingLabel!),
            ),
        ],
      ),
    );
  }
}
