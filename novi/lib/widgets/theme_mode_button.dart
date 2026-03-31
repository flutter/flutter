import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';

/// Botón que alterna sistema → claro → oscuro.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: noviThemeMode,
      builder: (context, mode, _) {
        return IconButton(
          tooltip: themeModeTooltip(mode),
          onPressed: cycleNoviThemeMode,
          icon: Icon(themeModeIcon(mode)),
        );
      },
    );
  }
}
