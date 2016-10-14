// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'basic.dart';
import 'binding.dart';
import 'focus.dart';
import 'framework.dart';
import 'overlay.dart';
import 'ticker_provider.dart';

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

  /// A future that completes when this route is popped off the navigator.
  ///
  /// The future completes with the value given to [Navigator.pop], if any.
  Future<T> get popped => _popCompleter.future;
  final Completer<T> _popCompleter = new Completer<T>();

  /// Called when the route is inserted into the navigator.
  ///
  /// Use this to populate overlayEntries and add them to the overlay
  /// (accessible as navigator.overlay). (The reason the Route is responsible
  /// for doing this, rather than the Navigator, is that the Route will be
  /// responsible for _removing_ the entries and this way it's symmetric.)
  ///
  /// The overlay argument will be null if this is the first route inserted.
  @protected
  @mustCallSuper
  void install(OverlayEntry insertionPoint) { }

  /// Called after install() when the route is pushed onto the navigator.
  @protected
  @mustCallSuper
  void didPush() { }

  /// When this route is popped (see [Navigator.pop]) if the result isn't
  /// specified or if it's null, this value will be used instead.
  T get currentResult => null;

  /// Called after install() when the route replaced another in the navigator.
  @protected
  @mustCallSuper
  void didReplace(Route<dynamic> oldRoute) { }

  /// A request was made to pop this route. If the route can handle it
  /// internally (e.g. because it has its own stack of internal state) then
  /// return false, otherwise return true. Returning false will prevent the
  /// default behavior of NavigatorState.pop().
  ///
  /// If this is called, the Navigator will not call dispose(). It is the
  /// responsibility of the Route to later call dispose().
  @protected
  @mustCallSuper
  bool didPop(T result) {
    _popCompleter.complete(result);
    return true;
  }

  /// Whether calling didPop() would return false.
  bool get willHandlePopInternally => false;

  /// The given route, which came after this one, has been popped off the
  /// navigator.
  @protected
  @mustCallSuper
  void didPopNext(Route<dynamic> nextRoute) { }

  /// This route's next route has changed to the given new route. This is called
  /// on a route whenever the next route changes for any reason, except for
  /// cases when didPopNext() would be called, so long as it is in the history.
  /// nextRoute will be null if there's no next route.
  @protected
  @mustCallSuper
  void didChangeNext(Route<dynamic> nextRoute) { }

  /// The route should remove its overlays and free any other resources.
  ///
  /// A call to didPop() implies that the Route should call dispose() itself,
  /// but it is possible for dispose() to be called directly (e.g. if the route
  /// is replaced, or if the navigator itself is disposed).
  @mustCallSuper
  void dispose() { }

  /// If the route's transition can be popped via a user gesture (e.g. the iOS
  /// back gesture), this should return a controller object that can be used to
  /// control the transition animation's progress. Otherwise, it should return
  /// null.
  NavigationGestureController startPopGesture(NavigatorState navigator) {
    return null;
  }

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
  /// rendered. It is even possible for the route to be active but for the stateful
  /// widgets within the route to not be instatiated. See [ModalRoute.maintainState].
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
    this.isInitialRoute: false,
  });

  /// The name of the route (e.g., "/settings").
  ///
  /// If null, the route is anonymous.
  final String name;

  /// Whether this route is the very first route being pushed onto this [Navigator].
  ///
  /// The initial route typically skips any entrance transition to speed startup.
  final bool isInitialRoute;

  @override
  String toString() => '"$name"';
}

/// Creates a route for the given route settings.
typedef Route<dynamic> RouteFactory(RouteSettings settings);

/// An interface for observing the behavior of a [Navigator].
class NavigatorObserver {
  /// The navigator that the observer is observing, if any.
  NavigatorState get navigator => _navigator;
  NavigatorState _navigator;

  /// The [Navigator] pushed the given route.
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) { }

  /// The [Navigator] popped the given route.
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) { }

  /// The [Navigator] is being controlled by a user gesture.
  ///
  /// Used for the iOS back gesture.
  void didStartUserGesture() { }

  /// User gesture is no longer controlling the [Navigator].
  void didStopUserGesture() { }
}

/// Interface describing an object returned by the [Route.startPopGesture]
/// method, allowing the route's transition animations to be controlled by a
/// drag or other user gesture.
abstract class NavigationGestureController {
  /// Configures the NavigationGestureController and tells the given [Navigator] that
  /// a gesture has started.
  NavigationGestureController(this._navigator) {
    // Disable Hero transitions until the gesture is complete.
    _navigator.didStartUserGesture();
  }

  /// The navigator that this object is controlling.
  @protected
  NavigatorState get navigator => _navigator;
  NavigatorState _navigator;

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  ///
  /// Must be called when the gesture is done.
  ///
  /// Calling this method notifies the navigator that the gesture has completed.
  void dispose() {
    _navigator.didStopUserGesture();
    _navigator = null;
  }

