// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

import 'page_transitions_theme.dart';
import 'theme.dart';

/// A modal route that replaces the entire screen with a platform-adaptive
/// transition.
///
/// {@macro flutter.material.materialRouteTransitionMixin}
///
/// By default, when a modal route is replaced by another, the previous route
/// remains in memory. To free all the resources when this is not necessary, set
/// [maintainState] to false.
///
/// The `fullscreenDialog` property specifies whether the incoming route is a
/// fullscreen modal dialog. On iOS, those routes animate from the bottom to the
/// top rather than horizontally.
///
/// The type `T` specifies the return type of the route which can be supplied as
/// the route is popped from the stack via [Navigator.pop] by providing the
/// optional `result` argument.
///
/// See also:
///
///  * [MaterialRouteTransitionMixin], which provides the material transition
///    for this route.
///  * [MaterialPage], which is a [Page] of this class.
class MaterialPageRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  /// Construct a MaterialPageRoute whose contents are defined by [builder].
  ///
  /// The values of [builder], [maintainState], and [PageRoute.fullscreenDialog]
  /// must not be null.
  MaterialPageRoute({
    required this.builder,
    super.settings,
    this.maintainState = true,
    super.fullscreenDialog,
  }) {
    assert(opaque);
  }

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  final bool maintainState;

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}


/// A mixin that provides platform-adaptive transitions for a [PageRoute].
///
/// {@template flutter.material.materialRouteTransitionMixin}
/// For Android, the entrance transition for the page zooms in and fades in
/// while the exiting page zooms out and fades out. The exit transition is similar,
/// but in reverse.
///
/// For iOS, the page slides in from the right and exits in reverse. The page
/// also shifts to the left in parallax when another page enters to cover it.
/// (These directions are flipped in environments with a right-to-left reading
/// direction.)
/// {@endtemplate}
///
/// See also:
///
///  * [PageTransitionsTheme], which specifies the [PageTransitionsBuilder] to use
///    on different platforms to define the transition durations, barrier colors,
///    ignore pointer behavior for the route.
///  * [NoAnimationPageTransitionsBuilder], which is the default page transition used
///    by the [PageTransitionsTheme].
///  * [ZoomPageTransitionsBuilder], which defines the default page transition used
///    by the [PageTransitionsTheme] for [TargetPlatform.android] and [TargetPlatform.fuchsia].
///  * [CupertinoPageTransitionsBuilder], which defines the default page transition
///    used by the [PageTransitionsTheme] for [TargetPlatform.iOS].
mixin MaterialRouteTransitionMixin<T> on PageRoute<T> {
  /// Builds the primary contents of the route.
  @protected
  Widget buildContent(BuildContext context);

  @override
  Duration get transitionDuration => _pageTransitionsBuilder.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _pageTransitionsBuilder.reverseTransitionDuration;

  @override
  bool get ignorePointerDuringTransitions => _pageTransitionsBuilder.ignorePointerDuringTransitions;

  @override
  Color? get barrierColor => _pageTransitionsBuilder.getBarrierColor(this);

  @override
  String? get barrierLabel => null;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return (nextRoute is MaterialRouteTransitionMixin && !nextRoute.fullscreenDialog)
      || (nextRoute is CupertinoRouteTransitionMixin && !nextRoute.fullscreenDialog);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget result = buildContent(context);
    assert(() {
      if (result == null) {
        throw FlutterError(
          'The builder for route "${settings.name}" returned null.\n'
          'Route builders must never return null.',
        );
      }
      return true;
    }());
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: result,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return _pageTransitionsBuilder.buildTransitions<T>(this, context, animation, secondaryAnimation, child);
  }

  PageTransitionsBuilder get _pageTransitionsBuilder {
    final BuildContext context = navigator!.context;
    return Theme.of(context).pageTransitionsTheme.getBuilder(this, context);
  }
}

/// A page that creates a material style [PageRoute].
///
/// {@macro flutter.material.materialRouteTransitionMixin}
///
/// By default, when the created route is replaced by another, the previous
/// route remains in memory. To free all the resources when this is not
/// necessary, set [maintainState] to false.
///
/// The `fullscreenDialog` property specifies whether the created route is a
/// fullscreen modal dialog. On iOS, those routes animate from the bottom to the
/// top rather than horizontally.
///
/// The type `T` specifies the return type of the route which can be supplied as
/// the route is popped from the stack via [Navigator.transitionDelegate] by
/// providing the optional `result` argument to the
/// [RouteTransitionRecord.markForPop] in the [TransitionDelegate.resolve].
///
/// See also:
///
///  * [MaterialPageRoute], which is the [PageRoute] version of this class
class MaterialPage<T> extends Page<T> {
  /// Creates a material page.
  const MaterialPage({
    required this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
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

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedMaterialPageRoute<T>(page: this);
  }
}

// A page-based version of MaterialPageRoute.
//
// This route uses the builder from the page to build its content. This ensures
// the content is up to date after page updates.
class _PageBasedMaterialPageRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  _PageBasedMaterialPageRoute({
    required MaterialPage<T> page,
  }) : super(settings: page) {
    assert(opaque);
  }

  MaterialPage<T> get _page => settings as MaterialPage<T>;

  @override
  Widget buildContent(BuildContext context) {
    return _page.child;
  }

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}
