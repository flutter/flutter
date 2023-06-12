import 'package:device_preview/src/state/store.dart';
import 'package:device_preview/src/views/tool_panel/sections/subsections/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'section.dart';

/// All the simulated system settings.
class SystemSection extends StatelessWidget {
  /// Create a new menu section with simulated systel properties.
  ///
  /// The items can be hidden with [locale], [theme] parameters.
  const SystemSection({
    Key? key,
    this.locale = true,
    this.theme = true,
  }) : super(key: key);

  /// Allow to select the current device locale.
  final bool locale;

  /// Allow to override the current system theme (dark/light)
  final bool theme;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select(
      (DevicePreviewStore store) => store.data.isDarkMode,
    );

    final locales = context.select(
      (DevicePreviewStore store) => store.locales,
    );

    final selectedLocale = locales.firstWhere(
      (element) =>
          element.code ==
          context.select(
            (DevicePreviewStore store) => store.data.locale,
          ),
      orElse: () => locales.first,
    );

    return ToolPanelSection(
      title: 'System',
      children: [
        if (locale)
          ListTile(
            key: const Key('locale'),
            title: const Text('Locale'),
            subtitle: Text(selectedLocale.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.language),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
            onTap: () {
              final theme = Theme.of(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Theme(
                    data: theme,
                    child: const LocalePicker(),
                  ),
                ),
              );
            },
          ),
        if (theme)
          ListTile(
            key: const Key('theme'),
            title: const Text('Theme'),
            subtitle: Text(isDarkMode ? 'Dark' : 'Light'),
            trailing: Icon(
              isDarkMode ? Icons.brightness_3 : Icons.brightness_high,
            ),
            onTap: () {
              final state = context.read<DevicePreviewStore>();
              state.toggleDarkMode();
            },
          ),
      ],
    );
  }
}
