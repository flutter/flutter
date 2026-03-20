import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../../../widgets/foundation/app_card.dart';
import '../../../../widgets/foundation/primary_pill_button.dart';
import '../../../../widgets/foundation/rounded_action_button.dart';

class TimerCard extends StatelessWidget {
  const TimerCard({
    required this.elapsed,
    required this.pausedDurationLabel,
    required this.onPause,
    required this.onSecondaryAction,
    this.secondaryActionLabel = 'Næste',
    super.key,
  });

  final String elapsed;
  final String pausedDurationLabel;
  final VoidCallback onPause;
  final VoidCallback onSecondaryAction;
  final String secondaryActionLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Tidsmåler', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          Text(
            elapsed,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(pausedDurationLabel, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: PrimaryPillButton(
                  label: 'Pause',
                  icon: Icons.pause,
                  onPressed: onPause,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              RoundedActionButton(
                label: secondaryActionLabel,
                icon: Icons.skip_next,
                onPressed: onSecondaryAction,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
