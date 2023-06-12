import 'package:device_preview/src/state/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'section.dart';

/// All the simulated accessibility settings.
class AccessibilitySection extends StatelessWidget {
  /// Create a new menu section with simulated accessibility settings.
  ///
  /// The items can be hidden with [accessibleNavigation], [invertColors],
  /// [textScalingFactor] parameters.
  const AccessibilitySection({
    Key? key,
    this.accessibleNavigation = true,
    this.invertColors = true,
    this.textScalingFactor = true,
    this.boldText = true,
  }) : super(key: key);

  /// Allow to enable accessible navigation mode.
  final bool accessibleNavigation;

  /// Allow to enable invert color mode.
  final bool invertColors;

  /// Allow to edit the current text scaling factor.
  final bool textScalingFactor;

  /// Allow to edit the current text weight.
  final bool boldText;

  @override
  Widget build(BuildContext context) {
    final textScalingFactor = context.select(
      (DevicePreviewStore store) => store.data.textScaleFactor,
    );
    final boldText = context.select(
      (DevicePreviewStore store) => store.data.boldText,
    );
    final accessibleNavigation = context.select(
      (DevicePreviewStore store) => store.data.accessibleNavigation,
    );
    final invertColors = context.select(
      (DevicePreviewStore store) => store.data.invertColors,
    );
    return ToolPanelSection(
      title: 'Accessibility',
      children: [
        if (this.accessibleNavigation)
          ListTile(
            key: const Key('accessible-navigation'),
            title: const Text('Accessible navigation'),
            subtitle: Text(accessibleNavigation ? 'Enabled' : 'Disabled'),
            trailing: Opacity(
              opacity: accessibleNavigation ? 1.0 : 0.3,
              child: Icon(
                accessibleNavigation
                    ? Icons.accessible_forward
                    : Icons.accessible_rounded,
              ),
            ),
            onTap: () {
              final state = context.read<DevicePreviewStore>();
              state.data = state.data.copyWith(
                accessibleNavigation: !accessibleNavigation,
              );
            },
          ),
        if (this.invertColors)
          ListTile(
            key: const Key('invert-colors'),
            title: const Text('Invert colors'),
            subtitle: Text(invertColors ? 'Enabled' : 'Disabled'),
            trailing: Opacity(
              opacity: invertColors ? 1.0 : 0.3,
              child: Icon(
                invertColors
                    ? Icons.format_color_reset_rounded
                    : Icons.format_color_reset_outlined,
              ),
            ),
            onTap: () {
              final state = context.read<DevicePreviewStore>();
              state.data = state.data.copyWith(
                invertColors: !invertColors,
              );
            },
          ),
        if (this.boldText)
          ListTile(
            key: const Key('bold-text'),
            title: const Text('Bold text'),
            subtitle: Text(boldText ? 'Enabled' : 'Disabled'),
            trailing: Opacity(
              opacity: boldText ? 1.0 : 0.3,
              child: const Icon(
                Icons.format_bold,
              ),
            ),
            onTap: () {
              final state = context.read<DevicePreviewStore>();
              state.data = state.data.copyWith(
                boldText: !boldText,
              );
            },
          ),
        if (this.textScalingFactor) ...[
          ListTile(
            key: const Key('text-scaling-factor'),
            title: const Text('Text scaling factor'),
            subtitle: Text(textScalingFactor.toString()),
            trailing: Transform(
              alignment: Alignment.center,
              transform: (Matrix4.identity()
                ..scale(
                  textScalingFactor >= 2
                      ? 1.0
                      : (textScalingFactor < 1 ? 0.25 : 0.6),
                )),
              child: const Icon(Icons.text_format),
            ),
          ),
          ListTile(
            key: const Key('text-scaling-slider'),
            title: Slider(
              value: textScalingFactor,
              onChanged: (v) {
                final state = context.read<DevicePreviewStore>();
                state.data = state.data.copyWith(textScaleFactor: v);
              },
              min: 0.25,
              max: 3,
              divisions: 11,
            ),
          ),
        ],
      ],
    );
  }
}
