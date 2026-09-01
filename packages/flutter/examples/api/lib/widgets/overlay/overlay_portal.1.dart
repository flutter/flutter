// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Flutter code sample for [OverlayPortal.overlayChildLayoutBuilder].

void main() => runApp(const OverlayPortalLayoutBuilderExampleApp());

class OverlayPortalLayoutBuilderExampleApp extends StatelessWidget {
  const OverlayPortalLayoutBuilderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      home: const OverlayPortalLayoutBuilderExample(),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (BuildContext context, _, _) => builder(context),
          ),
    );
  }
}

class OverlayPortalLayoutBuilderExample extends StatefulWidget {
  const OverlayPortalLayoutBuilderExample({super.key});

  @override
  State<OverlayPortalLayoutBuilderExample> createState() =>
      _OverlayPortalLayoutBuilderExampleState();
}

class _OverlayPortalLayoutBuilderExampleState
    extends State<OverlayPortalLayoutBuilderExample> {
  final OverlayPortalController _controller = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OverlayPortal.overlayChildLayoutBuilder(
        controller: _controller,
        overlayChildBuilder: (BuildContext context, OverlayChildLayoutInfo info) {
          // Translate the child widget's local coordinates to the overlay's
          // coordinate space. This assumes the child paint transform is invertible
          // (e.g., not a transform that collapses the child to a line or point),
          // otherwise the resulting childRect would contain NaN.
          final Rect childRect = MatrixUtils.transformRect(
            info.childPaintTransform,
            Offset.zero & info.childSize,
          );

          return Positioned(
            left: childRect.left,
            top: childRect.bottom,
            child: Container(
              color: const Color(0xFFFFE57F),
              padding: const .all(8),
              child: const Text('Hello from the overlay!'),
            ),
          );
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _controller.toggle,
          child: const Text('Press me'),
        ),
      ),
    );
  }
}
