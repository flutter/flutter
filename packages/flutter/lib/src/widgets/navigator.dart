// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'focus.dart';
import 'framework.dart';
import 'overlay.dart';

/// An abstraction for an entry managed by a [Navigator].
///
/// This class defines an abstract interface between the navigator and the
/// "routes" that are pushed on and popped off the navigator. Most routes have
/// visual affordances, which they place in the navigators [Overlay] using one
/// or more [OverlayEntry] objects.
abstract class Route<T> {
  /// The navigator that the route is in, if any.
  NavigatorState get navigator => _navigator;
  NavigatorState _navigator;

  /// The overlay entries for this route.
  List<OverlayEntry> get overlayEntries => const <OverlayEntry>[];

  /// The key this route will use for its root [Focus] widget, if any.
  ///
  /// If this route is the first route shown by the navigator, the navigator
  /// will initialize its [Focus] to this key.
  GlobalKey get focusKey => null;

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

  /// When this route is popped (see [Navigator.pop]) if the result isn't
  /// specified or if it's null, this value will be used instead.
  T get currentResult => null;

  /// Called after install() when the route replaced another in the navigator.
  void didReplace(Route<dynamic> oldRoute) { }

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
  void didPopNext(Route<dynamic> nextRoute) { }

  /// This route's next route has changed to the given new route. This is called
  /// on a route whenever the next route changes for any reason, except for
  /// cases when didPopNext() would be called, so long as it is in the history.
  /// nextRoute will be null if there's no next route.
  void didChangeNext(Route<dynamic> nextRoute) { }

  /// The route should remove its overlays and free any other resources.
  ///
  /// A call to didPop() implies that the Route should call dispose() itself,
  /// but it is possible for dispose() to be called directly (e.g. if the route
  /// is replaced, or if the navigator itself is disposed).
  void dispose() { }

  /// Whether this route is the top-most route on the navigator.
  ///
  /// If this is true, then [isActive] is also true.
  bool get isCurrent {
    if (_navigator == null)
      return false;
    assert(_navigator._history.contains(this));
    return _navigator._history.last == this;
  }

  /// Whether this route is on the navigator.
  ///
  /// If the route is not only active, but also the current route (the top-most
  /// route), then [isCurrent] will also be true.
  ///
  /// If a later route is entirely opaque, then the route will be active but not
  /// rendered. In particular, it's possible for a route to be active but for
  /// stateful widgets within the route to not be instantiated.
  bool get isActive {
    if (_navigator == null)
      return false;
    assert(_navigator._history.contains(this));
    return true;
  }
}

/// Data that might be useful in constructing a [Route].
class RouteSettings {
  /// Creates data used to construct routes.
  const RouteSettings({
    this.name,
    this.mostValuableKeys,
    this.isInitialRoute: false
  });

  /// The name of the route (e.g., "/settings").
  ///
  /// If null, the route is anonymous.
  final String name;

  /// The set of keys that are most relevant for constructoring [Hero]
  /// transitions. For example, if the current route contains a list of music
  /// albums and the user triggered this navigation by tapping one of the
  /// albums, the most valuable album cover is the one associated with the album
  /// the user tapped and is the one that should heroically transition when
  /// opening the details page for that album.
  final Set<Key> mostValuableKeys;

  /// Whether this route is the very first route being pushed onto this [Navigator].
  ///
  /// The initial route typically skips any entrance transition to speed startup.
  final bool isInitialRoute;

  @override
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

/// Creates a route for the given route settings.
typedef Route<dynamic> RouteFactory(RouteSettings settings);

/// A callback in during which you can perform a number of navigator operations (e.g., pop, push) that happen atomically.
typedef void NavigatorTransactionCallback(NavigatorTransaction transaction);

/// An interface for observing the behavior of a [Navigator].
class NavigatorObserver {
  /// The navigator that the observer is observing, if any.
  NavigatorState get navigator => _navigator;
  NavigatorState _navigator;

  /// The [Navigator] pushed the given route.
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) { }

  /// THe [Navigator] popped the given route.
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) { }
}

