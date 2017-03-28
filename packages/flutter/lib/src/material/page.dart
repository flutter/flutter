// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/mountain_view.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'material.dart';
import 'theme.dart';

/// A modal route that replaces the entire screen with a material design transition.
///
/// The entrance transition for the page slides the page upwards and fades it
/// in. The exit transition is the same, but in reverse.
///
/// By default, when a modal route is replaced by another, the previous route
/// remains in memory. To free all the resources when this is not necessary, set
/// [maintainState] to false.
class MaterialPageRoute<T> extends PageRoute<T> {
  /// Creates a page route for use in a material design app.
  MaterialPageRoute({
    this.builder,
    RouteSettings settings: const RouteSettings(),
    this.maintainState: true,
  }) : super(settings: settings) {
    assert(builder != null);
    assert(opaque);
  }

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

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
  void dispose() {
    _backGestureController?.dispose();
    super.dispose();
  }

  _CupertinoBackGestureController _backGestureController;

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
    if (controller.status != AnimationStatus.completed)
      return null;
    assert(_backGestureController == null);
    _backGestureController = new _CupertinoBackGestureController(
      navigator: navigator,
      controller: controller,
      onDisposed: () { _backGestureController = null; }
    );
    return _backGestureController;
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
    if (Theme.of(context).platform == TargetPlatform.iOS &&
        Navigator.of(context).userGestureInProgress) {
      return new _CupertinoPageTransition(
        animation: new AnimationMean(left: animation, right: forwardAnimation),
        child: child
      );
    } else {
      return new MountainViewPageTransition(
        animation: animation,
        child: child
      );
    }
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
