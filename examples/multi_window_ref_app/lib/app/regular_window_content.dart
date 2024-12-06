import 'package:flutter/material.dart';
import 'child_window_renderer.dart';
import 'window_controller_text.dart';
import 'window_manager_model.dart';
import 'window_settings.dart';

class RegularWindowContent extends StatelessWidget {
  const RegularWindowContent(
      {super.key,
      required this.controller,
      required this.windowSettings,
      required this.windowManagerModel});

  final RegularWindowController controller;
  final WindowSettings windowSettings;
  final WindowManagerModel windowManagerModel;

  @override
  Widget build(BuildContext context) {
    final child = Scaffold(
      appBar: AppBar(title: Text('${controller.type}')),
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
            WindowControllerText(controller: controller)
          ],
        ),
      ),
    );

    return ViewAnchor(
        view: ChildWindowRenderer(
            windowManagerModel: windowManagerModel,
            windowSettings: windowSettings,
            controller: controller),
        child: child);
  }
}
