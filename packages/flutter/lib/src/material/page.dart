// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

class _MaterialPageTransition extends AnimatedWidget {
  _MaterialPageTransition({
    Key key,
    Animation<double> animation,
    this.child
  }) : super(
    key: key,
    animation: new CurvedAnimation(parent: animation, curve: Curves.easeOut)
  );

  final Widget child;

  final Tween<Point> _position = new Tween<Point>(
    begin: const Point(0.0, 75.0),
    end: Point.origin
  );

  @override
  Widget build(BuildContext context) {
    Point position = _position.evaluate(animation);
    Matrix4 transform = new Matrix4.identity()
      ..translate(position.x, position.y);
    return new Transform(
      transform: transform,
      // TODO(ianh): tell the transform to be un-transformed for hit testing
      child: new Opacity(
        opacity: animation.value,
        child: child
      )
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
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Color get barrierColor => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> nextRoute) => false;

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
