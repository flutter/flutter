import 'package:flutter/material.dart';

import '../../../../widgets/foundation/rounded_action_button.dart';
import '../../../../theme/app_spacing.dart';

class WorkoutHeader extends StatelessWidget {
  const WorkoutHeader({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            RoundedActionButton(
              label: 'Minimer',
              onPressed: onMinimize,
            ),
            const Spacer(),
            RoundedActionButton(
              label: 'Afslut',
              onPressed: onFinish,
              isPrimary: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Forløbet',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          elapsed,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
