import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../../../widgets/foundation/app_card.dart';
import '../../../../widgets/foundation/rounded_action_button.dart';
import 'exercise_tag_chips.dart';
import 'toggle_setting_row.dart';

class DurationCard extends StatelessWidget {
  const DurationCard({
    required this.durationMinutes,
    required this.onDurationChanged,
    required this.onDecrease,
    required this.onIncrease,
    required this.autopilotEnabled,
    required this.onAutopilotChanged,
    required this.tags,
    super.key,
  });

  final int durationMinutes;
  final ValueChanged<double> onDurationChanged;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final bool autopilotEnabled;
  final ValueChanged<bool> onAutopilotChanged;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Varighed', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text('$durationMinutes min', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          Slider(
            value: durationMinutes.toDouble(),
            min: 15,
            max: 120,
            divisions: 21,
            label: '$durationMinutes',
            onChanged: onDurationChanged,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              RoundedActionButton(label: '-5', onPressed: onDecrease),
              const SizedBox(width: AppSpacing.sm),
              RoundedActionButton(label: '+5', onPressed: onIncrease),
              const Spacer(),
              Text('Mål: $durationMinutes min', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ExerciseTagChips(tags: tags),
          const SizedBox(height: AppSpacing.lg),
          ToggleSettingRow(
            label: 'Time Budget Autopilot',
            value: autopilotEnabled,
            onChanged: onAutopilotChanged,
          ),
        ],
      ),
    );
  }
}