  /// The drag gesture has changed by [fractionalDelta]. The total range of the
  /// drag should be 0.0 to 1.0.
  void dragUpdate(double fractionalDelta);

  /// The drag gesture has ended with a horizontal motion of
  /// [fractionalVelocity] as a fraction of screen width per second.
  void dragEnd(double fractionalVelocity);
}

/// Signature for the [Navigator.popUntil] predicate argument.
typedef bool RoutePredicate(Route<dynamic> route);

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
  /// callback. The returned route will be pushed into the navigator.
  ///
  /// Returns a Future that completes when the pushed route is popped.
  static Future<dynamic> pushNamed(BuildContext context, String routeName) {
    return Navigator.of(context).pushNamed(routeName);
  }

  /// Push a route onto the navigator that most tightly encloses the given context.
  ///
  /// Adds the given route to the Navigator's history, and transitions to it.
  /// The route will have didPush() and didChangeNext() called on it; the
  /// previous route, if any, will have didChangeNext() called on it; and the
  /// Navigator observer, if any, will have didPush() called on it.
  ///
  /// Returns a Future that completes when the pushed route is popped.
  static Future<dynamic> push(BuildContext context, Route<dynamic> route) {
    return Navigator.of(context).push(route);
  }

  /// Pop a route off the navigator that most tightly encloses the given context.
  ///
  /// Tries to removes the current route, calling its didPop() method. If that
  /// method returns false, then nothing else happens. Otherwise, the observer
  /// (if any) is notified using its didPop() method, and the previous route is
  /// notified using [Route.didChangeNext].
  ///
  /// If non-null, `result` will be used as the result of the route. Routes
  /// such as dialogs or popup menus typically use this mechanism to return the
  /// value selected by the user to the widget that created their route. The
  /// type of `result`, if provided, must match the type argument of the class
  /// of the current route. (In practice, this is usually "dynamic".)
  ///
  /// Returns true if a route was popped; returns false if there are no further
  /// previous routes.
  static bool pop(BuildContext context, [ dynamic result ]) {
    return Navigator.of(context).pop(result);
  }

  /// Calls [pop()] repeatedly until the predicate returns false.
  /// The predicate may be applied to the same route more than once if
  /// [Route.willHandlePopInternally] is true.
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    Navigator.of(context).popUntil(predicate);
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
  /// pushes a named route into the navigator that most tightly encloses the
  /// given context.
  ///
  /// If non-null, `result` will be used as the result of the route that is
  /// popped. Routes such as dialogs or popup menus typically use this mechanism
  /// to return the value selected by the user to the widget that created their
  /// route. The type of `result`, if provided, must match the type argument of
  /// the class of the current route. (In practice, this is usually "dynamic".)
  ///
  /// Returns a Future that completes when the pushed route is popped.
  static Future<dynamic> popAndPushNamed(BuildContext context, String routeName, { dynamic result }) {
    NavigatorState navigator = Navigator.of(context);
    navigator.pop(result);
    return navigator.pushNamed(routeName);
  }

  /// The state from the closest instance of this class that encloses the given context.
  static NavigatorState of(BuildContext context) {
    NavigatorState navigator = context.ancestorStateOfType(const TypeMatcher<NavigatorState>());
    assert(() {
      if (navigator == null) {
        throw new FlutterError(
          'Navigator operation requested with a context that does not include a Navigator.\n'
          'The context used to push or pop routes from the Navigator must be that of a widget that is a descendant of a Navigator widget.'
        );
      }
      return true;
    });
    return navigator;
  }

  @override
  NavigatorState createState() => new NavigatorState();
}

/// The state for a [Navigator] widget.
class NavigatorState extends State<Navigator> with TickerProviderStateMixin {
  final GlobalKey<OverlayState> _overlayKey = new GlobalKey<OverlayState>();
  final List<Route<dynamic>> _history = new List<Route<dynamic>>();

