import 'package:flutter/material.dart';
import 'package:multi_window_ref_app/app/window_controller_render.dart';
import 'package:multi_window_ref_app/app/window_manager_model.dart';
import 'package:multi_window_ref_app/app/window_settings.dart';

class RegularWindowContent extends StatelessWidget {
  const RegularWindowContent(
      {super.key,
      required this.window,
      required this.windowSettings,
      required this.windowManagerModel});

  final RegularWindowController window;
  final WindowSettings windowSettings;
  final WindowManagerModel windowManagerModel;

  @override
  Widget build(BuildContext context) {
    final child = Scaffold(
      appBar: AppBar(title: Text('${window.type}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                windowManagerModel.add(KeyedWindowController(
                    controller: RegularWindowController()));
              },
              child: const Text('Create Regular Window'),
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
                listenable: window,
                builder: (BuildContext context, Widget? _) {
                  return Text(
                    'View #${window.view?.viewId ?? "Unknown"}\n'
                    'Parent View: ${window.parentViewId}\n'
                    'Logical Size: ${window.size?.width ?? "?"}\u00D7${window.size?.height ?? "?"}\n'
                    'DPR: ${MediaQuery.of(context).devicePixelRatio}',
                    textAlign: TextAlign.center,
                  );
                })
          ],
        ),
      ),
    );

    return ViewAnchor(
        view: ListenableBuilder(
            listenable: windowManagerModel,
            builder: (BuildContext context, Widget? _) {
              final List<Widget> childViews = <Widget>[];
              for (final KeyedWindowController controller
                  in windowManagerModel.windows) {
                if (controller.parent == window) {
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
            }),
        child: child);
  }
}
