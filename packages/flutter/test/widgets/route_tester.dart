// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// A [PageRoute] for usage in tests.
///
/// This route defaults to building no transitions.
class TestRoute<T> extends PageRoute<T> {
  TestRoute({
    this.child,
    this.builder,
    RouteSettings super.settings = const RouteSettings(),
    this.barrierColor,
    this.maintainState = false,
    this.transitionDuration = Duration.zero,
    this.reverseTransitionDuration = Duration.zero,
    this.transitionsBuilder,
    super.fullscreenDialog,
    super.allowSnapshotting,
  }) : assert(child != null || builder != null, 'Either child or builder must be provided.');

  final Widget? child;
  final WidgetBuilder? builder;
  final PageTransitionsBuilder? transitionsBuilder;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  final Color? barrierColor;

  @override
  String? get barrierLabel => null;

  @override
  final bool maintainState;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child ?? builder?.call(context) ?? const SizedBox.shrink();
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (transitionsBuilder == null) {
      return child;
    }

    return transitionsBuilder!.buildTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// A [Page] that creates a [Route] with a [PageRoute.transitionDuration] set to [Duration.zero].
class ZeroTransitionPage<T> extends Page<T> {
  const ZeroTransitionPage({
    super.key,
    super.arguments,
    super.name,
    this.child,
    this.builder,
    this.allowSnapshotting = true,
  }) : assert(child != null || builder != null, 'Either child or builder must be provided.');

  final Widget? child;
  final WidgetBuilder? builder;
  final bool allowSnapshotting;

  @override
  Route<T> createRoute(BuildContext context) {
    return TestRoute(
      settings: this,
      allowSnapshotting: allowSnapshotting,
      child: child,
      builder: builder,
    );
  }
}
