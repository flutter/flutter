import 'package:flutter/material.dart';

class WorkoutUiTokens {
  static const Color pageBackground = Color(0xFFF5F6F8);
  static const Color cardBackground = Colors.white;
  static const Color exerciseCardBackground = Color(0xFFE5E7EB);
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color chipBackground = Color(0xFFF8FAFC);
  static const Color setRowBackground = Color(0xFFF1F5F9);

  static const double radiusCard = 22;
  static const double radiusPill = 999;

  static List<BoxShadow> softShadow() => <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}
