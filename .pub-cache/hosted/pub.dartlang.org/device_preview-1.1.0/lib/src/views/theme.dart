import 'package:device_preview/src/state/state.dart';
import 'package:flutter/material.dart';

extension ThemeBackgroundExtension on DevicePreviewBackgroundThemeData {
  /// Converts a [DevicePreviewBackgroundThemeData] to a [ThemeData].
  ThemeData asThemeData() {
    switch (this) {
      case DevicePreviewBackgroundThemeData.dark:
        return ThemeData.dark();
      case DevicePreviewBackgroundThemeData.light:
        return ThemeData.light();
    }
  }
}

extension ThemeToolbarExtension on DevicePreviewToolBarThemeData {
  /// Converts a [DevicePreviewToolBarThemeData] to a [ThemeData].
  ThemeData asThemeData() {
    switch (this) {
      case DevicePreviewToolBarThemeData.dark:
        final base = ThemeData.dark();
        const accentColor = Colors.white;
        return base.copyWith(
          colorScheme: const ColorScheme.dark(
            primary: accentColor,
            secondary: accentColor,
          ),
          primaryColor: accentColor,
          primaryColorDark: accentColor,
          indicatorColor: accentColor,
          toggleableActiveColor: accentColor,
          highlightColor: accentColor.withOpacity(0.1),
          sliderTheme: base.sliderTheme.copyWith(
            thumbColor: accentColor,
            activeTrackColor: accentColor.withOpacity(0.7),
            inactiveTrackColor: accentColor.withOpacity(0.12),
            activeTickMarkColor: accentColor,
            inactiveTickMarkColor: accentColor,
            overlayColor: accentColor.withOpacity(0.12),
          ),
        );
      case DevicePreviewToolBarThemeData.light:
        final base = ThemeData.light();
        const accentColor = Colors.black;
        const barColor = Color(0xFF303030);
        return base.copyWith(
          colorScheme: const ColorScheme.light(
            primary: accentColor,
            secondary: accentColor,
          ),
          primaryColor: accentColor,
          primaryColorDark: accentColor,
          indicatorColor: accentColor,
          toggleableActiveColor: accentColor,
          highlightColor: accentColor,
          appBarTheme: base.appBarTheme.copyWith(
            color: barColor,
          ),
          sliderTheme: base.sliderTheme.copyWith(
            thumbColor: accentColor,
            activeTrackColor: accentColor.withOpacity(0.7),
            inactiveTrackColor: accentColor.withOpacity(0.12),
            activeTickMarkColor: accentColor,
            inactiveTickMarkColor: accentColor,
            overlayColor: accentColor.withOpacity(0.12),
          ),
        );
    }
  }
}
