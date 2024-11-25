import 'package:flutter/material.dart';
import 'package:multi_window_ref_app/app/regular_window_content.dart';

class WindowMetadataContent extends StatelessWidget {
  WindowMetadataContent({required this.childWindow});

  WindowMetadata childWindow;

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (childWindow.type) {
      case WindowArchetype.regular:
        child =
            RegularWindowContent(window: childWindow as RegularWindowMetadata);
        break;
      default:
        throw UnimplementedError(
            "The provided window type does not have an implementation");
    }

    return View(
      view: childWindow.view,
      child: WindowContext(
        viewId: childWindow.view.viewId,
        child: child,
      ),
    );
  }
}
