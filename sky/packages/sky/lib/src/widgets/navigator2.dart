// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'overlay.dart';

abstract class Route {
  List<Widget> createWidgets() => const <Widget>[];

  OverlayEntry get topEntry => _entries.isNotEmpty ? _entries.last : null;
  OverlayEntry get bottomEntry => _entries.isNotEmpty ? _entries.first : null;

  final List<OverlayEntry> _entries = new List<OverlayEntry>();

  void add(OverlayState overlay, OverlayEntry insertionPoint) {
    List<Widget> widgets = createWidgets();
    for (Widget widget in widgets) {
      _entries.add(new OverlayEntry(child: widget));
      overlay?.insert(_entries.last, above: insertionPoint);
      insertionPoint = _entries.last;
    }
  }

  void remove(dynamic result) {
    for (OverlayEntry entry in _entries)
      entry.remove();
  }
}

class RouteArguments {
  const RouteArguments({ this.name: '<anonymous>', this.mostValuableKeys });

  final String name;
  final Set<Key> mostValuableKeys;
}

typedef Route RouteFactory(RouteArguments args);

class Navigator extends StatefulComponent {
  Navigator({
    Key key,
    this.onGenerateRoute,
    this.onUnknownRoute
  }) : super(key: key) {
    assert(onGenerateRoute != null);
  }

  final RouteFactory onGenerateRoute;
  final RouteFactory onUnknownRoute;

  static const String defaultRouteName = '/';

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
  final GlobalKey<OverlayState> _overlay = new GlobalKey<OverlayState>();
  final List<Route> _ephemeral = new List<Route>();
  final List<Route> _modal = new List<Route>();

  void initState() {
    super.initState();
    push(config.onGenerateRoute(new RouteArguments(name: Navigator.defaultRouteName)));
  }

  bool get hasPreviousRoute => _modal.length > 1;

  OverlayEntry get _topRouteOverlay {
    for (Route route in _ephemeral.reversed) {
      if (route.topEntry != null)
        return route.topEntry;
    }
    for (Route route in _modal.reversed) {
      if (route.topEntry != null)
        return route.topEntry;
    }
    return null;
  }

  void pushNamed(String name, { Set<Key> mostValuableKeys }) {
    RouteArguments args = new RouteArguments(name: name, mostValuableKeys: mostValuableKeys);
    push(config.onGenerateRoute(args) ?? config.onUnknownRoute(args));
  }

  void push(Route route) {
    _popAllEphemeralRoutes();
    route.add(_overlay.currentState, _topRouteOverlay);
    _modal.add(route);
  }

  void pushEphemeral(Route route) {
    route.add(_overlay.currentState, _topRouteOverlay);
    _ephemeral.add(route);
  }

  void _popAllEphemeralRoutes() {
    List<Route> localEphemeral = new List<Route>.from(_ephemeral);
    _ephemeral.clear();
    for (Route route in localEphemeral)
      route.remove(null);
    assert(_ephemeral.isEmpty);
  }

  void pop([dynamic result]) {
    if (_ephemeral.isNotEmpty) {
      _ephemeral.removeLast().remove(result);
      return;
    }
    _modal.removeLast().remove(result);
  }

  Widget build(BuildContext context) {
    return new Overlay(
      key: _overlay,
      initialEntries: _modal.first._entries
    );
  }
}
