import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../../../widgets/foundation/app_card.dart';
import 'segmented_selector.dart';
import 'toggle_setting_row.dart';

class IntensityCard extends StatelessWidget {
  const IntensityCard({
    required this.selection,
    required this.onSelectionChanged,
    required this.autopilotEnabled,
    required this.onAutopilotChanged,
    super.key,
  });

  final String selection;
  final ValueChanged<String> onSelectionChanged;
  final bool autopilotEnabled;
  final ValueChanged<bool> onAutopilotChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Intensitet', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text(selection, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedSelector(
            options: const <String>['Let', 'Normal', 'Meget'],
            selected: selection,
            onSelected: onSelectionChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          ToggleSettingRow(
            label: 'Intensity Autopilot',
            value: autopilotEnabled,
            onChanged: onAutopilotChanged,
          ),
        ],
      ),
    );
  }
}
