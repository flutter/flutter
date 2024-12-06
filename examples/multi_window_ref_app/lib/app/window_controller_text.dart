import 'package:flutter/material.dart';

class WindowControllerText extends StatelessWidget {
  WindowControllerText({required this.controller});

  final WindowController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) {
          return Text(
            'View #${controller.view?.viewId ?? "Unknown"}\n'
            'Parent View: ${controller.parentViewId}\n'
            'Logical Size: ${controller.size?.width ?? "?"}\u00D7${controller.size?.height ?? "?"}\n'
            'DPR: ${MediaQuery.of(context).devicePixelRatio}',
            textAlign: TextAlign.center,
          );
        });
  }
}
