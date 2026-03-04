import 'package:flutter/material.dart';

import 'workout_ui_tokens.dart';

class SetRow extends StatelessWidget {
  const SetRow({
    required this.index,
    required this.previous,
    required this.kg,
    required this.reps,
    required this.completed,
    required this.onKgChanged,
    required this.onRepsChanged,
    required this.onCompletedChanged,
    super.key,
  });

  final int index;
  final String previous;
  final String kg;
  final String reps;
  final bool completed;
  final ValueChanged<String> onKgChanged;
  final ValueChanged<String> onRepsChanged;
  final ValueChanged<bool> onCompletedChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WorkoutUiTokens.rowBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 30,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              previous,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: WorkoutUiTokens.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 54, child: _EditableCell(value: kg, hint: '--', onChanged: onKgChanged)),
          const SizedBox(width: 8),
          SizedBox(width: 54, child: _EditableCell(value: reps, hint: '--', onChanged: onRepsChanged)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onCompletedChanged(!completed),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed ? WorkoutUiTokens.accentGreen : Colors.white,
                border: Border.all(
                  color: completed ? WorkoutUiTokens.accentGreen : Colors.black.withValues(alpha: 0.16),
                  width: 1.6,
                ),
              ),
              child: Icon(
                Icons.check_rounded,
                color: completed ? Colors.white : Colors.transparent,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableCell extends StatelessWidget {
  const _EditableCell({
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      alignment: Alignment.center,
      child: TextFormField(
        initialValue: value,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
