// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

// Used for Android and Fuchsia.
class _MountainViewPageTransition extends AnimatedWidget {
  static final FractionalOffsetTween _kTween = new FractionalOffsetTween(
    begin: FractionalOffset.bottomLeft,
    end: FractionalOffset.topLeft
  );

  _MountainViewPageTransition({
    Key key,
    Animation<double> animation,
    this.child,
  }) : super(
    key: key,
    listenable: _kTween.animate(new CurvedAnimation(
      parent: animation, // The route's linear 0.0 - 1.0 animation.
      curve: Curves.fastOutSlowIn
    )
  ));

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO(ianh): tell the transform to be un-transformed for hit testing
    return new SlideTransition(
      position: listenable,
      child: child
    );
  }
}

/// A modal route that replaces the entire screen with a material design transition.
///
/// The entrance transition for the page slides the page upwards and fades it
/// in. The exit transition is the same, but in reverse.
///
/// By default, when a modal route is replaced by another, the previous route
/// remains in memory. To free all the resources when this is not necessary, set
/// [maintainState] to false.
///
/// Specify whether the incoming page is a fullscreen modal dialog. On iOS, those
/// pages animate bottom->up rather than right->left.
class MaterialPageRoute<T> extends PageRoute<T> {
  /// Creates a page route for use in a material design app.
  MaterialPageRoute({
    this.builder,
    RouteSettings settings: const RouteSettings(),
    this.maintainState: true,
    this.fullscreenDialog: false,
  }) : super(settings: settings) {
    assert(builder != null);
    assert(opaque);
  }

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;
  final bool fullscreenDialog;

  @override
  final bool maintainState;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Color get barrierColor => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is MaterialPageRoute<dynamic>;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    if (!(nextRoute is MaterialPageRoute<dynamic>))
      return false;
    final MaterialPageRoute<dynamic> nextMaterialPageRoute = nextRoute;
    return !nextMaterialPageRoute.fullscreenDialog;
  }

  @override
  void dispose() {
    _backGestureController?.dispose();
    super.dispose();
  }

  CupertinoBackGestureController _backGestureController;

  /// Support for dismissing this route with a horizontal swipe is enabled
  /// for [TargetPlatform.iOS]. If attempts to dismiss this route might be
  /// vetoed because a [WillPopCallback] was defined for the route then the
  /// platform-specific back gesture is disabled.
  ///
  /// See also:
  ///
  ///  * [hasScopedWillPopCallback], which is true if a `willPop` callback
  ///    is defined for this route.
  @override
  NavigationGestureController startPopGesture() {
    // If attempts to dismiss this route might be vetoed, then do not
    // allow the user to dismiss the route with a swipe.
    if (hasScopedWillPopCallback)
      return null;
    if (fullscreenDialog)
      return null;
    if (controller.status != AnimationStatus.completed)
      return null;
    assert(_backGestureController == null);
    _backGestureController = new CupertinoBackGestureController(
      navigator: navigator,
      controller: controller,
    );

    controller.addStatusListener(handleBackGestureEnded);
    return _backGestureController;
  }

  void handleBackGestureEnded(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _backGestureController?.dispose();
      _backGestureController = null;
      controller.removeStatusListener(handleBackGestureEnded);
    }
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation) {
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
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation, Widget child) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      if (fullscreenDialog)
        return new CupertinoFullscreenDialogTransition(
          animation: animation,
          child: child,
        );
      else
        return new CupertinoPageTransition(
          animation: new AnimationMean(left: animation, right: forwardAnimation),
          child: child,
        );
    } else {
      return new _MountainViewPageTransition(
        animation: animation,
        child: child,
      );
    }
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
