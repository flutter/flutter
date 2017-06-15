// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

// Fractional offset from 1/4 screen below the top to fully on screen.
final FractionalOffsetTween _kBottomUpTween = new FractionalOffsetTween(
  begin: FractionalOffset.bottomLeft,
  end: FractionalOffset.topLeft
);

// Used for Android and Fuchsia.
class _MountainViewPageTransition extends StatelessWidget {
  _MountainViewPageTransition({
    Key key,
    @required Animation<double> routeAnimation,
    @required this.child,
  }) : _positionAnimation = _kBottomUpTween.animate(new CurvedAnimation(
         parent: routeAnimation, // The route's linear 0.0 - 1.0 animation.
         curve: Curves.fastOutSlowIn,
       )),
       super(key: key);

  final Animation<FractionalOffset> _positionAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO(ianh): tell the transform to be un-transformed for hit testing
    return new SlideTransition(
      position: _positionAnimation,
      child: child,
    );
  }
}

/// A modal route that replaces the entire screen with a platform-adaptive transition.
///
/// For Android, the entrance transition for the page slides the page upwards and fades it
/// in. The exit transition is the same, but in reverse.
///
/// The transition is adaptive to the platform and on iOS, the page slides in from the right and
/// exits in reverse. The page also shifts to the left in parallax when another page enters to
/// cover it.
///
/// By default, when a modal route is replaced by another, the previous route
/// remains in memory. To free all the resources when this is not necessary, set
/// [maintainState] to false.
///
/// Specify whether the incoming page is a fullscreen modal dialog. On iOS, those
/// pages animate bottom->up rather than right->left.
///
/// See also:
///
///  * [CupertinoPageRoute], that this [PageRoute] delegates transition animations to for iOS.
class MaterialPageRoute<T> extends PageRoute<T> {
  /// Creates a page route for use in a material design app.
  MaterialPageRoute({
    @required this.builder,
    RouteSettings settings: const RouteSettings(),
    this.maintainState: true,
    bool fullscreenDialog: false,
  }) : assert(builder != null),
       assert(opaque),
       super(settings: settings, fullscreenDialog: fullscreenDialog);

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// A delegate PageRoute to which iOS themed page operations are delegated to.
  /// It's lazily created on first use.
  CupertinoPageRoute<T> _internalCupertinoPageRoute;
  CupertinoPageRoute<T> get _cupertinoPageRoute {
    _internalCupertinoPageRoute ??= new CupertinoPageRoute<T>(
      builder: builder, // Not used.
      fullscreenDialog: fullscreenDialog,
    );
    return _internalCupertinoPageRoute;
  }

  @override
  final bool maintainState;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Color get barrierColor => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is MaterialPageRoute<dynamic> || nextRoute is CupertinoPageRoute<dynamic>;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return (nextRoute is MaterialPageRoute && !nextRoute.fullscreenDialog)
        || (nextRoute is CupertinoPageRoute && !nextRoute.fullscreenDialog);
  }

  @override
  void dispose() {
    _internalCupertinoPageRoute?.dispose();
    super.dispose();
  }

  /// Support for dismissing this route with a horizontal swipe is enabled
  /// for [TargetPlatform.iOS]. If attempts to dismiss this route might be
  /// vetoed because a [WillPopCallback] was defined for the route then the
  /// platform-specific back gesture is disabled.
  ///
  /// See also:
  ///
  ///  * [CupertinoPageRoute] that backs the gesture for iOS.
  ///  * [hasScopedWillPopCallback], which is true if a `willPop` callback
  ///    is defined for this route.
  @override
  NavigationGestureController startPopGesture() {
    return Theme.of(navigator.context).platform == TargetPlatform.iOS
        ? _cupertinoPageRoute.startPopGestureForRoute(this)
        : null;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final Widget result = builder(context);
    assert(() {
      if (result == null) {
        throw new FlutterError(
          'The builder for route "${settings.name}" returned null.\n'
          'Route builders must never return null.'
        );
      }
      return true;
    });
    return result;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return _cupertinoPageRoute.buildTransitions(context, animation, secondaryAnimation, child);
    } else {
      return new _MountainViewPageTransition(
        routeAnimation: animation,
        child: child
      );
    }
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
