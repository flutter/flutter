// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'overlay.dart';

abstract class Route {
  List<OverlayEntry> get overlayEntries;

  void didPush(OverlayState overlay, OverlayEntry insertionPoint);
  void didPop(dynamic result);
}

class NamedRouteSettings {
  const NamedRouteSettings({ this.name, this.mostValuableKeys });

  final String name;
  final Set<Key> mostValuableKeys;
}

typedef Route RouteFactory(NamedRouteSettings settings);

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
  final GlobalKey<OverlayState> _overlayKey = new GlobalKey<OverlayState>();
  final List<Route> _ephemeral = new List<Route>();
  final List<Route> _modal = new List<Route>();

  void initState() {
    super.initState();
    push(config.onGenerateRoute(new NamedRouteSettings(name: Navigator.defaultRouteName)));
  }

  bool get hasPreviousRoute => _modal.length > 1;
  OverlayState get overlay => _overlayKey.currentState;

  OverlayEntry get _currentOverlay {
    for (Route route in _ephemeral.reversed) {
      if (route.overlayEntries.isNotEmpty)
        return route.overlayEntries.last;
    }
    for (Route route in _modal.reversed) {
      if (route.overlayEntries.isNotEmpty)
        return route.overlayEntries.last;
    }
    return null;
  }

  Route get currentRoute => _ephemeral.isNotEmpty ? _ephemeral.last : _modal.last;

  Route _removeCurrentRoute() {
    return _ephemeral.isNotEmpty ? _ephemeral.removeLast() : _modal.removeLast();
  }

  void pushNamed(String name, { Set<Key> mostValuableKeys }) {
    assert(name != null);
    NamedRouteSettings settings = new NamedRouteSettings(
      name: name,
      mostValuableKeys: mostValuableKeys
    );
    push(config.onGenerateRoute(settings) ?? config.onUnknownRoute(settings));
  }

  void push(Route route) {
    _popAllEphemeralRoutes();
    route.didPush(overlay, _currentOverlay);
    _modal.add(route);
  }

  void pushEphemeral(Route route) {
    route.didPush(overlay, _currentOverlay);
    _ephemeral.add(route);
  }

  void _popAllEphemeralRoutes() {
    List<Route> localEphemeral = new List<Route>.from(_ephemeral);
    _ephemeral.clear();
    for (Route route in localEphemeral)
      route.didPop(null);
    assert(_ephemeral.isEmpty);
  }

  void pop([dynamic result]) {
    _removeCurrentRoute().didPop(result);
  }

  Widget build(BuildContext context) {
    return new Overlay(
      key: _overlayKey,
      initialEntries: _modal.first.overlayEntries
    );
  }
}
