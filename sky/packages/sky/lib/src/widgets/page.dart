// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'framework.dart';
import 'navigator2.dart';
import 'overlay.dart';
import 'transitions.dart';

abstract class TransitionRoute extends Route {
  bool get opaque => true;

  PerformanceView get performance => _performance?.view;
  Performance _performance;

  Duration get transitionDuration;

  Performance createPerformance() {
    Duration duration = transitionDuration;
    assert(duration != null && duration >= Duration.ZERO);
    return new Performance(duration: duration, debugLabel: debugLabel);
  }

  dynamic _result;

  void _handleStatusChanged(PerformanceStatus status) {
    if (status == PerformanceStatus.completed && opaque) {
      bottomEntry.opaque = true;
    } else if (status == PerformanceStatus.dismissed) {
      super.remove(_result);
    }
  }

  void add(OverlayState overlayer, OverlayEntry insertionPoint) {
    _performance = createPerformance()
      ..addStatusListener(_handleStatusChanged)
      ..forward();
    super.add(overlayer, insertionPoint);
  }

  void remove(dynamic result) {
    _result = result;
    _performance.reverse();
  }

  String get debugLabel => '$runtimeType';
  String toString() => '$runtimeType(performance: $_performance)';
}

class _Page extends StatefulComponent {
  _Page({
    PageRoute route
  }) : route = route, super(key: new GlobalObjectKey(route));

  final PageRoute route;

  _PageState createState() => new _PageState();
}

class _PageState extends State<_Page> {
  final AnimatedValue<Point> _position =
      new AnimatedValue<Point>(const Point(0.0, 75.0), end: Point.origin, curve: Curves.easeOut);

  final AnimatedValue<double> _opacity =
      new AnimatedValue<double>(0.0, end: 1.0, curve: Curves.easeOut);

  Widget build(BuildContext context) {
    return new SlideTransition(
      performance: config.route.performance,
      position: _position,
      child: new FadeTransition(
        performance: config.route.performance,
        opacity: _opacity,
        child: _invokeBuilder()
      )
    );
  }

  Widget _invokeBuilder() {
    Widget result = config.route.builder(context);
    assert(() {
      if (result == null)
        debugPrint('The builder for route \'${config.route.name}\' returned null. Route builders must never return null.');
      assert(result != null && 'A route builder returned null. See the previous log message for details.' is String);
      return true;
    });
    return result;
  }
}

class PageRoute extends TransitionRoute {
  PageRoute({
    this.builder,
    this.args: const RouteArguments()
  }) {
    assert(builder != null);
    assert(opaque);
  }

  final WidgetBuilder builder;
  final RouteArguments args;

  String get name => args.name;

  Duration get transitionDuration => const Duration(milliseconds: 150);
  List<Widget> createWidgets() => [ new _Page(route: this) ];

  String get debugLabel => '${super.debugLabel}($name)';
}
