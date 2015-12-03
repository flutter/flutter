// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

class _MaterialPageTransition extends TransitionWithChild {
  _MaterialPageTransition({
    Key key,
    PerformanceView performance,
    Widget child
  }) : super(key: key,
             performance: performance,
             child: child);

  final AnimatedValue<Point> _position =
     new AnimatedValue<Point>(const Point(0.0, 75.0), end: Point.origin, curve: Curves.easeOut);

  final AnimatedValue<double> _opacity =
     new AnimatedValue<double>(0.0, end: 1.0, curve: Curves.easeOut);

  Widget buildWithChild(BuildContext context, Widget child) {
    performance.updateVariable(_position);
    performance.updateVariable(_opacity);
    Matrix4 transform = new Matrix4.identity()
      ..translate(_position.value.x, _position.value.y);
    return new Transform(
      transform: transform,
      // TODO(ianh): tell the transform to be un-transformed for hit testing
      child: new Opacity(
        opacity: _opacity.value,
        child: child
      )
    );
  }
}

const Duration kMaterialPageRouteTransitionDuration = const Duration(milliseconds: 150);

class MaterialPageRoute<T> extends PageRoute<T> {
  MaterialPageRoute({
    this.builder,
    NamedRouteSettings settings: const NamedRouteSettings()
  }) : super(settings: settings) {
    assert(builder != null);
    assert(opaque);
  }

  final WidgetBuilder builder;

  Duration get transitionDuration => kMaterialPageRouteTransitionDuration;
  bool get barrierDismissable => false;
  Color get barrierColor => Colors.black54;

  Widget buildPage(BuildContext context) {
    Widget result = builder(context);
    assert(() {
      if (result == null)
        debugPrint('The builder for route \'${settings.name}\' returned null. Route builders must never return null.');
      assert(result != null && 'A route builder returned null. See the previous log message for details.' is String);
      return true;
    });
    return result;
  }

  Widget buildTransition(BuildContext context, PerformanceView performance, Widget child) {
    return new _MaterialPageTransition(
      performance: performance,
      child: child
    );
  }

  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