/// A widget that manages a set of child widgets with a stack discipline.
///
/// Many apps have a navigator near the top of their widget hierarchy in order
/// to display their logical history using an [Overlay] with the most recently
/// visited pages visually on top of the older pages. Using this pattern lets
/// the navigator visually transition from one page to another by the widgets
/// around in the overlay. Similarly, the navigator can be used to show a dialog
/// by positioning the dialog widget above the current page.
class Navigator extends StatefulWidget {
  /// Creates a widget that maintains a stack-based history of child widgets.
  ///
  /// The [onGenerateRoute] argument must not be null.
  Navigator({
    Key key,
    this.initialRoute,
    @required this.onGenerateRoute,
    this.onUnknownRoute,
    this.observer
  }) : super(key: key) {
    assert(onGenerateRoute != null);
  }

  /// The name of the first route to show.
  final String initialRoute;

  /// Called to generate a route for a given [RouteSettings].
  final RouteFactory onGenerateRoute;

  /// Called when [onGenerateRoute] fails to generate a route.
  ///
  /// This callback is typically used for error handling. For example, this
  /// callback might always generate a "not found" page that describes the route
  /// that wasn't found.
  ///
  /// Unknown routes can arise either from errors in the app or from external
  /// requests to push routes, such as from Android intents.
  final RouteFactory onUnknownRoute;

  /// An observer for this navigator.
  final NavigatorObserver observer;

  /// The default name for the initial route.
  static const String defaultRouteName = '/';

  /// Push a named route onto the navigator that most tightly encloses the given context.
  ///
  /// The route name will be passed to that navigator's [onGenerateRoute]
  /// callback. The returned route will be pushed into the navigator. The set of
  /// most valuable keys will be used to construct an appropriate [Hero] transition.
  ///
  /// Uses [openTransaction()]. Only one transaction will be executed per frame.
  static void pushNamed(BuildContext context, String routeName, { Set<Key> mostValuableKeys }) {
    openTransaction(context, (NavigatorTransaction transaction) {
      transaction.pushNamed(routeName, mostValuableKeys: mostValuableKeys);
    });
  }

  /// Push a route onto the navigator that most tightly encloses the given context.
  ///
  /// Adds the given route to the Navigator's history, and transitions to it.
  /// The route will have didPush() and didChangeNext() called on it; the
  /// previous route, if any, will have didChangeNext() called on it; and the
  /// Navigator observer, if any, will have didPush() called on it.
  ///
  /// Uses [openTransaction()]. Only one transaction will be executed per frame.
  static void push(BuildContext context, Route<dynamic> route) {
    openTransaction(context, (NavigatorTransaction transaction) {
      transaction.push(route);
    });
  }

  /// Pop a route off the navigator that most tightly encloses the given context.
  ///
  /// Tries to removes the current route, calling its didPop() method. If that
  /// method returns false, then nothing else happens. Otherwise, the observer
  /// (if any) is notified using its didPop() method, and the previous route is
  /// notified using [Route.didChangeNext].
  ///
  /// If non-null, [result] will be used as the result of the route. Routes
  /// such as dialogs or popup menus typically use this mechanism to return the
  /// value selected by the user to the widget that created their route. The
  /// type of [result], if provided, must match the type argument of the class
  /// of the current route. (In practice, this is usually "dynamic".)
  ///
  /// Returns true if a route was popped; returns false if there are no further
  /// previous routes.
  ///
  /// Uses [openTransaction()]. Only one transaction will be executed per frame.
  static bool pop(BuildContext context, [ dynamic result ]) {
    bool returnValue;
    openTransaction(context, (NavigatorTransaction transaction) {
      returnValue = transaction.pop(result);
    });
    return returnValue;
  }

  /// Calls pop() repeatedly until the given route is the current route.
  /// If it is already the current route, nothing happens.
  ///
  /// Uses [openTransaction()]. Only one transaction will be executed per frame.
  static void popUntil(BuildContext context, Route<dynamic> targetRoute) {
    openTransaction(context, (NavigatorTransaction transaction) {
      transaction.popUntil(targetRoute);
    });
  }

  /// Whether the navigator that most tightly encloses the given context can be popped.
  ///
  /// The initial route cannot be popped off the navigator, which implies that
  /// this function returns true only if popping the navigator would not remove
  /// the initial route.
  static bool canPop(BuildContext context) {
    NavigatorState navigator = context.ancestorStateOfType(const TypeMatcher<NavigatorState>());
    return navigator != null && navigator.canPop();
  }

