import 'package:flutter/material.dart';
import 'package:multi_window_ref_app/app/regular_window_content.dart';
import 'package:multi_window_ref_app/app/window_settings.dart';

class WindowControllerRender extends StatelessWidget {
  WindowControllerRender(
      {required this.controller,
      required this.onDestroyed,
      required this.windowSettings,
      this.key});

  final WindowController controller;
  final VoidCallback onDestroyed;
  final WindowSettings windowSettings;
  final Key? key;

  @override
  Widget build(BuildContext context) {
    switch (controller.type) {
      case WindowArchetype.regular:
        return RegularWindow(
            key: key,
            onDestroyed: onDestroyed,
            preferredSize: windowSettings.regularSize,
            controller: controller as RegularWindowController,
            child: RegularWindowContent(
                window: controller as RegularWindowController,
                windowSettings: windowSettings));
      default:
        throw UnimplementedError(
            "The provided window type does not have an implementation");
    }
  }
}
