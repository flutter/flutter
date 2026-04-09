// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

Widget _defaultTransitionsBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return child;
}

/// A [Page] that creates a [PageRouteBuilder].
///
/// This provides a concrete, design-agnostic [Page] subclass that gives
/// developers an out-of-the-box way to use the declarative [Navigator] API
/// ([Navigator.pages]) without having to depend on `Material` or `Cupertino`
/// within widget tests.
class TestPage<T> extends Page<T> {
  /// Creates a page that delegates to a widget child.
  const TestPage({
    required this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.allowSnapshotting = true,
    this.transitionsBuilder = _defaultTransitionsBuilder,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  /// {@macro flutter.widgets.PageRoute.fullscreenDialog}
  final bool fullscreenDialog;

  /// {@macro flutter.widgets.TransitionRoute.allowSnapshotting}
  final bool allowSnapshotting;

  /// {@macro flutter.widgets.pageRouteBuilder.transitionsBuilder}
  final RouteTransitionsBuilder transitionsBuilder;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      allowSnapshotting: allowSnapshotting,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) => child,
      transitionsBuilder: transitionsBuilder,
    );
  }
}
