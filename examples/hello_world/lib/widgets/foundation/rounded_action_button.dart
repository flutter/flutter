import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';

class RoundedActionButton extends StatelessWidget {
  const RoundedActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final Color background = isPrimary ? AppColors.primary : AppColors.surfaceSoft;
    final Color foreground = isPrimary ? AppColors.onPrimary : AppColors.textPrimary;

    final Widget child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size(112, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
        side: isPrimary ? null : BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      child: child,
    );
  }
}