  @override
  void initState() {
    super.initState();
    assert(config.observer == null || config.observer.navigator == null);
    config.observer?._navigator = this;
    push(config.onGenerateRoute(new RouteSettings(
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

  /// Looks up the route with the given name using [Navigator.onGenerateRoute],
  /// and then [push]es that route.
  ///
  /// Returns a Future that completes when the pushed route is popped.
  Future<dynamic> pushNamed(String name) {
    assert(!_debugLocked);
    assert(name != null);
    RouteSettings settings = new RouteSettings(name: name);
    Route<dynamic> route = config.onGenerateRoute(settings);
    if (route == null) {
      assert(config.onUnknownRoute != null);
      route = config.onUnknownRoute(settings);
      assert(route != null);
    }
    return push(route);
  }

  /// Adds the given route to the navigator's history, and transitions to it.
  ///
  /// The new route and the previous route (if any) are notified (see
  /// [Route.didPush] and [Route.didChangeNext]). If the [Navigator] has an
  /// [Navigator.observer], it will be notified as well (see
  /// [NavigatorObserver.didPush]).
  ///
  /// Ongoing gestures within the current route are canceled when a new route is
  /// pushed.
  ///
  /// Returns a Future that completes when the pushed route is popped.
  Future<dynamic> push(Route<dynamic> route) {
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
    _cancelActivePointers();
    return route.popped;
  }

  /// Replaces a route that is not currently visible with a new route.
  ///
  /// The new route and the route below the new route (if any) are notified
  /// (see [Route.didReplace] and [Route.didChangeNext]). The navigator observer
  /// is not notified. The old route is disposed (see [Route.dispose]).
  ///
  /// This can be useful in combination with [removeRouteBelow] when building a
  /// non-linear user experience.
  void replace({ Route<dynamic> oldRoute, Route<dynamic> newRoute }) {
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

  /// Replaces a route that is not currently visible with a new route.
  ///
  /// The route to be removed is the one below the given `anchorRoute`. That
  /// route must not be the first route in the history.
  ///
  /// In every other way, this acts the same as [replace].
  void replaceRouteBelow({ Route<dynamic> anchorRoute, Route<dynamic> newRoute }) {
    assert(anchorRoute != null);
    assert(anchorRoute._navigator == this);
    assert(_history.indexOf(anchorRoute) > 0);
    replace(oldRoute: _history[_history.indexOf(anchorRoute)-1], newRoute: newRoute);
  }

  /// Removes the route below the given `anchorRoute`. The route to be removed
  /// must not currently be visible. The `anchorRoute` must not be the first
  /// route in the history.
  ///
  /// The removed route is disposed (see [Route.dispose]). The route prior to
  /// the removed route, if any, is notified (see [Route.didChangeNext]). The
  /// navigator observer is not notified.
  void removeRouteBelow(Route<dynamic> anchorRoute) {
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

  /// Removes the top route in the [Navigator]'s history.
  ///
  /// If an argument is provided, that argument will be the return value of the
  /// route (see [Route.didPop]).
  ///
  /// If there are any routes left on the history, the top remaining route is
  /// notified (see [Route.didPopNext]), and the method returns true. In that
  /// case, if the [Navigator] has an [Navigator.observer], it will be notified
  /// as well (see [NavigatorObserver.didPop]). Otherwise, if the popped route
  /// was the last route, the method returns false.
  ///
  /// Ongoing gestures within the current route are canceled when a route is
  /// popped.
  bool pop([dynamic result]) {
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
    _cancelActivePointers();
    return true;
  }

  /// Repeatedly calls [pop] until the given `predicate` returns true.
  void popUntil(RoutePredicate predicate) {
    while (!predicate(_history.last))
      pop();
  }

  /// Whether this navigator can be popped.
  ///
  /// The only route that cannot be popped off the navigator is the initial
  /// route.
  bool canPop() {
    assert(_history.length > 0);
    return _history.length > 1 || _history[0].willHandlePopInternally;
  }

  /// Starts a gesture that results in popping the navigator.
  NavigationGestureController startPopGesture() {
    if (canPop())
      return _history.last.startPopGesture(this);
    return null;
  }

  /// Whether a gesture controlled by a [NavigationGestureController] is currently in progress.
  bool get userGestureInProgress => _userGestureInProgress;
  // TODO(mpcomplete): remove this bool when we fix
  // https://github.com/flutter/flutter/issues/5577
  bool _userGestureInProgress = false;

  /// The navigator is being controlled by a user gesture.
  ///
  /// Used for the iOS back gesture.
  void didStartUserGesture() {
    _userGestureInProgress = true;
    config.observer?.didStartUserGesture();
  }

  /// A user gesture is no longer controlling the navigator.
  void didStopUserGesture() {
    _userGestureInProgress = false;
    config.observer?.didStopUserGesture();
  }

  final Set<int> _activePointers = new Set<int>();

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
  }

  void _handlePointerUpOrCancel(PointerEvent event) {
    _activePointers.remove(event.pointer);
  }

  void _cancelActivePointers() {
    // TODO(abarth): This mechanism is far from perfect. See https://github.com/flutter/flutter/issues/4770
    RenderAbsorbPointer absorber = _overlayKey.currentContext?.ancestorRenderObjectOfType(const TypeMatcher<RenderAbsorbPointer>());
    setState(() {
      absorber?.absorbing = true;
    });
    for (int pointer in _activePointers.toList())
      WidgetsBinding.instance.cancelPointer(pointer);
  }

  // TODO(abarth): We should be able to take a focusScopeKey as configuration
  // information in case our parent wants to control whether we are focused.
  final GlobalKey _focusScopeKey = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    assert(!_debugLocked);
    assert(_history.isNotEmpty);
    final Route<dynamic> initialRoute = _history.first;
    return new Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUpOrCancel,
      onPointerCancel: _handlePointerUpOrCancel,
      child: new AbsorbPointer(
        absorbing: false,
        child: new Focus(
          key: _focusScopeKey,
          initiallyFocusedScope: initialRoute.focusKey,
          child: new Overlay(
            key: _overlayKey,
            initialEntries: initialRoute.overlayEntries
          )
        )
      )
    );
  }
}
