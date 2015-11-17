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
  ///
  /// Use this to populate overlayEntries and add them to the overlay
  /// (accessible as navigator.overlay). (The reason the Route is responsible
  /// for doing this, rather than the Navigator, is that the Route will be
  /// responsible for _removing_ the entries and this way it's symmetric.)
  ///
  /// The overlay argument will be null if this is the first route inserted.
  void install(OverlayEntry insertionPoint) { }

  /// Called after install() when the route is pushed onto the navigator.
  void didPush() { }

  /// Called after install() when the route replaced another in the navigator.
  void didReplace(Route oldRoute) { }

  /// A request was made to pop this route. If the route can handle it
  /// internally (e.g. because it has its own stack of internal state) then
  /// return false, otherwise return true. Returning false will prevent the
  /// default behavior of NavigatorState.pop().
  ///
  /// If this is called, the Navigator will not call dispose(). It is the
  /// responsibility of the Route to later call dispose().
  bool didPop(T result) => true;

  /// Whether calling didPop() would return false.
  bool get willHandlePopInternally => false;

  /// The given route, which came after this one, has been popped off the
  /// navigator.
  void didPopNext(Route nextRoute) { }

  /// This route's next route has changed to the given new route. This is called
  /// on a route whenever the next route changes for any reason, except for
  /// cases when didPopNext() would be called, so long as it is in the history.
  /// nextRoute will be null if there's no next route.
  void didChangeNext(Route nextRoute) { }

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
  const NamedRouteSettings({
    this.name,
    this.mostValuableKeys,
    this.isInitialRoute: false
  });

  final String name;
  final Set<Key> mostValuableKeys;
  final bool isInitialRoute;

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
typedef void NavigatorTransactionCallback(NavigatorTransaction transaction);

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

  static void pushNamed(BuildContext context, String routeName, { Set<Key> mostValuableKeys }) {
    openTransaction(context, (NavigatorTransaction transaction) {
      transaction.pushNamed(routeName, mostValuableKeys: mostValuableKeys);
    });
  }

  static void push(BuildContext context, Route route, { Set<Key> mostValuableKeys }) {
    openTransaction(context, (NavigatorTransaction transaction) {
      transaction.push(route, mostValuableKeys: mostValuableKeys);
    });
  }

  static bool pop(BuildContext context, [ dynamic result ]) {
    bool returnValue;
    openTransaction(context, (NavigatorTransaction transaction) {
      returnValue = transaction.pop(result);
    });
    return returnValue;
  }
 
  static void popUntil(BuildContext context, Route targetRoute) {
    openTransaction(context, (NavigatorTransaction transaction) {
      transaction.popUntil(targetRoute);
    });
  }

  static bool canPop(BuildContext context) {
    NavigatorState navigator = context.ancestorStateOfType(NavigatorState);
    return navigator.canPop();
  }

  static void popAndPushNamed(BuildContext context, String routeName, { Set<Key> mostValuableKeys }) {
    openTransaction(context, (NavigatorTransaction transaction) {
      transaction.pop();
      transaction.pushNamed(routeName, mostValuableKeys: mostValuableKeys);
    });
  }

  static void openTransaction(BuildContext context, NavigatorTransactionCallback callback) {
    NavigatorState navigator = context.ancestorStateOfType(NavigatorState);
    navigator.openTransaction(callback);
  }

  NavigatorState createState() => new NavigatorState();
}

class NavigatorState extends State<Navigator> {
  final GlobalKey<OverlayState> _overlayKey = new GlobalKey<OverlayState>();
  final List<Route> _history = new List<Route>();

