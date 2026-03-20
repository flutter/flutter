import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../../../widgets/foundation/app_card.dart';
import 'segmented_selector.dart';

class CrowdCard extends StatelessWidget {
  const CrowdCard({
    required this.selection,
    required this.onSelectionChanged,
    super.key,
  });

  final String selection;
  final ValueChanged<String> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Crowd', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          SegmentedSelector(
            options: const <String>['Få', 'Normal', 'Mange'],
            selected: selection,
            onSelected: onSelectionChanged,
          ),
        ],
      ),
    );
  }
}
