// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'overlay.dart';

abstract class Route<T> {
  /// The navigator that the route is in, if any.
  NavigatorState get navigator => _navigator;
  NavigatorState _navigator;

  List<OverlayEntry> get overlayEntries => const <OverlayEntry>[];

  /// Called when the route is inserted into the navigator.
  /// Use this to install any overlays.
  void install(OverlayState overlay, OverlayEntry insertionPoint) { }

  /// Called after install() when the route is pushed onto the navigator.
  void didPush() { }

  /// A request was made to pop this route. If the route can handle it
  /// internally (e.g. because it has its own stack of internal state) then
  /// return false, otherwise return true. Returning false will prevent the
  /// default behavior of NavigatorState.pop().
  ///
  /// If this is called, the Navigator will not call dispose(). It is the
  /// responsibility of the Route to later call dispose().
  bool didPop(T result) => true;

  /// The given route has been pushed onto the navigator after this route.
  void didPushNext(Route nextRoute) { }

  /// The given route, which came after this one, has been popped off the
  /// navigator.
  void didPopNext(Route nextRoute) { }

  /// The route should remove its overlays and free any other resources.
  ///
  /// A call to didPop() implies that the Route should call dispose() itself,
  /// but it is possible for dispose() to be called directly (e.g. if the route
  /// is replaced, or if the navigator itself is disposed).
  void dispose() { }

  /// Whether this route is the top-most route on the navigator.
  bool get isCurrent {
    if (_navigator == null)
      return false;
    assert(_navigator._history.contains(this));
    return _navigator._history.last == this;
  }
}

class NamedRouteSettings {
  const NamedRouteSettings({ this.name, this.mostValuableKeys });
  final String name;
  final Set<Key> mostValuableKeys;

  String toString() {
    String result = '"$name"';
    if (mostValuableKeys != null && mostValuableKeys.isNotEmpty) {
      result += '; keys:';
      for (Key key in mostValuableKeys)
        result += ' $key';
    }
    return result;
  }
}

typedef Route RouteFactory(NamedRouteSettings settings);

class NavigatorObserver {
  /// The navigator that the observer is observing, if any.
  NavigatorState get navigator => _navigator;
  NavigatorState _navigator;
  void didPush(Route route, Route previousRoute) { }
  void didPop(Route route, Route previousRoute) { }
}

class Navigator extends StatefulComponent {
  Navigator({
    Key key,
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.observer
  }) : super(key: key) {
    assert(onGenerateRoute != null);
  }

  final String initialRoute;
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
    push(config.onGenerateRoute(new NamedRouteSettings(
      name: config.initialRoute ?? Navigator.defaultRouteName
    )));
  }

  void didUpdateConfig(Navigator oldConfig) {
    if (oldConfig.observer != config.observer) {
      oldConfig.observer?._navigator = null;
      assert(config.observer == null || config.observer.navigator == null);
      config.observer?._navigator = this;
    }
  }

  void dispose() {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; });
    config.observer?._navigator = null;
    for (Route route in _history) {
      route.dispose();
      route._navigator = null;
    }
    super.dispose();
    assert(() { _debugLocked = false; return true; });
  }

  OverlayState get overlay => _overlayKey.currentState;

  OverlayEntry get _currentOverlay {
    for (Route route in _history.reversed) {
      if (route.overlayEntries.isNotEmpty)
        return route.overlayEntries.last;
    }
    return null;
  }

  bool _debugLocked = false; // used to prevent re-entrant calls to push, pop, and friends

  void pushNamed(String name, { Set<Key> mostValuableKeys }) {
    assert(!_debugLocked);
    assert(name != null);
    NamedRouteSettings settings = new NamedRouteSettings(
      name: name,
      mostValuableKeys: mostValuableKeys
    );
    push(config.onGenerateRoute(settings) ?? config.onUnknownRoute(settings));
  }

  void push(Route route, { Set<Key> mostValuableKeys }) {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; });
    assert(route != null);
    assert(route._navigator == null);
    setState(() {
      Route oldRoute = _history.isNotEmpty ? _history.last : null;
      route._navigator = this;
      route.install(overlay, _currentOverlay);
      _history.add(route);
      route.didPush();
      if (oldRoute != null)
        oldRoute.didPushNext(route);
      config.observer?.didPush(route, oldRoute);
    });
    assert(() { _debugLocked = false; return true; });
  }

  /// Removes the current route, notifying the observer (if any), and the
  /// previous routes (using [Route.didPopNext]).
  ///
  /// The type of the result argument, if provided, must match the type argument
  /// of the class of the current route. (In practice, this is usually
  /// "dynamic".)
  ///
  /// Returns true if a route was popped; returns false if there are no further
  /// previous routes.
  bool pop([dynamic result]) {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; });
    Route route = _history.last;
    assert(route._navigator == this);
    if (route.didPop(result)) {
      if (_history.length > 1) {
        setState(() {
          // We use setState to guarantee that we'll rebuild, since the routes
          // can't do that for themselves, even if they have changed their own
          // state (e.g. ModalScope.isCurrent).
          _history.removeLast();
          _history.last.didPopNext(route);
          config.observer?.didPop(route, _history.last);
          route._navigator = null;
        });
      } else {
        assert(() { _debugLocked = false; return true; });
        return false;
      }
    }
    assert(() { _debugLocked = false; return true; });
    return true;
  }

  Widget build(BuildContext context) {
    assert(!_debugLocked);
    assert(_history.isNotEmpty);
    return new Overlay(
      key: _overlayKey,
      initialEntries: _history.first.overlayEntries
    );
  }
}