  /// Executes a simple transaction that both pops the current route off and
  /// pushes a named route into the navigator that most tightly encloses the given context.
  ///
  /// Uses [openTransaction()]. Only one transaction will be executed per frame.
  static void popAndPushNamed(BuildContext context, String routeName, { Set<Key> mostValuableKeys }) {
    openTransaction(context, (NavigatorTransaction transaction) {
      transaction.pop();
      transaction.pushNamed(routeName, mostValuableKeys: mostValuableKeys);
    });
  }

  /// Calls callback immediately to create a navigator transaction.
  ///
  /// To avoid race conditions, a navigator will execute at most one operation
  /// per animation frame. If you wish to perform a compound change to the
  /// navigator's state, you can use a navigator transaction to execute all the
  /// changes atomically by making the changes inside the given callback.
  static void openTransaction(BuildContext context, NavigatorTransactionCallback callback) {
    NavigatorState navigator = context.ancestorStateOfType(const TypeMatcher<NavigatorState>());
    assert(() {
      if (navigator == null) {
        throw new FlutterError(
          'openTransaction called with a context that does not include a Navigator.\n'
          'The context passed to the Navigator.openTransaction() method must be that of a widget that is a descendant of a Navigator widget.'
        );
      }
      return true;
    });
    navigator.openTransaction(callback);
  }

  @override
  NavigatorState createState() => new NavigatorState();
}

/// The state for a [Navigator] widget.
class NavigatorState extends State<Navigator> {
  final GlobalKey<OverlayState> _overlayKey = new GlobalKey<OverlayState>();
  final List<Route<dynamic>> _history = new List<Route<dynamic>>();

  @override
  void initState() {
    super.initState();
    assert(config.observer == null || config.observer.navigator == null);
    config.observer?._navigator = this;
    _push(config.onGenerateRoute(new RouteSettings(
      name: config.initialRoute ?? Navigator.defaultRouteName,
      isInitialRoute: true
    )));
  }

  @override
  void didUpdateConfig(Navigator oldConfig) {
    if (oldConfig.observer != config.observer) {
      oldConfig.observer?._navigator = null;
      assert(config.observer == null || config.observer.navigator == null);
      config.observer?._navigator = this;
    }
  }

