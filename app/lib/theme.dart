import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme();

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true);
    const seed = Color(0xFF3B4CCA);
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    return base.copyWith(
      colorScheme: scheme,
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.4),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F8FB),
      cardTheme: const CardTheme(margin: EdgeInsets.zero, elevation: 0),
    );
  }
}