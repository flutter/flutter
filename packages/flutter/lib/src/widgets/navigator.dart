// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'overlay.dart';

abstract class Route {
  List<OverlayEntry> get overlayEntries;
  void didPush(OverlayState overlay, OverlayEntry insertionPoint) { }
  void didPop(dynamic result) { }

  /// The given route has been pushed onto the navigator after this route.
  /// Return true if the route before this one should be notified also. The
  /// first route to return false will be the one passed to the
  /// NavigatorObserver's didPushModal() as the previousRoute.
  bool willPushNext(Route nextRoute) => false;

  /// The given route, which came after this one, has been popped off the
  /// navigator. Return true if the route before this one should be notified
  /// also. The first route to return false will be the one passed to the
  /// NavigatorObserver's didPushModal() as the previousRoute.
  bool didPopNext(Route nextRoute) => false;
}

class NamedRouteSettings {
  const NamedRouteSettings({ this.name, this.mostValuableKeys });
  final String name;
  final Set<Key> mostValuableKeys;
}

typedef Route RouteFactory(NamedRouteSettings settings);

class NavigatorObserver {
  NavigatorState _navigator;
  NavigatorState get navigator => _navigator;
  void didPushModal(Route route, Route previousRoute) { }
  void didPopModal(Route route, Route previousRoute) { }
}

class Navigator extends StatefulComponent {
  Navigator({
    Key key,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.observer
  }) : super(key: key) {
    assert(onGenerateRoute != null);
  }

  final RouteFactory onGenerateRoute;
  final RouteFactory onUnknownRoute;
  final NavigatorObserver observer;

  static const String defaultRouteName = '/';

  static NavigatorState of(BuildContext context) => context.ancestorStateOfType(NavigatorState);

  NavigatorState createState() => new NavigatorState();
}

class NavigatorState extends State<Navigator> {
  final GlobalKey<OverlayState> _overlayKey = new GlobalKey<OverlayState>();
  final List<Route> _ephemeral = new List<Route>();
  final List<Route> _modal = new List<Route>();

  void initState() {
    super.initState();
    assert(config.observer == null || config.observer.navigator == null);
    config.observer?._navigator = this;
    push(config.onGenerateRoute(new NamedRouteSettings(name: Navigator.defaultRouteName)));
  }

  void didUpdateConfig(Navigator oldConfig) {
    if (oldConfig.observer != config.observer) {
      oldConfig.observer?._navigator = null;
      assert(config.observer == null || config.observer.navigator == null);
      config.observer?._navigator = this;
    }
  }

  void dispose() {
    config.observer?._navigator = null;
    super.dispose();
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

  void pushNamed(String name, { Set<Key> mostValuableKeys }) {
    assert(name != null);
    NamedRouteSettings settings = new NamedRouteSettings(
      name: name,
      mostValuableKeys: mostValuableKeys
    );
    push(config.onGenerateRoute(settings) ?? config.onUnknownRoute(settings));
  }

  void push(Route route, { Set<Key> mostValuableKeys }) {
    setState(() {
      _popAllEphemeralRoutes();
      int index = _modal.length-1;
      while (index >= 0 && _modal[index].willPushNext(route))
        index -= 1;
      route.didPush(overlay, _currentOverlay);
      config.observer?.didPushModal(route, index >= 0 ? _modal[index] : null);
      _modal.add(route);
    });
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
    setState(() {
      // We use setState to guarantee that we'll rebuild, since the routes can't
      // do that for themselves, even if they have changed their own state (e.g.
      // ModalScope.isCurrent).
      if (_ephemeral.isNotEmpty) {
        _ephemeral.removeLast().didPop(result);
      } else {
        assert(_modal.length > 1);
        Route route = _modal.removeLast();
        route.didPop(result);
        int index = _modal.length-1;
        while (index >= 0 && _modal[index].didPopNext(route))
          index -= 1;
        config.observer?.didPopModal(route, index >= 0 ? _modal[index] : null);
      }
    });
  }

  Widget build(BuildContext context) {
    return new Overlay(
      key: _overlayKey,
      initialEntries: _modal.first.overlayEntries
    );
  }
}
