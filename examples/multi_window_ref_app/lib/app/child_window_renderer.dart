import 'package:flutter/material.dart';
import 'positioner_settings.dart';
import 'window_controller_render.dart';
import 'window_manager_model.dart';
import 'window_settings.dart';

class ChildWindowRenderer extends StatelessWidget {
  const ChildWindowRenderer(
      {required this.windowManagerModel,
      required this.windowSettings,
      required this.positionerSettingsModifier,
      required this.controller,
      super.key});

  final WindowManagerModel windowManagerModel;
  final WindowSettings windowSettings;
  final PositionerSettingsModifier positionerSettingsModifier;
  final WindowController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: windowManagerModel,
        builder: (BuildContext context, Widget? _) {
          final List<Widget> childViews = <Widget>[];
          for (final KeyedWindowController child
              in windowManagerModel.windows) {
            if (child.parent == controller && !child.isMainWindow) {
              childViews.add(WindowControllerRender(
                controller: child.controller,
                key: child.key,
                windowSettings: windowSettings,
                positionerSettingsModifier: positionerSettingsModifier,
                windowManagerModel: windowManagerModel,
                onDestroyed: () => windowManagerModel.remove(child.key),
                onError: () => windowManagerModel.remove(child.key),
              ));
            }
          }

          return ViewCollection(views: childViews);
        });
  }
}
