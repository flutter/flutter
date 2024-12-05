import 'package:flutter/material.dart';
import 'regular_window_content.dart';
import 'window_manager_model.dart';
import 'window_settings.dart';

class WindowControllerRender extends StatelessWidget {
  WindowControllerRender(
      {required this.controller,
      required this.onDestroyed,
      required this.windowSettings,
      required this.windowManagerModel,
      required this.key});

  final WindowController controller;
  final VoidCallback onDestroyed;
  final WindowSettings windowSettings;
  final WindowManagerModel windowManagerModel;
  final Key key;

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
                windowSettings: windowSettings,
                windowManagerModel: windowManagerModel));
      default:
        throw UnimplementedError(
            "The provided window type does not have an implementation");
    }
  }
}
