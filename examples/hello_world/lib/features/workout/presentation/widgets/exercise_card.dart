import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../widgets/foundation/app_card.dart';
import 'add_set_button.dart';
import 'exercise_header_row.dart';
import 'exercise_tag_chips.dart';
import 'rest_timer_row.dart';
import 'set_row.dart';
import 'set_table_header.dart';

class ExerciseCardData {
  const ExerciseCardData({
    required this.id,
    required this.name,
    required this.sets,
    this.leadingIcon = Icons.fitness_center,
    this.tags = const <String>[],
    this.notes,
    this.restLabel = 'Pause mellem sæt: 2m',
    this.actions = const <ExerciseHeaderAction>[],
  });

  final String id;
  final String name;
  final IconData leadingIcon;
  final List<ExerciseHeaderAction> actions;
  final List<String> tags;
  final String? notes;
  final String restLabel;
  final List<SetRowData> sets;
}

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    required this.data,
    required this.onAddSet,
    this.onRestInsightsTap,
    this.onKgChanged,
    this.onRepsChanged,
    this.onSetCompletedChanged,
    super.key,
  });

  final ExerciseCardData data;
  final VoidCallback onAddSet;
  final VoidCallback? onRestInsightsTap;
  final void Function(String setId, String value)? onKgChanged;
  final void Function(String setId, String value)? onRepsChanged;
  final void Function(String setId, bool value)? onSetCompletedChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExerciseHeaderRow(
            name: data.name,
            leadingIcon: data.leadingIcon,
            actions: data.actions,
          ),
          const SizedBox(height: AppSpacing.md),
          ExerciseTagChips(tags: data.tags),
          if (data.tags.isNotEmpty) const SizedBox(height: AppSpacing.md),
          if (data.notes != null && data.notes!.isNotEmpty) ...<Widget>[
            Text(
              data.notes!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          RestTimerRow(
            label: data.restLabel,
            trailingLabel: 'Vis indsigt',
            onTrailingTap: onRestInsightsTap,
          ),
          const SizedBox(height: AppSpacing.md),
          const SetTableHeader(),
          for (final SetRowData set in data.sets)
            SetRow(
              key: ValueKey<String>('${data.id}-${set.id}'),
              data: set,
              onKgChanged: (String value) => onKgChanged?.call(set.id, value),
              onRepsChanged: (String value) => onRepsChanged?.call(set.id, value),
              onCompletedChanged: (bool value) => onSetCompletedChanged?.call(set.id, value),
            ),
          const SizedBox(height: AppSpacing.md),
          AddSetButton(onPressed: onAddSet),
        ],
      ),
    );
  }
}
