// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

final FractionalOffsetTween _kMaterialPageTransitionTween = new FractionalOffsetTween(
  begin: FractionalOffset.bottomLeft,
  end: FractionalOffset.topLeft
);

class _MaterialPageTransition extends AnimatedWidget {
  _MaterialPageTransition({
    Key key,
    Animation<double> animation,
    this.child
  }) : super(
    key: key,
    animation: _kMaterialPageTransitionTween.animate(animation)
  );

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO(ianh): tell the transform to be un-transformed for hit testing
    return new SlideTransition(
      position: animation,
      child: child
    );
  }
}

/// A modal route that replaces the entire screen with a material design transition.
///
/// The entrance transition for the page slides the page upwards and fades it
/// in. The exit transition is the same, but in reverse.
///
/// [MaterialApp] creates material page routes for entries in the
/// [MaterialApp.routes] map.
class MaterialPageRoute<T> extends PageRoute<T> {
  /// Creates a page route for use in a material design app.
  MaterialPageRoute({
    this.builder,
    Completer<T> completer,
    RouteSettings settings: const RouteSettings()
  }) : super(completer: completer, settings: settings) {
    assert(builder != null);
    assert(opaque);
  }

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Color get barrierColor => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> nextRoute) => false;

  @override
  Animation<double> createAnimation() {
    return new CurvedAnimation(
      parent: super.createAnimation(),
      curve: Curves.fastOutSlowIn
    );
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation) {
    Widget result = builder(context);
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
    return new _MaterialPageTransition(
      animation: animation,
      child: child
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
