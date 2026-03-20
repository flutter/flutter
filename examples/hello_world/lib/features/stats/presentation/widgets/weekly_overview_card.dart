import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../../../widgets/foundation/app_card.dart';

class WeeklyOverviewCard extends StatelessWidget {
  const WeeklyOverviewCard({
    required this.completedSessions,
    required this.targetSessions,
    required this.progressLabel,
    super.key,
  });

  final int completedSessions;
  final int targetSessions;
  final String progressLabel;

  @override
  Widget build(BuildContext context) {
    final double progress = targetSessions == 0 ? 0 : (completedSessions / targetSessions).clamp(0, 1);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Denne uge', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$completedSessions',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('/ $targetSessions pas', style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(99)),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(progressLabel, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
