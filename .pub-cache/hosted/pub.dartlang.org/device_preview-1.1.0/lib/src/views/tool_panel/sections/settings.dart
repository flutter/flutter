import 'package:device_preview/device_preview.dart';
import 'package:device_preview/src/state/store.dart';
import 'package:device_preview/src/views/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'section.dart';

/// All the settings for customizing the preview.
class SettingsSection extends StatelessWidget {
  /// Create a new menu section with settings for customizing the preview.
  ///
  /// The items can be hidden with [backgroundTheme], [toolsTheme] parameters.
  const SettingsSection({
    Key? key,
    this.backgroundTheme = true,
    this.toolsTheme = true,
  }) : super(key: key);

  /// Allow to edit the current background theme.
  final bool backgroundTheme;

  /// Allow to edit the current toolbar theme.
  final bool toolsTheme;

  @override
  Widget build(BuildContext context) {
    final backgroundTheme = context.select(
      (DevicePreviewStore store) => store.settings.backgroundTheme,
    );
    final toolbarTheme = context.select(
      (DevicePreviewStore store) => store.settings.toolbarTheme,
    );
    final background = backgroundTheme.asThemeData();
    final toolbar = toolbarTheme.asThemeData();
    return ToolPanelSection(
      title: 'Preview settings',
      children: [
        if (this.backgroundTheme)
          ListTile(
            key: const Key('background-theme'),
            title: const Text('Background color'),
            subtitle: Text(
              backgroundTheme == DevicePreviewBackgroundThemeData.dark
                  ? 'Dark'
                  : 'Light',
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: background.scaffoldBackgroundColor,
                border: Border.all(
                  color: toolbar.backgroundColor,
                  width: 1,
                ),
              ),
            ),
            onTap: () {
              final state = context.read<DevicePreviewStore>();
              state.settings = state.settings.copyWith(
                backgroundTheme:
                    backgroundTheme == DevicePreviewBackgroundThemeData.dark
                        ? DevicePreviewBackgroundThemeData.light
                        : DevicePreviewBackgroundThemeData.dark,
              );
            },
          ),
        if (toolsTheme)
          ListTile(
            key: const Key('toolbar-theme'),
            title: const Text('Tools theme'),
            subtitle: Text(
              toolbarTheme == DevicePreviewToolBarThemeData.dark
                  ? 'Dark'
                  : 'Light',
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: toolbar.scaffoldBackgroundColor,
                border: Border.all(
                  color: toolbar.backgroundColor,
                  width: 1,
                ),
              ),
            ),
            onTap: () {
              final state = context.read<DevicePreviewStore>();
              state.settings = state.settings.copyWith(
                toolbarTheme: toolbarTheme == DevicePreviewToolBarThemeData.dark
                    ? DevicePreviewToolBarThemeData.light
                    : DevicePreviewToolBarThemeData.dark,
              );
            },
          ),
      ],
    );
  }
}