  @override
  void dispose() {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; });
    config.observer?._navigator = null;
    for (Route<dynamic> route in _history) {
      route.dispose();
      route._navigator = null;
    }
    super.dispose();
    assert(() { _debugLocked = false; return true; });
  }

  /// The overlay this navigator uses for its visual presentation.
  OverlayState get overlay => _overlayKey.currentState;

  OverlayEntry get _currentOverlayEntry {
    for (Route<dynamic> route in _history.reversed) {
      if (route.overlayEntries.isNotEmpty)
        return route.overlayEntries.last;
    }
    return null;
  }

  bool _debugLocked = false; // used to prevent re-entrant calls to push, pop, and friends

  void _pushNamed(String name, { Set<Key> mostValuableKeys }) {
    assert(!_debugLocked);
    assert(name != null);
    RouteSettings settings = new RouteSettings(
      name: name,
      mostValuableKeys: mostValuableKeys
    );
    Route<dynamic> route = config.onGenerateRoute(settings);
    if (route == null) {
      assert(config.onUnknownRoute != null);
      route = config.onUnknownRoute(settings);
      assert(route != null);
    }
    _push(route);
  }

  void _push(Route<dynamic> route) {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; });
    assert(route != null);
    assert(route._navigator == null);
    setState(() {
      Route<dynamic> oldRoute = _history.isNotEmpty ? _history.last : null;
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

  void _replace({ Route<dynamic> oldRoute, Route<dynamic> newRoute }) {
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

  void _replaceRouteBefore({ Route<dynamic> anchorRoute, Route<dynamic> newRoute }) {
    assert(anchorRoute != null);
    assert(anchorRoute._navigator == this);
    assert(_history.indexOf(anchorRoute) > 0);
    _replace(oldRoute: _history[_history.indexOf(anchorRoute)-1], newRoute: newRoute);
  }

  void _removeRouteBefore(Route<dynamic> anchorRoute) {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; });
    assert(anchorRoute._navigator == this);
    int index = _history.indexOf(anchorRoute) - 1;
    assert(index >= 0);
    Route<dynamic> targetRoute = _history[index];
    assert(targetRoute._navigator == this);
    assert(targetRoute.overlayEntries.isEmpty || !overlay.debugIsVisible(targetRoute.overlayEntries.last));
    setState(() {
      _history.removeAt(index);
      Route<dynamic> newRoute = index < _history.length ? _history[index] : null;
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
    Route<dynamic> route = _history.last;
    assert(route._navigator == this);
    bool debugPredictedWouldPop;
    assert(() { debugPredictedWouldPop = !route.willHandlePopInternally; return true; });
    if (route.didPop(result ?? route.currentResult)) {
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

  void _popUntil(Route<dynamic> targetRoute) {
    assert(_history.contains(targetRoute));
    while (!targetRoute.isCurrent)
      _pop();
  }

  /// Whether this navigator can be popped.
  ///
  /// The only route that cannot be popped off the navigator is the initial
  /// route.
  bool canPop() {
    assert(_history.length > 0);
    return _history.length > 1 || _history[0].willHandlePopInternally;
  }

  bool _hadTransaction = true;

  /// Calls callback immediately to create a navigator transaction.
  ///
  /// To avoid race conditions, a navigator will execute at most one operation
  /// per animation frame. If you wish to perform a compound change to the
  /// navigator's state, you can use a navigator transaction to execute all the
  /// changes atomically by making the changes inside the given callback.
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

  // TODO(abarth): We should be able to take a focusScopeKey as configuration
  // information in case our parent wants to control whether we are focused.
  final GlobalKey _focusScopeKey = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    assert(!_debugLocked);
    assert(_history.isNotEmpty);
    _hadTransaction = false;
    final Route<dynamic> initialRoute = _history.first;
    return new Focus(
      key: _focusScopeKey,
      initiallyFocusedScope: initialRoute.focusKey,
      child: new Overlay(
        key: _overlayKey,
        initialEntries: initialRoute.overlayEntries
      )
    );
  }
}

/// A sequence of [Navigator] operations that are executed atomically.
class NavigatorTransaction {
  NavigatorTransaction._(this._navigator) {
    assert(_navigator != null);
  }
  NavigatorState _navigator;
  bool _debugOpen = true;

  /// The route name will be passed to the navigator's [onGenerateRoute]
  /// callback. The returned route will be pushed into the navigator. The set of
  /// most valuable keys will be used to construct an appropriate [Hero] transition.
  void pushNamed(String name, { Set<Key> mostValuableKeys }) {
    assert(_debugOpen);
    _navigator._pushNamed(name, mostValuableKeys: mostValuableKeys);
  }

  /// Adds the given route to the Navigator's history, and transitions to it.
  /// The route will have didPush() and didChangeNext() called on it; the
  /// previous route, if any, will have didChangeNext() called on it; and the
  /// Navigator observer, if any, will have didPush() called on it.
  void push(Route<dynamic> route) {
    assert(_debugOpen);
    _navigator._push(route);
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
  void replace({ Route<dynamic> oldRoute, Route<dynamic> newRoute }) {
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
  void replaceRouteBefore({ Route<dynamic> anchorRoute, Route<dynamic> newRoute }) {
    assert(_debugOpen);
    _navigator._replaceRouteBefore(anchorRoute: anchorRoute, newRoute: newRoute);
  }

  /// Removes the route prior to the given anchorRoute, and calls didChangeNext
  /// on the route prior to that one, if any. The observer is not notified.
  void removeRouteBefore(Route<dynamic> anchorRoute) {
    assert(_debugOpen);
    _navigator._removeRouteBefore(anchorRoute);
  }

  /// Tries to removes the current route, calling its didPop() method. If that
  /// method returns false, then nothing else happens. Otherwise, the observer
  /// (if any) is notified using its didPop() method, and the previous route is
  /// notified using [Route.didChangeNext].
  ///
  /// If non-null, [result] will be used as the result of the route, otherwise
  /// the route's [Route.currentValue] will be used. Routes such as dialogs or
  /// popup menus typically use this mechanism to return the value selected by
  /// the user to the widget that created their route. The type of [result],
  /// if provided, must match the type argument of the class of the current
  /// route. (In practice, this is usually "dynamic".)
  ///
  /// Returns true if a route was popped; returns false if there are no further
  /// previous routes.
  bool pop([dynamic result]) {
    assert(_debugOpen);
    return _navigator._pop(result);
  }

  /// Calls pop() repeatedly until the given route is the current route.
  /// If it is already the current route, nothing happens.
  void popUntil(Route<dynamic> targetRoute) {
    assert(_debugOpen);
    _navigator._popUntil(targetRoute);
  }

  void _debugClose() {
    assert(_debugOpen);
    _debugOpen = false;
  }
}
