import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';

/// Preferencia global de tema (claro / oscuro / según sistema).
final ValueNotifier<ThemeMode> noviThemeMode =
    ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> loadSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final i = prefs.getInt(_kThemeModeKey);
  if (i != null && i >= 0 && i < ThemeMode.values.length) {
    noviThemeMode.value = ThemeMode.values[i];
  }
}

Future<void> persistThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kThemeModeKey, mode.index);
}

void cycleNoviThemeMode() {
  noviThemeMode.value = switch (noviThemeMode.value) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  };
  persistThemeMode(noviThemeMode.value);
}

IconData themeModeIcon(ThemeMode mode) => switch (mode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };

String themeModeTooltip(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'Tema: según el teléfono',
      ThemeMode.light => 'Tema: claro (tocar para oscuro)',
      ThemeMode.dark => 'Tema: oscuro (tocar para sistema)',
    };
