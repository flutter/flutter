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

  Widget _buildOverlay(BuildContext context, OverlayChildLayoutInfo info) {
    final Offset childOffset = MatrixUtils.transformPoint(
      info.childPaintTransform,
      Offset.zero,
    );

    return Positioned(
      left: childOffset.dx,
      top: childOffset.dy + info.childSize.height,
      child: Align(
        alignment: .topLeft,
        child: Container(
          color: const Color(0xFFFFE57F),
          padding: const .all(8),
          child: const Text('Hello from the overlay!'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OverlayPortal.overlayChildLayoutBuilder(
        controller: _controller,
        overlayChildBuilder: _buildOverlay,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _controller.toggle,
          child: const Text('Press me'),
        ),
      ),
    );
  }
}
