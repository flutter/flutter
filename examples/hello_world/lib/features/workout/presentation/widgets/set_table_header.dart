import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';

class SetTableHeader extends StatelessWidget {
  const SetTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          SizedBox(width: 40, child: Text('SET', style: style)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('PREVIOUS', style: style)),
          SizedBox(width: 70, child: Text('KG', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(width: 70, child: Text('REPS', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(width: 34, child: Text('✓', style: style, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
