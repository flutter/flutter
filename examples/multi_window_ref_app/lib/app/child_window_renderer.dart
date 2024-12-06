import 'package:flutter/material.dart';
import 'window_controller_render.dart';
import 'window_manager_model.dart';
import 'window_settings.dart';

class ChildWindowRenderer extends StatelessWidget {
  const ChildWindowRenderer(
      {required this.windowManagerModel,
      required this.windowSettings,
      required this.controller,
      super.key});

  final WindowManagerModel windowManagerModel;
  final WindowSettings windowSettings;
  final WindowController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: windowManagerModel,
        builder: (BuildContext context, Widget? _) {
          final List<Widget> childViews = <Widget>[];
          for (final KeyedWindowController controller
              in windowManagerModel.windows) {
            if (controller.parent == controller) {
              childViews.add(WindowControllerRender(
                controller: controller.controller,
                key: controller.key,
                windowSettings: windowSettings,
                windowManagerModel: windowManagerModel,
                onDestroyed: () => windowManagerModel.remove(controller),
                onError: () => windowManagerModel.remove(controller),
              ));
            }
          }

          return ViewCollection(views: childViews);
        });
  }
}
