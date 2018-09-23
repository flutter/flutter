// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

// Fractional offset from 1/4 screen below the top to fully on screen.
final Animatable<Offset> _kBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 0.25),
  end: Offset.zero,
);

// Used for Android and Fuchsia.
class _MountainViewPageTransition extends StatelessWidget {
  _MountainViewPageTransition({
    Key key,
    @required bool fade,
    @required Animation<double> routeAnimation, // The route's linear 0.0 - 1.0 animation.
    @required this.child,
  }) : _positionAnimation = routeAnimation.drive(_kBottomUpTween.chain(_fastOutSlowInTween)),
       _opacityAnimation = fade
         ? routeAnimation.drive(_easeInTween) // Eyeballed from other Material apps.
         : const AlwaysStoppedAnimation<double>(1.0),
       super(key: key);

  static final Animatable<double> _fastOutSlowInTween = CurveTween(curve: Curves.fastOutSlowIn);
  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);

  final Animation<Offset> _positionAnimation;
  final Animation<double> _opacityAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO(ianh): tell the transform to be un-transformed for hit testing
    return SlideTransition(
      position: _positionAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: child,
      ),
    );
  }
}

/// A modal route that replaces the entire screen with a platform-adaptive
/// transition.
///
/// For Android, the entrance transition for the page slides the page upwards
/// and fades it in. The exit transition is the same, but in reverse.
///
/// The transition is adaptive to the platform and on iOS, the page slides in
/// from the right and exits in reverse. The page also shifts to the left in
/// parallax when another page enters to cover it. (These directions are flipped
/// in environments with a right-to-left reading direction.)
///
/// By default, when a modal route is replaced by another, the previous route
/// remains in memory. To free all the resources when this is not necessary, set
/// [maintainState] to false.
///
/// The `fullscreenDialog` property specifies whether the incoming page is a
/// fullscreen modal dialog. On iOS, those pages animate from the bottom to the
/// top rather than horizontally.
///
/// The type `T` specifies the return type of the route which can be supplied as
/// the route is popped from the stack via [Navigator.pop] by providing the
/// optional `result` argument.
///
/// See also:
///
///  * [CupertinoPageRoute], which this [PageRoute] delegates transition
///    animations to for iOS.
class MaterialPageRoute<T> extends PageRoute<T> {
  /// Creates a page route for use in a material design app.
  MaterialPageRoute({
    @required this.builder,
    RouteSettings settings,
    this.maintainState = true,
    bool fullscreenDialog = false,
  }) : assert(builder != null),
       super(settings: settings, fullscreenDialog: fullscreenDialog) {
    // ignore: prefer_asserts_in_initializer_lists , https://github.com/dart-lang/sdk/issues/31223
    assert(opaque);
  }

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  @override
  final bool maintainState;

  /// A delegate PageRoute to which iOS themed page operations are delegated to.
  /// It's lazily created on first use.
  CupertinoPageRoute<T> get _cupertinoPageRoute {
    assert(_useCupertinoTransitions);
    _internalCupertinoPageRoute ??= CupertinoPageRoute<T>(
      builder: builder, // Not used.
      fullscreenDialog: fullscreenDialog,
      hostRoute: this,
    );
    return _internalCupertinoPageRoute;
  }
  CupertinoPageRoute<T> _internalCupertinoPageRoute;

  /// Whether we should currently be using Cupertino transitions. This is true
  /// if the theme says we're on iOS, or if we're in an active gesture.
  bool get _useCupertinoTransitions {
    return _internalCupertinoPageRoute?.popGestureInProgress == true
        || Theme.of(navigator.context).platform == TargetPlatform.iOS;
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return previousRoute is MaterialPageRoute || previousRoute is CupertinoPageRoute;
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

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final Widget result = Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: builder(context),
    );
    assert(() {
      if (result == null) {
        throw FlutterError(
          'The builder for route "${settings.name}" returned null.\n'
          'Route builders must never return null.'
        );
      }
      return true;
    }());
    return result;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (_useCupertinoTransitions) {
      return _cupertinoPageRoute.buildTransitions(context, animation, secondaryAnimation, child);
    } else {
      return _MountainViewPageTransition(
        routeAnimation: animation,
        child: child,
        fade: true,
      );
    }
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
