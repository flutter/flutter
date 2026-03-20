import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radii.dart';
import '../../../../theme/app_spacing.dart';

class SetRowData {
  const SetRowData({
    required this.id,
    required this.setNumber,
    required this.previousLabel,
    required this.kg,
    required this.reps,
    this.completed = false,
  });

  final String id;
  final int setNumber;
  final String previousLabel;
  final String kg;
  final String reps;
  final bool completed;
}

class SetRow extends StatelessWidget {
  const SetRow({
    required this.data,
    this.onKgChanged,
    this.onRepsChanged,
    this.onCompletedChanged,
    super.key,
  });

  final SetRowData data;
  final ValueChanged<String>? onKgChanged;
  final ValueChanged<String>? onRepsChanged;
  final ValueChanged<bool>? onCompletedChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadii.input,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 40,
            child: Text(
              '${data.setNumber}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              data.previousLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SizedBox(
            width: 70,
            child: TextFormField(
              initialValue: data.kg,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              onChanged: onKgChanged,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(),
                hintText: 'Kg',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 70,
            child: TextFormField(
              initialValue: data.reps,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: onRepsChanged,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(),
                hintText: 'Reps',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            onTap: () => onCompletedChanged?.call(!data.completed),
            borderRadius: AppRadii.full,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.completed ? AppColors.success : AppColors.surface,
                border: Border.all(
                  color: data.completed ? AppColors.success : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: data.completed ? Colors.white : Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
