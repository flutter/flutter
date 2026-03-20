import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextTheme textTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 40, height: 1.1, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
      headlineLarge: TextStyle(fontSize: 30, height: 1.15, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
      headlineMedium: TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
      titleLarge: TextStyle(fontSize: 20, height: 1.25, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
      titleMedium: TextStyle(fontSize: 16, height: 1.3, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
      bodySmall: TextStyle(fontSize: 12, height: 1.35, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
      labelLarge: TextStyle(fontSize: 14, height: 1.1, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
    );
  }
}