  void initState() {
    super.initState();
    assert(config.observer == null || config.observer.navigator == null);
    config.observer?._navigator = this;
    _push(config.onGenerateRoute(new NamedRouteSettings(
      name: config.initialRoute ?? Navigator.defaultRouteName,
      isInitialRoute: true
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

  // Used by Routes and NavigatorObservers
  OverlayState get overlay => _overlayKey.currentState;

  OverlayEntry get _currentOverlayEntry {
    for (Route route in _history.reversed) {
      if (route.overlayEntries.isNotEmpty)
        return route.overlayEntries.last;
    }
    return null;
  }

  bool _debugLocked = false; // used to prevent re-entrant calls to push, pop, and friends

  void _pushNamed(String name, { Set<Key> mostValuableKeys }) {
    assert(!_debugLocked);
    assert(name != null);
    NamedRouteSettings settings = new NamedRouteSettings(
      name: name,
      mostValuableKeys: mostValuableKeys
    );
    Route route = config.onGenerateRoute(settings);
    if (route == null) {
      assert(config.onUnknownRoute != null);
      route = config.onUnknownRoute(settings);
      assert(route != null);
    }
    _push(route);
  }

  void _push(Route route, { Set<Key> mostValuableKeys }) {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; });
    assert(route != null);
    assert(route._navigator == null);
    setState(() {
      Route oldRoute = _history.isNotEmpty ? _history.last : null;
      route._navigator = this;
      route.install(_currentOverlayEntry);
      _history.add(route);
      route.didPush();
      route.didChangeNext(null);
      if (oldRoute != null)
        oldRoute.didChangeNext(route);
      config.observer?.didPush(route, oldRoute);
    });
    assert(() { _debugLocked = false; return true; });
  }

  void _replace({ Route oldRoute, Route newRoute }) {
    assert(!_debugLocked);
    assert(oldRoute != null);
    assert(newRoute != null);
    if (oldRoute == newRoute)
      return;
    assert(() { _debugLocked = true; return true; });
    assert(oldRoute._navigator == this);
    assert(newRoute._navigator == null);
    assert(oldRoute.overlayEntries.isNotEmpty);
    assert(newRoute.overlayEntries.isEmpty);
    assert(!overlay.debugIsVisible(oldRoute.overlayEntries.last));
    setState(() {
      int index = _history.indexOf(oldRoute);
      assert(index >= 0);
      newRoute._navigator = this;
      newRoute.install(oldRoute.overlayEntries.last);
      _history[index] = newRoute;
      newRoute.didReplace(oldRoute);
      if (index + 1 < _history.length)
        newRoute.didChangeNext(_history[index + 1]);
      else
        newRoute.didChangeNext(null);
      if (index > 0)
        _history[index - 1].didChangeNext(newRoute);
      oldRoute.dispose();
      oldRoute._navigator = null;
    });
    assert(() { _debugLocked = false; return true; });
  }

  void _replaceRouteBefore({ Route anchorRoute, Route newRoute }) {
    assert(anchorRoute != null);
    assert(anchorRoute._navigator == this);
    assert(_history.indexOf(anchorRoute) > 0);
    _replace(oldRoute: _history[_history.indexOf(anchorRoute)-1], newRoute: newRoute);
  }

  void _removeRouteBefore(Route anchorRoute) {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; });
    assert(anchorRoute._navigator == this);
    int index = _history.indexOf(anchorRoute) - 1;
    assert(index >= 0);
    Route targetRoute = _history[index];
    assert(targetRoute._navigator == this);
    assert(targetRoute.overlayEntries.isEmpty || !overlay.debugIsVisible(targetRoute.overlayEntries.last));
    setState(() {
      _history.removeAt(index);
      Route newRoute = index < _history.length ? _history[index] : null;
      if (index > 0)
        _history[index - 1].didChangeNext(newRoute);
      targetRoute.dispose();
      targetRoute._navigator = null;
    });
    assert(() { _debugLocked = false; return true; });
  }

