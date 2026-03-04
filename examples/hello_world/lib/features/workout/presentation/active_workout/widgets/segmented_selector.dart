import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'workout_ui_tokens.dart';

class SegmentedSelector<T extends Object> extends StatelessWidget {
  const SegmentedSelector({
    required this.values,
    required this.labelBuilder,
    required this.groupValue,
    required this.onValueChanged,
    super.key,
  });

  final List<T> values;
  final String Function(T value) labelBuilder;
  final T groupValue;
  final ValueChanged<T> onValueChanged;

  @override
  Widget build(BuildContext context) {
    final Map<T, Widget> children = <T, Widget>{
      for (final T value in values)
        value: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            labelBuilder(value),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
    };

    return Container(
      decoration: BoxDecoration(
        color: WorkoutUiTokens.softBlue,
        borderRadius: BorderRadius.circular(WorkoutUiTokens.radiusPill),
      ),
      padding: const EdgeInsets.all(4),
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: groupValue,
        children: children,
        thumbColor: Colors.white,
        backgroundColor: WorkoutUiTokens.softBlue,
        onValueChanged: (T? value) {
          if (value != null) {
            onValueChanged(value);
          }
        },
      ),
    );
  }
}
