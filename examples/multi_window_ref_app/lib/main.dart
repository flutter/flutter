import 'package:flutter/material.dart';
import 'app/main_window.dart';
import 'app/window_controller_render.dart';
import 'app/positioner_settings.dart';
import 'app/window_settings.dart';
import 'app/window_manager_model.dart';

void main() {
  final RegularWindowController controller = RegularWindowController(
    size: const Size(800, 600),
    sizeConstraints: const BoxConstraints(minWidth: 640, minHeight: 480),
    title: "Multi-Window Reference Application",
  );

  final WindowSettings settings = WindowSettings();
  final PositionerSettingsModifier positionerSettingsModifier = PositionerSettingsModifier();
  final WindowManagerModel windowManagerModel = WindowManagerModel();
  windowManagerModel.add(KeyedWindowController(
      isMainWindow: true, key: UniqueKey(), controller: controller));

  runWidget(
    ListenableBuilder(
        listenable: windowManagerModel,
        builder: (BuildContext context, Widget? _) {
          final List<Widget> childViews = <Widget>[
            RegularWindow(
                controller: controller,
                child: MaterialApp(
                    home: MainWindow(
                        controller: controller,
                        settings: settings,
                        positionerSettingsModifier: positionerSettingsModifier,
                        windowManagerModel: windowManagerModel))),
          ];
          for (final KeyedWindowController controller
              in windowManagerModel.windows) {
            if (controller.parent == null && !controller.isMainWindow) {
              childViews.add(WindowControllerRender(
                controller: controller.controller,
                key: controller.key,
                windowSettings: settings,
                positionerSettingsModifier: positionerSettingsModifier,
                windowManagerModel: windowManagerModel,
                onDestroyed: () => windowManagerModel.remove(controller.key),
                onError: () => windowManagerModel.remove(controller.key),
              ));
            }
          }
          return ViewCollection(views: childViews);
        }),
  );
}