  bool _pop([dynamic result]) {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; });
    Route route = _history.last;
    assert(route._navigator == this);
    bool debugPredictedWouldPop;
    assert(() { debugPredictedWouldPop = !route.willHandlePopInternally; return true; });
    if (route.didPop(result)) {
      assert(debugPredictedWouldPop);
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
    } else {
      assert(!debugPredictedWouldPop);
    }
    assert(() { _debugLocked = false; return true; });
    return true;
  }

  void _popUntil(Route targetRoute) {
    assert(_history.contains(targetRoute));
    while (!targetRoute.isCurrent)
      _pop();
  }

  bool canPop() {
    assert(_history.length > 0);
    return _history.length > 1 || _history[0].willHandlePopInternally;
  }

  bool _hadTransaction = true;

  bool openTransaction(NavigatorTransactionCallback callback) {
    assert(callback != null);
    if (_hadTransaction)
      return false;
    _hadTransaction = true;
    NavigatorTransaction transaction = new NavigatorTransaction._(this);
    setState(() {
      callback(transaction);
    });
    assert(() { transaction._debugClose(); return true; });
    return true;
  }

  Widget build(BuildContext context) {
    assert(!_debugLocked);
    assert(_history.isNotEmpty);
    _hadTransaction = false;
    return new Overlay(
      key: _overlayKey,
      initialEntries: _history.first.overlayEntries
    );
  }
}

class NavigatorTransaction {
  NavigatorTransaction._(this._navigator) {
    assert(_navigator != null);
  }
  NavigatorState _navigator;
  bool _debugOpen = true;

  /// Invokes the Navigator's onGenerateRoute callback to create a route with
  /// the given name, then calls [push()] with that route.
  void pushNamed(String name, { Set<Key> mostValuableKeys }) {
    assert(_debugOpen);
    _navigator._pushNamed(name, mostValuableKeys: mostValuableKeys);
  }

  /// Adds the given route to the Navigator's history, and transitions to it.
  /// The route will have didPush() and didChangeNext() called on it; the
  /// previous route, if any, will have didChangeNext() called on it; and the
  /// Navigator observer, if any, will have didPush() called on it.
  void push(Route route, { Set<Key> mostValuableKeys }) {
    assert(_debugOpen);
    _navigator._push(route, mostValuableKeys: mostValuableKeys);
  }

  /// Replaces one given route with another. Calls install(), didReplace(), and
  /// didChangeNext() on the new route, then dispose() on the old route. The
  /// navigator is not informed of the replacement.
  ///
  /// The old route must have overlay entries, otherwise we won't know where to
  /// insert the entries of the new route. The old route must not be currently
  /// visible (i.e. a later route have overlay entries that are currently
  /// opaque), otherwise the replacement would have a jarring effect.
  ///
  /// It is safe to call this redundantly (replacing a route with itself). Such
  /// calls are ignored.
  void replace({ Route oldRoute, Route newRoute }) {
    assert(_debugOpen);
    _navigator._replace(oldRoute: oldRoute, newRoute: newRoute);
  }

  /// Like replace(), but affects the route before the given anchorRoute rather
  /// than the anchorRoute itself.
  ///
  /// If newRoute is already the route before anchorRoute, then the call is
  /// ignored.
  ///
  /// The conditions described for [replace()] apply; for instance, the route
  /// before anchorRoute must have overlay entries.
  void replaceRouteBefore({ Route anchorRoute, Route newRoute }) {
    assert(_debugOpen);
    _navigator._replaceRouteBefore(anchorRoute: anchorRoute, newRoute: newRoute);
  }

  /// Removes the route prior to the given anchorRoute, and calls didChangeNext
  /// on the route prior to that one, if any. The observer is not notified.
  void removeRouteBefore(Route anchorRoute) {
    assert(_debugOpen);
    _navigator._removeRouteBefore(anchorRoute);
  }

  /// Tries to removes the current route, calling its didPop() method. If that
  /// method returns false, then nothing else happens. Otherwise, the observer
  /// (if any) is notified using its didPop() method, and the previous route is
  /// notified using [Route.didChangeNext].
  ///
  /// The type of the result argument, if provided, must match the type argument
  /// of the class of the current route. (In practice, this is usually
  /// "dynamic".)
  ///
  /// Returns true if a route was popped; returns false if there are no further
  /// previous routes.
  bool pop([dynamic result]) {
    assert(_debugOpen);
    return _navigator._pop(result);
  }

  /// Calls pop() repeatedly until the given route is the current route.
  /// If it is already the current route, nothing happens.
  void popUntil(Route targetRoute) {
    assert(_debugOpen);
    _navigator._popUntil(targetRoute);
  }

  void _debugClose() {
    assert(_debugOpen);
    _debugOpen = false;
  }
}
