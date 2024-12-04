import 'package:flutter/material.dart';
import 'package:multi_window_ref_app/app/regular_window_content.dart';

class WindowMetadataContent extends StatelessWidget {
  WindowMetadataContent({required this.controller});

  WindowController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.type) {
      case WindowArchetype.regular:
        return RegularWindow(
            preferredSize: Size(400, 400),
            controller: controller as RegularWindowController,
            child: RegularWindowContent(
                window: controller as RegularWindowController));
      default:
        throw UnimplementedError(
            "The provided window type does not have an implementation");
    }
  }
}
