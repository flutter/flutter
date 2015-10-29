// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'framework.dart';
import 'navigator2.dart';
import 'overlay.dart';
import 'page_storage.dart';
import 'transitions.dart';

// TODO(abarth): Should we add a type for the result?
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
    switch (status) {
      case PerformanceStatus.completed:
        bottomEntry.opaque = opaque;
        break;
      case PerformanceStatus.forward:
      case PerformanceStatus.reverse:
        bottomEntry.opaque = false;
        break;
      case PerformanceStatus.dismissed:
        super.didPop(_result);
        break;
    }
  }

  void didPush(OverlayState overlay, OverlayEntry insertionPoint) {
    _performance = createPerformance()
      ..addStatusListener(_handleStatusChanged)
      ..forward();
    super.didPush(overlay, insertionPoint);
  }

  void didPop(dynamic result) {
    _result = result;
    _performance.reverse();
  }

  String get debugLabel => '$runtimeType';
  String toString() => '$runtimeType(performance: $_performance)';
}

class _Page extends StatefulComponent {
  _Page({
    Key key,
    this.route
  }) : super(key: key);

  final PageRoute route;

  _PageState createState() => new _PageState();
}

class _PageState extends State<_Page> {
  final AnimatedValue<Point> _position =
      new AnimatedValue<Point>(const Point(0.0, 75.0), end: Point.origin, curve: Curves.easeOut);

  final AnimatedValue<double> _opacity =
      new AnimatedValue<double>(0.0, end: 1.0, curve: Curves.easeOut);

  final GlobalKey _subtreeKey = new GlobalKey();

  Widget build(BuildContext context) {
    if (config.route._offstage) {
      return new OffStage(
        child: new PageStorage(
          key: _subtreeKey,
          bucket: config.route._storageBucket,
          child: _invokeBuilder()
        )
      );
    }
    return new SlideTransition(
      performance: config.route.performance,
      position: _position,
      child: new FadeTransition(
        performance: config.route.performance,
        opacity: _opacity,
        child: new PageStorage(
          key: _subtreeKey,
          bucket: config.route._storageBucket,
          child: _invokeBuilder()
        )
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
    this.settings: const NamedRouteSettings()
  }) {
    assert(builder != null);
    assert(opaque);
  }

  final WidgetBuilder builder;
  final NamedRouteSettings settings;

  final GlobalKey<_PageState> pageKey = new GlobalKey<_PageState>();

  String get name => settings.name;

  Duration get transitionDuration => const Duration(milliseconds: 150);
  List<Widget> createWidgets() => [ new _Page(key: pageKey, route: this) ];

  final PageStorageBucket _storageBucket = new PageStorageBucket();

  bool get offstage => _offstage;
  bool _offstage = false;
  void set offstage (bool value) {
    if (_offstage == value)
      return;
    _offstage = value;
    pageKey.currentState?.setState(() { });
  }

  String get debugLabel => '${super.debugLabel}($name)';
}
