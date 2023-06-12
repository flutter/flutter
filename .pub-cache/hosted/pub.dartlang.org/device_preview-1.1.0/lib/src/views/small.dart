import 'package:device_preview/src/state/store.dart';
import 'package:device_preview/src/views/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'tool_panel/tool_panel.dart';

/// The tool layout when the screen is small.
class DevicePreviewSmallLayout extends StatelessWidget {
  /// Create a new panel from the given tools grouped as [slivers].
  const DevicePreviewSmallLayout({
    Key? key,
    required this.maxMenuHeight,
    required this.scaffoldKey,
    required this.onMenuVisibleChanged,
    required this.slivers,
  }) : super(key: key);

  /// The maximum modal menu height.
  final double maxMenuHeight;

  /// The key of the [Scaffold] that must be used to show the modal menu.
  final GlobalKey<ScaffoldState> scaffoldKey;

  /// Invoked each time the menu is shown or hidden.
  final ValueChanged<bool> onMenuVisibleChanged;

  /// The sections containing the tools.
  ///
  /// They must be [Sliver]s.
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    final toolbarTheme = context.select(
      (DevicePreviewStore store) => store.settings.toolbarTheme,
    );
    return Theme(
      data: toolbarTheme.asThemeData(),
      child: SafeArea(
        top: false,
        child: _BottomToolbar(
          showPanel: () async {
            onMenuVisibleChanged(true);
            final sheet = scaffoldKey.currentState?.showBottomSheet(
              (context) => ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: ToolPanel(
                  isModal: true,
                  slivers: slivers,
                ),
              ),
              constraints: BoxConstraints(
                maxHeight: maxMenuHeight,
              ),
              backgroundColor: Colors.transparent,
            );
            await sheet?.closed;
            onMenuVisibleChanged(false);
          },
        ),
      ),
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  const _BottomToolbar({
    Key? key,
    required this.showPanel,
  }) : super(key: key);

  final VoidCallback showPanel;

  @override
  Widget build(BuildContext context) {
    final isEnabled = context.select(
      (DevicePreviewStore store) => store.data.isEnabled,
    );
    return Material(
      child: ListTile(
        title: const Text('Device Preview'),
        onTap: isEnabled ? showPanel : null,
        leading: const Icon(Icons.tune),
        trailing: Switch(
          value: isEnabled,
          onChanged: (v) {
            final state = context.read<DevicePreviewStore>();
            state.data = state.data.copyWith(isEnabled: v);
          },
        ),
      ),
    );
  }
}
