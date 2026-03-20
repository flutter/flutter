import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../../../widgets/foundation/app_card.dart';

class VolumeCard extends StatelessWidget {
  const VolumeCard({
    required this.completedSets,
    required this.totalSets,
    super.key,
  });

  final int completedSets;
  final int totalSets;

  @override
  Widget build(BuildContext context) {
    final double progress = totalSets == 0 ? 0 : (completedSets / totalSets).clamp(0, 1);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Volumen', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text('$completedSets/$totalSets sæt', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(99)),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Progression mod målet',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
