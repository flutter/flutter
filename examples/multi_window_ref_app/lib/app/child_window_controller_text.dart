import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ChildWindowControllerText extends StatelessWidget {
  const ChildWindowControllerText({super.key, required this.controller});

  final ChildWindowController controller;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;

    return ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) {
          return Text(
              'View #${controller.view?.viewId ?? "Unknown"}\n'
              'Parent View: ${controller.parent.viewId ?? "None"}\n'
              'View Size: ${(controller.view!.physicalSize.width / dpr).toStringAsFixed(1)}\u00D7${(controller.view!.physicalSize.height / dpr).toStringAsFixed(1)}\n'
              'Window Size: ${controller.size?.width}\u00D7${controller.size?.height}\n'
              'Device Pixel Ratio: $dpr',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ));
        });
  }
}
