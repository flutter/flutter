// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file defines basic route wrappers for use in tests for Widgets in `flutter/widgets`.

import 'package:flutter/widgets.dart';

@visibleForTesting
class TestPageRoute<T> extends PageRoute<T> {
  TestPageRoute({
    required this.builder,
    super.settings,
    super.requestFocus,
    this.maintainState = true,
    super.fullscreenDialog,
    super.allowSnapshotting = true,
    super.barrierDismissible = false,
    super.traversalEdgeBehavior,
    super.directionalTraversalEdgeBehavior,
  });

  final WidgetBuilder builder;

  @override
  final bool maintainState;

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => 'TestPageRoute barrier';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Duration get transitionDuration => Duration.zero;
}

@visibleForTesting
class TestPageRouteBuilder extends PageRouteBuilder<void> {
  TestPageRouteBuilder({required Widget child})
    : super(
        pageBuilder: (BuildContext _, Animation<double> _, Animation<double> _) {
          return child;
        },
      );
}

@visibleForTesting
class TestPage<T> extends Page<T> {
  const TestPage({
    required this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.allowSnapshotting = true,
    super.key,
    super.canPop,
    super.onPopInvoked,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final bool maintainState;
  final bool fullscreenDialog;
  final bool allowSnapshotting;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedTestPageRoute<T>(page: this, allowSnapshotting: allowSnapshotting);
  }
}

// A page-based version of _TestPageRoute.
//
// This route uses the builder from the page to build its content. This ensures
// the content is up to date after page updates.
class _PageBasedTestPageRoute<T> extends PageRoute<T> {
  _PageBasedTestPageRoute({required TestPage<T> page, super.allowSnapshotting})
    : super(settings: page) {
    assert(opaque);
  }

  TestPage<T> get _page => settings as TestPage<T>;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => '_PageBasedTestPageRoute barrier';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _page.child;
  }

  @override
  Duration get transitionDuration => Duration.zero;
}
