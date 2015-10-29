// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'framework.dart';
import 'overlay.dart';
import 'transitions.dart';

abstract class Route {
  /// Override this function to return the widget that this route should display.
  Widget createWidget();

  Widget _child;
  OverlayEntry _entry;

  void willPush() {
    _child = createWidget();
  }

  void didPop(dynamic result) {
    _entry.remove();
  }
}

typedef Widget RouteBuilder(args);
typedef RouteBuilder RouteGenerator(String name);

const String _kDefaultPageName = '/';

class Navigator extends StatefulComponent {
  Navigator({
    Key key,
    this.routes,
    this.onGeneratePage,
    this.onUnknownPage
  }) : super(key: key) {
    // To use a navigator, you must at a minimum define the route with the name '/'.
    assert(routes != null);
    assert(routes.containsKey(_kDefaultPageName));
  }

  final Map<String, RouteBuilder> routes;

  /// you need to implement this if you pushNamed() to names that might not be in routes.
  final RouteGenerator onGeneratePage;

  /// 404 generator. You only need to implement this if you have a way to navigate to arbitrary names.
  final RouteBuilder onUnknownPage;

  static NavigatorState of(BuildContext context) {
    NavigatorState result;
    context.visitAncestorElements((Element element) {
      if (element is StatefulComponentElement && element.state is NavigatorState) {
        result = element.state;
        return false;
      }
      return true;
    });
    return result;
  }

  NavigatorState createState() => new NavigatorState();
}

class NavigatorState extends State<Navigator> {
  GlobalKey<OverlayState> _overlay = new GlobalKey<OverlayState>();
  List<Route> _history = new List<Route>();

  void initState() {
    super.initState();
    _addRouteToHistory(new PageRoute(
      builder: config.routes[_kDefaultPageName],
      name: _kDefaultPageName
    ));
  }

  RouteBuilder _generatePage(String name) {
    assert(config.onGeneratePage != null);
    return config.onGeneratePage(name);
  }

  bool get hasPreviousRoute => _history.length > 1;

  void pushNamed(String name, { Set<Key> mostValuableKeys }) {
    final RouteBuilder builder = config.routes[name] ?? _generatePage(name) ?? config.onUnknownPage;
    assert(builder != null); // 404 getting your 404!
    push(new PageRoute(
      builder: builder,
      name: name,
      mostValuableKeys: mostValuableKeys
    ));
  }

  void _addRouteToHistory(Route route) {
    route.willPush();
    route._entry = new OverlayEntry(child: route._child);
    _history.add(route);
  }

  void push(Route route) {
    OverlayEntry reference = _history.last._entry;
    _addRouteToHistory(route);
    _overlay.currentState.insert(route._entry, above: reference);
  }

  void pop([dynamic result]) {
    _history.removeLast().didPop(result);
  }

  Widget build(BuildContext context) {
    return new Overlay(
      key: _overlay,
      initialEntries: <OverlayEntry>[ _history.first._entry ]
    );
  }
}

abstract class TransitionRoute extends Route {
  PerformanceView get performance => _performance?.view;
  Performance _performance;

  Duration get transitionDuration;

  Performance createPerformance() {
    Duration duration = transitionDuration;
    assert(duration != null && duration >= Duration.ZERO);
    return new Performance(duration: duration, debugLabel: debugLabel);
  }

  void willPush() {
    _performance = createPerformance();
    _performance.forward();
    super.willPush();
  }

  Future didPop(dynamic result) async {
    await _performance.reverse();
    super.didPop(result);
  }

  String get debugLabel => '$runtimeType';
  String toString() => '$runtimeType(performance: $_performance)';
}

class _Page extends StatefulComponent {
  _Page({ Key key, this.route }) : super(key: key);

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
    Widget result = config.route.builder(null);
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
    this.name: '<anonymous>',
    this.mostValuableKeys
  }) {
    assert(builder != null);
  }

  final RouteBuilder builder;
  final String name;
  final Set<Key> mostValuableKeys;

  Duration get transitionDuration => const Duration(milliseconds: 150);
  Widget createWidget() => new _Page(route: this);

  String get debugLabel => '${super.debugLabel}($name)';
}
