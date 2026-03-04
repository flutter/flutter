import 'package:flutter/material.dart';

class WorkoutUiTokens {
  static const Color pageBackground = Color(0xFFF5F6F8);
  static const Color cardBackground = Colors.white;
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color rowBackground = Color(0xFFF2F6FA);
  static const Color chipBackground = Color(0xFFF7F8FA);
  static const Color softBlue = Color(0xFFEAF2FF);

  static const double radiusCard = 22;
  static const double radiusPill = 999;
  static const double radiusSmall = 14;
  static const double sidePadding = 16;
  static const double cardPadding = 16;

  static List<BoxShadow> get cardShadow => <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
