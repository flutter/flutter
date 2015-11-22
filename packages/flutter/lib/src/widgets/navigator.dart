// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'overlay.dart';

abstract class Route<T> {
  List<OverlayEntry> get overlayEntries;
  void didPush(OverlayState overlay, OverlayEntry insertionPoint) { }
  void didPop(T result) { }

  /// The given route has been pushed onto the navigator after this route.
  /// Return true if the route before this one should be notified also. The
  /// first route to return false will be the one passed to the
  /// NavigatorObserver's didPush() as the previousRoute.
  bool willPushNext(Route nextRoute) => false;

  /// The given route, which came after this one, has been popped off the
  /// navigator. Return true if the route before this one should be notified
  /// also. The first route to return false will be the one passed to the
  /// NavigatorObserver's didPush() as the previousRoute.
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
  void didPush(Route route, Route previousRoute) { }
  void didPop(Route route, Route previousRoute) { }
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
  final List<Route> _history = new List<Route>();

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

  bool get hasPreviousRoute => _history.length > 1;
  OverlayState get overlay => _overlayKey.currentState;

  OverlayEntry get _currentOverlay {
    for (Route route in _history.reversed) {
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
      int index = _history.length-1;
      while (index >= 0 && _history[index].willPushNext(route))
        index -= 1;
      route.didPush(overlay, _currentOverlay);
      config.observer?.didPush(route, index >= 0 ? _history[index] : null);
      _history.add(route);
    });
  }

  /// Pops the given route, if it's the current route. If it's not the current
  /// route, removes it from the list of active routes without notifying any
  /// observers or adjacent routes.
  ///
  /// Do not use this for ModalRoutes, or indeed anything other than
  /// StateRoutes. Doing so would cause very odd results, e.g. ModalRoutes would
  /// get confused about who is current.
  ///
  /// The type of the result argument, if provided, must match the type argument
  /// of the class of the given route. (In practice, this is usually "dynamic".)
  void remove(Route route, [dynamic result]) {
    assert(_history.contains(route));
    assert(route.overlayEntries.isEmpty);
    if (_history.last == route) {
      pop(result);
    } else {
      setState(() {
        _history.remove(route);
        route.didPop(result);
      });
    }
  }

  /// Removes the current route, notifying the observer (if any), and the
  /// previous routes (using [Route.didPopNext]).
  ///
  /// The type of the result argument, if provided, must match the type argument
  /// of the class of the current route. (In practice, this is usually
  /// "dynamic".)
  void pop([dynamic result]) {
    setState(() {
      // We use setState to guarantee that we'll rebuild, since the routes can't
      // do that for themselves, even if they have changed their own state (e.g.
      // ModalScope.isCurrent).
      assert(_history.length > 1);
      Route route = _history.removeLast();
      route.didPop(result);
      int index = _history.length-1;
      while (index >= 0 && _history[index].didPopNext(route))
        index -= 1;
      config.observer?.didPop(route, index >= 0 ? _history[index] : null);
    });
  }

  Widget build(BuildContext context) {
    assert(_history.isNotEmpty);
    return new Overlay(
      key: _overlayKey,
      initialEntries: _history.first.overlayEntries
    );
  }
}
