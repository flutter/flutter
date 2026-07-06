// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Flutter code sample for [CompositedTransformTarget] and [CompositedTransformFollower].

void main() => runApp(const CompositedTransformFollowerExampleApp());

class CompositedTransformFollowerExampleApp extends StatelessWidget {
  const CompositedTransformFollowerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      home: const CompositedTransformFollowerExample(),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (BuildContext context, _, _) => builder(context),
        );
      },
    );
  }
}

class CompositedTransformFollowerExample extends StatefulWidget {
  const CompositedTransformFollowerExample({super.key});

  @override
  State<CompositedTransformFollowerExample> createState() =>
      _CompositedTransformFollowerExampleState();
}

class _CompositedTransformFollowerExampleState
    extends State<CompositedTransformFollowerExample> {
  final OverlayPortalController _portalController = OverlayPortalController();
  final LayerLink _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (BuildContext context) {
          return CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            child: Align(
              alignment: .topCenter,
              child: ColoredBox(
                color: const Color(0xFFFFE57F),
                child: const Text('Hello from the overlay!'),
              ),
            ),
          );
        },
        child: CompositedTransformTarget(
          link: _link,
          child: GestureDetector(
            onTap: () => _portalController.toggle(),
            child: const Text('Press me'),
          ),
        ),
      ),
    );
  }
}
