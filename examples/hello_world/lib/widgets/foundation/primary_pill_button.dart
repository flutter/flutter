import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';

class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      padding: AppSpacing.pillPadding,
      minimumSize: Size(expanded ? double.infinity : 0, 56),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.full),
      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );

    if (icon == null) {
      return FilledButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 19),
      label: Text(label),
    );
  }
}
