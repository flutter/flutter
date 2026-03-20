import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class SegmentedSelector extends StatelessWidget {
  const SegmentedSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: options
          .map(
            (String option) => ButtonSegment<String>(
              value: option,
              label: Text(option),
            ),
          )
          .toList(growable: false),
      selected: <String>{selected},
      onSelectionChanged: (Set<String> selection) {
        final String value = selection.first;
        onSelected(value);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.16);
          }
          return AppColors.surface;
        }),
        foregroundColor: const WidgetStatePropertyAll(AppColors.textPrimary),
      ),
    );
  }
}
