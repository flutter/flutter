// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'binding.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'overlay.dart';
import 'ticker_provider.dart';

/// Indicates whether the current route should be popped.
///
/// Used as the return value for [Route.willPop].
///
/// See also:
///
///  * [WillPopScope], a widget that hooks into the route's [Route.willPop]
///    mechanism.
enum RoutePopDisposition {
  /// Pop the route.
  ///
  /// If [Route.willPop] returns [pop] then the back button will actually pop
  /// the current route.
  pop,

  /// Do not pop the route.
  ///
  /// If [Route.willPop] returns [doNotPop] then the back button will be ignored.
  doNotPop,

  /// Delegate this to the next level of navigation.
  ///
  /// If [Route.willPop] return [bubble] then the back button will be handled
  /// by the [SystemNavigator], which will usually close the application.
  bubble,
}

/// Signature for a callback that verifies that it's OK to call [Navigator.pop].
///
/// Used by [Form.onWillPop], [ModalRoute.addScopedWillPopCallback],
/// [ModalRoute.removeScopedWillPopCallback], and [WillPopScope].
typedef Future<bool> WillPopCallback();

/// An abstraction for an entry managed by a [Navigator].
///
/// This class defines an abstract interface between the navigator and the
/// "routes" that are pushed on and popped off the navigator. Most routes have
/// visual affordances, which they place in the navigators [Overlay] using one
/// or more [OverlayEntry] objects.
///
/// See [Navigator] for more explanation of how to use a Route
/// with navigation, including code examples.
///
/// See [MaterialPageRoute] for a route that replaces the
/// entire screen with a platform-adaptive transition.
abstract class Route<T> {
  /// The navigator that the route is in, if any.
  NavigatorState get navigator => _navigator;
  NavigatorState _navigator;

  /// The overlay entries for this route.
  List<OverlayEntry> get overlayEntries => const <OverlayEntry>[];

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

  /// Called after [install] when the route is pushed onto the navigator.
  ///
  /// The returned value resolves when the push transition is complete.
  @protected
  TickerFuture didPush() => new TickerFuture.complete();

  /// When this route is popped (see [Navigator.pop]) if the result isn't
  /// specified or if it's null, this value will be used instead.
  T get currentResult => null;

  /// Called after [install] when the route replaced another in the navigator.
  @protected
  @mustCallSuper
  void didReplace(Route<dynamic> oldRoute) { }

  /// Returns false if this route wants to veto a [Navigator.pop]. This method is
  /// called by [Navigator.maybePop].
  ///
  /// By default, routes veto a pop if they're the first route in the history
  /// (i.e., if [isFirst]). This behavior prevents the user from popping the
  /// first route off the history and being stranded at a blank screen.
  ///
  /// See also:
  ///
  ///  * [Form], which provides a [Form.onWillPop] callback that uses this
  ///    mechanism.
  ///  * [WillPopScope], another widget that provides a way to intercept the
  ///    back button.
  Future<RoutePopDisposition> willPop() async {
    return isFirst ? RoutePopDisposition.bubble : RoutePopDisposition.pop;
  }

  /// A request was made to pop this route. If the route can handle it
  /// internally (e.g. because it has its own stack of internal state) then
  /// return false, otherwise return true. Returning false will prevent the
  /// default behavior of [NavigatorState.pop].
  ///
  /// When this function returns true, the navigator removes this route from
  /// the history but does not yet call [dispose]. Instead, it is the route's
  /// responsibility to call [NavigatorState.finalizeRoute], which will in turn
  /// call [dispose] on the route. This sequence lets the route perform an
  /// exit animation (or some other visual effect) after being popped but prior
  /// to being disposed.
  @protected
  @mustCallSuper
  bool didPop(T result) {
    didComplete(result);
    return true;
  }

  /// Whether calling [didPop] would return false.
  bool get willHandlePopInternally => false;

  /// The given route, which came after this one, has been popped off the
  /// navigator.
  @protected
  @mustCallSuper
  void didPopNext(Route<dynamic> nextRoute) { }

  /// This route's next route has changed to the given new route. This is called
  /// on a route whenever the next route changes for any reason, except for
  /// cases when [didPopNext] would be called, so long as it is in the history.
  /// `nextRoute` will be null if there's no next route.
  @protected
  @mustCallSuper
  void didChangeNext(Route<dynamic> nextRoute) { }

  /// This route's previous route has changed to the given new route. This is
  /// called on a route whenever the previous route changes for any reason, so
  /// long as it is in the history, except for immediately after the route has
  /// been pushed (in which case [didPush] or [didReplace] will be called
  /// instead). `previousRoute` will be null if there's no previous route.
  @protected
  @mustCallSuper
  void didChangePrevious(Route<dynamic> previousRoute) { }

  /// The route was popped or is otherwise being removed somewhat gracefully.
  ///
  /// This is called by [didPop] and in response to [Navigator.pushReplacement].
  @protected
  @mustCallSuper
  void didComplete(T result) {
    _popCompleter.complete(result);
  }

  /// The route should remove its overlays and free any other resources.
  ///
  /// This route is no longer referenced by the navigator.
  @mustCallSuper
  @protected
  void dispose() {
    _navigator = null;
  }

  /// Whether this route is the top-most route on the navigator.
  ///
  /// If this is true, then [isActive] is also true.
  bool get isCurrent {
    return _navigator != null && _navigator._history.last == this;
  }

  /// Whether this route is the bottom-most route on the navigator.
  ///
  /// If this is true, then [Navigator.canPop] will return false if this route's
  /// [willHandlePopInternally] returns false.
  ///
  /// If [isFirst] and [isCurrent] are both true then this is the only route on
  /// the navigator (and [isActive] will also be true).
  bool get isFirst {
    return _navigator != null && _navigator._history.first == this;
  }

  /// Whether this route is on the navigator.
  ///
  /// If the route is not only active, but also the current route (the top-most
  /// route), then [isCurrent] will also be true. If it is the first route (the
  /// bottom-most route), then [isFirst] will also be true.
  ///
  /// If a later route is entirely opaque, then the route will be active but not
  /// rendered. It is even possible for the route to be active but for the stateful
  /// widgets within the route to not be instantiated. See [ModalRoute.maintainState].
  bool get isActive {
    return _navigator != null && _navigator._history.contains(this);
  }
}

/// Data that might be useful in constructing a [Route].
@immutable
class RouteSettings {
  /// Creates data used to construct routes.
  const RouteSettings({
    this.name,
    this.isInitialRoute: false,
  });

  /// Creates a copy of this route settings object with the given fields
  /// replaced with the new values.
  RouteSettings copyWith({
    String name,
    bool isInitialRoute,
  }) {
    return new RouteSettings(
      name: name ?? this.name,
      isInitialRoute: isInitialRoute ?? this.isInitialRoute,
    );
  }

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
///
/// Used by [Navigator.onGenerateRoute] and [Navigator.onUnknownRoute].
typedef Route<dynamic> RouteFactory(RouteSettings settings);

/// An interface for observing the behavior of a [Navigator].
class NavigatorObserver {
  /// The navigator that the observer is observing, if any.
  NavigatorState get navigator => _navigator;
  NavigatorState _navigator;

  /// The [Navigator] pushed `route`.
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) { }

  /// The [Navigator] popped `route`.
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) { }

  /// The [Navigator] removed `route`.
  void didRemove(Route<dynamic> route, Route<dynamic> previousRoute) { }

  /// The [Navigator]'s routes are being moved by a user gesture.
  ///
  /// For example, this is called when an iOS back gesture starts, and is used
  /// to disabled hero animations during such interactions.
  void didStartUserGesture() { }

  /// User gesture is no longer controlling the [Navigator].
  ///
  /// Paired with an earlier call to [didStartUserGesture].
  void didStopUserGesture() { }
}

/// Signature for the [Navigator.popUntil] predicate argument.
typedef bool RoutePredicate(Route<dynamic> route);

/// A widget that manages a set of child widgets with a stack discipline.
///
/// Many apps have a navigator near the top of their widget hierarchy in order
/// to display their logical history using an [Overlay] with the most recently
/// visited pages visually on top of the older pages. Using this pattern lets
/// the navigator visually transition from one page to another by moving the widgets
/// around in the overlay. Similarly, the navigator can be used to show a dialog
/// by positioning the dialog widget above the current page.
///
/// ## Using the Navigator
///
/// Mobile apps typically reveal their contents via full-screen elements
/// called "screens" or "pages". In Flutter these elements are called
/// routes and they're managed by a [Navigator] widget. The navigator
/// manages a stack of [Route] objects and provides methods for managing
/// the stack, like [Navigator.push] and [Navigator.pop].
///
/// ### Displaying a full-screen route
///
/// Although you can create a navigator directly, it's most common to use
/// the navigator created by a [WidgetsApp] or a [MaterialApp] widget. You
/// can refer to that navigator with [Navigator.of].
///
/// A MaterialApp is the simplest way to set things up. The MaterialApp's
/// home becomes the route at the bottom of the Navigator's stack. It is
/// what you see when the app is launched.
///
/// ```dart
/// void main() {
///   runApp(new MaterialApp(home: new MyAppHome()));
/// }
/// ```
///
/// To push a new route on the stack you can create an instance of
/// [MaterialPageRoute] with a builder function that creates whatever you
/// want to appear on the screen. For example:
///
/// ```dart
/// Navigator.of(context).push(new MaterialPageRoute<Null>(
///   builder: (BuildContext context) {
///     return new Scaffold(
///       appBar: new AppBar(title: new Text('My Page')),
///       body: new Center(
///         child: new FlatButton(
///           child: new Text('POP'),
///           onPressed: () {
///             Navigator.of(context).pop();
///           },
///         ),
///       ),
///     );
///   },
/// ));
/// ```
///
/// The route defines its widget with a builder function instead of a
/// child widget because it will be built and rebuilt in different
/// contexts depending on when it's pushed and popped.
///
/// As you can see, the new route can be popped, revealing the app's home
/// page, with the Navigator's pop method:
///
/// ```dart
/// Navigator.of(context).pop();
/// ```
///
/// It usually isn't necessary to provide a widget that pops the Navigator
/// in a route with a [Scaffold] because the Scaffold automatically adds a
/// 'back' button to its AppBar. Pressing the back button causes
/// [Navigator.pop] to be called. On Android, pressing the system back
/// button does the same thing.
///
/// ### Using named navigator routes
///
/// Mobile apps often manage a large number of routes and it's often
/// easiest to refer to them by name. Route names, by convention,
/// use a path-like structure (for example, '/a/b/c').
/// The app's home page route is named '/' by default.
///
/// The [MaterialApp] can be created
/// with a [Map<String, WidgetBuilder>] which maps from a route's name to
/// a builder function that will create it. The [MaterialApp] uses this
/// map to create a value for its navigator's [onGenerateRoute] callback.
///
/// ```dart
/// void main() {
///   runApp(new MaterialApp(
///     home: new MyAppHome(), // becomes the route named '/'
///     routes: <String, WidgetBuilder> {
///       '/a': (BuildContext context) => new MyPage(title: 'page A'),
///       '/b': (BuildContext context) => new MyPage(title: 'page B'),
///       '/c': (BuildContext context) => new MyPage(title: 'page C'),
///     },
///   ));
/// }
/// ```
///
/// To show a route by name:
///
/// ```dart
/// Navigator.of(context).pushNamed('/b');
/// ```
///
/// ### Routes can return a value
///
/// When a route is pushed to ask the user for a value, the value can be
/// returned via the [pop] method's result parameter.
///
/// Methods that push a route return a Future. The Future resolves when
/// the route is popped and the Future's value is the [pop] method's result
/// parameter.
///
/// For example if we wanted to ask the user to press 'OK' to confirm an
/// operation we could `await` the result of [Navigator.push]:
///
/// ```
/// bool value = await Navigator.of(context).push(new MaterialPageRoute<bool>(
///   builder: (BuildContext context) {
///     return new Center(
///       child: new GestureDetector(
///         child: new Text('OK'),
///         onTap: () { Navigator.of(context).pop(true); }
///       ),
///     );
///   }
/// ));
/// ```
/// If the user presses 'OK' then value will be true. If the user backs
/// out of the route, for example by pressing the Scaffold's back button,
/// the value will be null.
///
/// When a route is used to return a value, the route's type parameter
/// must match the type of [pop]'s result. That's why we've used
/// `MaterialPageRoute<bool>` instead of `MaterialPageRoute<Null>`.
///
/// ### Popup routes
///
/// Routes don't have to obscure the entire screen. [PopupRoute]s cover the
/// screen with a [ModalRoute.barrierColor] that can be only partially opaque to
/// allow the current screen to show through. Popup routes are "modal" because
/// they block input to the widgets below.
///
/// There are functions which create and show popup routes. For
/// example: [showDialog], [showMenu], and [showModalBottomSheet]. These
/// functions return their pushed route's Future as described above.
/// Callers can await the returned value to take an action when the
/// route is popped, or to discover the route's value.
///
/// There are also widgets which create popup routes, like [PopupMenuButton] and
/// [DropdownButton]. These widgets create internal subclasses of PopupRoute
/// and use the Navigator's push and pop methods to show and dismiss them.
///
/// ### Custom routes
///
/// You can create your own subclass of one of the widget library route classes
/// like [PopupRoute], [ModalRoute], or [PageRoute], to control the animated
/// transition employed to show the route, the color and behavior of the route's
/// modal barrier, and other aspects of the route.
///
/// The PageRouteBuilder class makes it possible to define a custom route
/// in terms of callbacks. Here's an example that rotates and fades its child
/// when the route appears or disappears. This route does not obscure the entire
/// screen because it specifies `opaque: false`, just as a popup route does.
///
/// ```dart
/// Navigator.of(context).push(new PageRouteBuilder(
///   opaque: false,
///   pageBuilder: (BuildContext context, _, __) {
///     return new Center(child: new Text('My PageRoute'));
///   },
///   transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
///     return new FadeTransition(
///       opacity: animation,
///       child: new RotationTransition(
///         turns: new Tween<double>(begin: 0.5, end: 1.0).animate(animation),
///         child: child,
///       ),
///     );
///   }
/// ));
/// ```
///
/// The page route is built in two parts, the "page" and the
/// "transitions". The page becomes a descendant of the child passed to
/// the `buildTransitions` method. Typically the page is only built once,
/// because it doesn't depend on its animation parameters (elided with `_`
/// and `__` in this example). The transition is built on every frame
/// for its duration.
class Navigator extends StatefulWidget {
  /// Creates a widget that maintains a stack-based history of child widgets.
  ///
  /// The [onGenerateRoute] argument must not be null.
  const Navigator({
    Key key,
    this.initialRoute,
    @required this.onGenerateRoute,
    this.onUnknownRoute,
    this.observers: const <NavigatorObserver>[]
  }) : assert(onGenerateRoute != null),
       super(key: key);

  /// The name of the first route to show.
  ///
  /// By default, this defers to [dart:ui.Window.defaultRouteName].
  ///
  /// If this string contains any `/` characters, then the string is split on
  /// those characters and substrings from the start of the string up to each
  /// such character are, in turn, used as routes to push.
  ///
  /// For example, if the route `/stocks/HOOLI` was used as the [initialRoute],
  /// then the [Navigator] would push the following routes on startup: `/`,
  /// `/stocks`, `/stocks/HOOLI`. This enables deep linking while allowing the
  /// application to maintain a predictable route history.
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

  /// A list of observers for this navigator.
  final List<NavigatorObserver> observers;

  /// The default name for the [initialRoute].
  ///
  /// See also:
  ///
  ///  * [dart:ui.Window.defaultRouteName], which reflects the route that the
  ///    application was started with.
  static const String defaultRouteName = '/';

  /// Push a named route onto the navigator that most tightly encloses the given context.
  ///
  /// The route name will be passed to that navigator's [onGenerateRoute]
  /// callback. The returned route will be pushed into the navigator.
  ///
  /// Returns a [Future] that completes to the `result` value passed to [pop]
  /// when the pushed route is popped off the navigator.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Navigator.pushNamed(context, '/nyc/1776');
  /// ```
  static Future<dynamic> pushNamed(BuildContext context, String routeName) {
    return Navigator.of(context).pushNamed(routeName);
  }

  /// Adds the given route to the history of the navigator that most tightly
  /// encloses the given context, and transitions to it.
  ///
  /// The new route and the previous route (if any) are notified (see
  /// [Route.didPush] and [Route.didChangeNext]). If the [Navigator] has any
  /// [Navigator.observers], they will be notified as well (see
  /// [NavigatorObserver.didPush]).
  ///
  /// Ongoing gestures within the current route are canceled when a new route is
  /// pushed.
  ///
  /// Returns a [Future] that completes to the `result` value passed to [pop]
  /// when the pushed route is popped off the navigator.
  @optionalTypeArgs
  static Future<T> push<T>(BuildContext context, Route<T> route) {
    return Navigator.of(context).push(route);
  }

  /// Returns the value of the current route's [Route.willPop] method. This
  /// method is typically called before a user-initiated [pop]. For example on
  /// Android it's called by the binding for the system's back button.
  ///
  /// See also:
  ///
  /// * [Form], which provides an `onWillPop` callback that enables the form
  ///   to veto a [pop] initiated by the app's back button.
  /// * [ModalRoute], which provides a `scopedWillPopCallback` that can be used
  ///   to define the route's `willPop` method.
  static Future<bool> maybePop(BuildContext context, [ dynamic result ]) {
    return Navigator.of(context).maybePop(result);
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
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Navigator.pop(context);
  /// ```
  static bool pop(BuildContext context, [ dynamic result ]) {
    return Navigator.of(context).pop(result);
  }

  /// Calls [pop] repeatedly until the predicate returns true.
  ///
  /// The predicate may be applied to the same route more than once if
  /// [Route.willHandlePopInternally] is true.
  ///
  /// To pop until a route with a certain name, use the [RoutePredicate]
  /// returned from [ModalRoute.withName].
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Navigator.popUntil(context, ModalRoute.withName('/login'));
  /// ```
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    Navigator.of(context).popUntil(predicate);
  }

  /// Whether the navigator that most tightly encloses the given context can be
  /// popped.
  ///
  /// The initial route cannot be popped off the navigator, which implies that
  /// this function returns true only if popping the navigator would not remove
  /// the initial route.
  static bool canPop(BuildContext context) {
    final NavigatorState navigator = context.ancestorStateOfType(const TypeMatcher<NavigatorState>());
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
  /// Returns a [Future] that completes to the `result` value passed to [pop]
  /// when the pushed route is popped off the navigator.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Navigator.popAndPushNamed(context, '/nyc/1776');
  /// ```
  static Future<dynamic> popAndPushNamed(BuildContext context, String routeName, { dynamic result }) {
    final NavigatorState navigator = Navigator.of(context);
    navigator.pop(result);
    return navigator.pushNamed(routeName);
  }

  /// Replace the current route by pushing the route named [routeName] and then
  /// disposing the previous route.
  ///
  /// The route name will be passed to the navigator's [onGenerateRoute]
  /// callback. The returned route will be pushed into the navigator.
  ///
  /// Returns a [Future] that completes to the `result` value passed to [pop]
  /// when the pushed route is popped off the navigator.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Navigator.of(context).pushReplacementNamed('/jouett/1781');
  /// ```
  static Future<dynamic> pushReplacementNamed(BuildContext context, String routeName, { dynamic result }) {
    return Navigator.of(context).pushReplacementNamed(routeName, result: result);
  }

  /// Replace the current route by pushing [route] and then disposing the
  /// current route.
  ///
  /// The new route and the route below the new route (if any) are notified
  /// (see [Route.didPush] and [Route.didChangeNext]). The navigator observer
  /// is not notified about the old route. The old route is disposed (see
  /// [Route.dispose]).
  ///
  /// If a [result] is provided, it will be the return value of the old route,
  /// as if the old route had been popped.
  ///
  /// Returns a [Future] that completes to the `result` value passed to [pop]
  /// when the pushed route is popped off the navigator.
  static Future<dynamic> pushReplacement(BuildContext context, Route<dynamic> route, { dynamic result }) {
    return Navigator.of(context).pushReplacement(route, result: result);
  }

  /// Immediately remove `route` and [Route.dispose] it.
  ///
  /// The route's animation does not run and the future returned from pushing
  /// the route will not complete. Ongoing input gestures are cancelled. If
  /// the [Navigator] has any [Navigator.observers], they will be notified with
  /// [NavigatorObserver.didRemove].
  ///
  /// The routes before and after the removed route, if any, are notified with
  /// [Route.didChangeNext] and [Route.didChangePrevious].
  ///
  /// This method is used to dismiss dropdown menus that are up when the screen's
  /// orientation changes.
  static void removeRoute(BuildContext context, Route<dynamic> route) {
    return Navigator.of(context).removeRoute(route);
  }

  /// The state from the closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Navigator.of(context)
  ///   ..pop()
  ///   ..pop()
  ///   ..pushNamed('/settings');
  /// ```
  ///
  /// If `rootNavigator` is set to true, the state from the furthest instance of
  /// this class is given instead. Useful for pushing contents above all subsequent
  /// instances of [Navigator].
  static NavigatorState of(
    BuildContext context, {
      bool rootNavigator: false
    }) {
    final NavigatorState navigator = rootNavigator
        ? context.rootAncestorStateOfType(const TypeMatcher<NavigatorState>())
        : context.ancestorStateOfType(const TypeMatcher<NavigatorState>());
    assert(() {
      if (navigator == null) {
        throw new FlutterError(
          'Navigator operation requested with a context that does not include a Navigator.\n'
          'The context used to push or pop routes from the Navigator must be that of a widget that is a descendant of a Navigator widget.'
        );
      }
      return true;
    }());
    return navigator;
  }

  @override
  NavigatorState createState() => new NavigatorState();
}

/// The state for a [Navigator] widget.
class NavigatorState extends State<Navigator> with TickerProviderStateMixin {
  final GlobalKey<OverlayState> _overlayKey = new GlobalKey<OverlayState>();
  final List<Route<dynamic>> _history = <Route<dynamic>>[];
  final Set<Route<dynamic>> _poppedRoutes = new Set<Route<dynamic>>();

  /// The [FocusScopeNode] for the [FocusScope] that encloses the routes.
  final FocusScopeNode focusScopeNode = new FocusScopeNode();

  final List<OverlayEntry> _initialOverlayEntries = <OverlayEntry>[];

  @override
  void initState() {
    super.initState();
    for (NavigatorObserver observer in widget.observers) {
      assert(observer.navigator == null);
      observer._navigator = this;
    }
    String initialRouteName = widget.initialRoute ?? Navigator.defaultRouteName;
    if (initialRouteName.startsWith('/') && initialRouteName.length > 1) {
      initialRouteName = initialRouteName.substring(1); // strip leading '/'
      assert(Navigator.defaultRouteName == '/');
      final List<String> plannedInitialRouteNames = <String>[
        Navigator.defaultRouteName,
      ];
      final List<Route<dynamic>> plannedInitialRoutes = <Route<dynamic>>[
        _routeNamed(Navigator.defaultRouteName, allowNull: true),
      ];
      final List<String> routeParts = initialRouteName.split('/');
      if (initialRouteName.isNotEmpty) {
        String routeName = '';
        for (String part in routeParts) {
          routeName += '/$part';
          plannedInitialRouteNames.add(routeName);
          plannedInitialRoutes.add(_routeNamed(routeName, allowNull: true));
        }
      }
      if (plannedInitialRoutes.contains(null)) {
        assert(() {
          FlutterError.reportError(
            new FlutterErrorDetails( // ignore: prefer_const_constructors, https://github.com/dart-lang/sdk/issues/29952
              exception:
                'Could not navigate to initial route.\n'
                'The requested route name was: "/$initialRouteName"\n'
                'The following routes were therefore attempted:\n'
                ' * ${plannedInitialRouteNames.join("\n * ")}\n'
                'This resulted in the following objects:\n'
                ' * ${plannedInitialRoutes.join("\n * ")}\n'
                'One or more of those objects was null, and therefore the initial route specified will be '
                'ignored and "${Navigator.defaultRouteName}" will be used instead.'
            ),
          );
          return true;
        }());
        push(_routeNamed(Navigator.defaultRouteName));
      } else {
        plannedInitialRoutes.forEach(push);
      }
    } else {
      Route<dynamic> route;
      if (initialRouteName != Navigator.defaultRouteName)
        route = _routeNamed(initialRouteName, allowNull: true);
      route ??= _routeNamed(Navigator.defaultRouteName);
      push(route);
    }
    for (Route<dynamic> route in _history)
      _initialOverlayEntries.addAll(route.overlayEntries);
  }

  @override
  void didUpdateWidget(Navigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.observers != widget.observers) {
      for (NavigatorObserver observer in oldWidget.observers)
        observer._navigator = null;
      for (NavigatorObserver observer in widget.observers) {
        assert(observer.navigator == null);
        observer._navigator = this;
      }
    }
  }

  @override
  void dispose() {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; }());
    for (NavigatorObserver observer in widget.observers)
      observer._navigator = null;
    final List<Route<dynamic>> doomed = _poppedRoutes.toList()..addAll(_history);
    for (Route<dynamic> route in doomed)
      route.dispose();
    _poppedRoutes.clear();
    _history.clear();
    focusScopeNode.detach();
    super.dispose();
    assert(() { _debugLocked = false; return true; }());
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

  Route<dynamic> _routeNamed(String name, { bool allowNull: false }) {
    assert(!_debugLocked);
    assert(name != null);
    final RouteSettings settings = new RouteSettings(
      name: name,
      isInitialRoute: _history.isEmpty,
    );
    Route<dynamic> route = widget.onGenerateRoute(settings);
    if (route == null && !allowNull) {
      assert(() {
        if (widget.onUnknownRoute == null) {
          throw new FlutterError(
            'If a Navigator has no onUnknownRoute, then its onGenerateRoute must never return null.\n'
            'When trying to build the route "$name", onGenerateRoute returned null, but there was no '
            'onUnknownRoute callback specified.\n'
            'The Navigator was:\n'
            '  $this'
          );
        }
        return true;
      }());
      route = widget.onUnknownRoute(settings);
      assert(() {
        if (route == null) {
          throw new FlutterError(
            'A Navigator\'s onUnknownRoute returned null.\n'
            'When trying to build the route "$name", both onGenerateRoute and onUnknownRoute returned '
            'null. The onUnknownRoute callback should never return null.\n'
            'The Navigator was:\n'
            '  $this'
          );
        }
        return true;
      }());
    }
    return route;
  }

  /// Push a named route onto the navigator.
  ///
  /// The route name will be passed to [Navigator.onGenerateRoute]. The returned
  /// route will be pushed into the navigator.
  ///
  /// Returns a [Future] that completes to the `result` value passed to [pop]
  /// when the pushed route is popped off the navigator.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Navigator.of(context).pushNamed('/nyc/1776');
  /// ```
  Future<dynamic> pushNamed(String name) {
    return push(_routeNamed(name));
  }

  /// Adds the given route to the navigator's history, and transitions to it.
  ///
  /// The new route and the previous route (if any) are notified (see
  /// [Route.didPush] and [Route.didChangeNext]). If the [Navigator] has any
  /// [Navigator.observers], they will be notified as well (see
  /// [NavigatorObserver.didPush]).
  ///
  /// Ongoing gestures within the current route are canceled when a new route is
  /// pushed.
  ///
  /// Returns a [Future] that completes to the `result` value passed to [pop]
  /// when the pushed route is popped off the navigator.
  Future<Object> push(Route<Object> route) {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; }());
    assert(route != null);
    assert(route._navigator == null);
    setState(() {
      final Route<dynamic> oldRoute = _history.isNotEmpty ? _history.last : null;
      route._navigator = this;
      route.install(_currentOverlayEntry);
      _history.add(route);
      route.didPush();
      route.didChangeNext(null);
      if (oldRoute != null)
        oldRoute.didChangeNext(route);
      for (NavigatorObserver observer in widget.observers)
        observer.didPush(route, oldRoute);
    });
    assert(() { _debugLocked = false; return true; }());
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
  void replace({ @required Route<dynamic> oldRoute, @required Route<dynamic> newRoute }) {
    assert(!_debugLocked);
    assert(oldRoute != null);
    assert(newRoute != null);
    if (oldRoute == newRoute)
      return;
    assert(() { _debugLocked = true; return true; }());
    assert(oldRoute._navigator == this);
    assert(newRoute._navigator == null);
    assert(oldRoute.overlayEntries.isNotEmpty);
    assert(newRoute.overlayEntries.isEmpty);
    assert(!overlay.debugIsVisible(oldRoute.overlayEntries.last));
    setState(() {
      final int index = _history.indexOf(oldRoute);
      assert(index >= 0);
      newRoute._navigator = this;
      newRoute.install(oldRoute.overlayEntries.last);
      _history[index] = newRoute;
      newRoute.didReplace(oldRoute);
      if (index + 1 < _history.length) {
        newRoute.didChangeNext(_history[index + 1]);
        _history[index + 1].didChangePrevious(newRoute);
      } else {
        newRoute.didChangeNext(null);
      }
      if (index > 0)
        _history[index - 1].didChangeNext(newRoute);
      oldRoute.dispose();
    });
    assert(() { _debugLocked = false; return true; }());
  }

  /// Push the [newRoute] and dispose the old current Route.
  ///
  /// The new route and the route below the new route (if any) are notified
  /// (see [Route.didPush] and [Route.didChangeNext]). The navigator observer
  /// is not notified about the old route. The old route is disposed (see
  /// [Route.dispose]). The new route is not notified when the old route
  /// is removed (which happens when the new route's animation completes).
  ///
  /// If a [result] is provided, it will be the return value of the old route,
  /// as if the old route had been popped.
  Future<dynamic> pushReplacement(Route<dynamic> newRoute, { dynamic result }) {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; }());
    final Route<dynamic> oldRoute = _history.last;
    assert(oldRoute != null && oldRoute._navigator == this);
    assert(oldRoute.overlayEntries.isNotEmpty);
    assert(newRoute._navigator == null);
    assert(newRoute.overlayEntries.isEmpty);
    setState(() {
      final int index = _history.length - 1;
      assert(index >= 0);
      assert(_history.indexOf(oldRoute) == index);
      newRoute._navigator = this;
      newRoute.install(_currentOverlayEntry);
      _history[index] = newRoute;
      newRoute.didPush().whenCompleteOrCancel(() {
        // The old route's exit is not animated. We're assuming that the
        // new route completely obscures the old one.
        if (mounted) {
          oldRoute
            ..didComplete(result ?? oldRoute.currentResult)
            ..dispose();
        }
      });
      newRoute.didChangeNext(null);
      if (index > 0)
        _history[index - 1].didChangeNext(newRoute);
      for (NavigatorObserver observer in widget.observers)
        observer.didPush(newRoute, oldRoute);
    });
    assert(() { _debugLocked = false; return true; }());
    _cancelActivePointers();
    return newRoute.popped;
  }

  /// Push the route named [name] and dispose the old current route.
  ///
  /// The route name will be passed to [Navigator.onGenerateRoute]. The returned
  /// route will be pushed into the navigator.
  ///
  /// Returns a [Future] that completes to the `result` value passed to [pop]
  /// when the pushed route is popped off the navigator.
  Future<dynamic> pushReplacementNamed(String name, { dynamic result }) {
    return pushReplacement(_routeNamed(name), result: result);
  }

  /// Replaces a route that is not currently visible with a new route.
  ///
  /// The route to be removed is the one below the given `anchorRoute`. That
  /// route must not be the first route in the history.
  ///
  /// In every other way, this acts the same as [replace].
  void replaceRouteBelow({ @required Route<dynamic> anchorRoute, Route<dynamic> newRoute }) {
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
  /// route above the removed route, if any, is also notified (see
  /// [Route.didChangePrevious]). The navigator observer is not notified.
  void removeRouteBelow(Route<dynamic> anchorRoute) {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; }());
    assert(anchorRoute._navigator == this);
    final int index = _history.indexOf(anchorRoute) - 1;
    assert(index >= 0);
    final Route<dynamic> targetRoute = _history[index];
    assert(targetRoute._navigator == this);
    assert(targetRoute.overlayEntries.isEmpty || !overlay.debugIsVisible(targetRoute.overlayEntries.last));
    setState(() {
      _history.removeAt(index);
      final Route<dynamic> nextRoute = index < _history.length ? _history[index] : null;
      final Route<dynamic> previousRoute = index > 0 ? _history[index - 1] : null;
      if (previousRoute != null)
        previousRoute.didChangeNext(nextRoute);
      if (nextRoute != null)
        nextRoute.didChangePrevious(previousRoute);
      targetRoute.dispose();
    });
    assert(() { _debugLocked = false; return true; }());
  }

  /// Push the given route and then remove all the previous routes until the
  /// `predicate` returns true.
  ///
  /// The predicate may be applied to the same route more than once if
  /// [Route.willHandlePopInternally] is true.
  ///
  /// To remove routes until a route with a certain name, use the
  /// [RoutePredicate] returned from [ModalRoute.withName].
  ///
  /// To remove all the routes before the pushed route, use a [RoutePredicate]
  /// that always returns false.
  Future<dynamic> pushAndRemoveUntil(Route<dynamic> newRoute, RoutePredicate predicate) {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; }());
    final List<Route<dynamic>> removedRoutes = <Route<dynamic>>[];
    while (_history.isNotEmpty && !predicate(_history.last)) {
      final Route<dynamic> removedRoute = _history.removeLast();
      assert(removedRoute != null && removedRoute._navigator == this);
      assert(removedRoute.overlayEntries.isNotEmpty);
      removedRoutes.add(removedRoute);
    }
    assert(newRoute._navigator == null);
    assert(newRoute.overlayEntries.isEmpty);
    setState(() {
      final Route<dynamic> oldRoute = _history.isNotEmpty ? _history.last : null;
      newRoute._navigator = this;
      newRoute.install(_currentOverlayEntry);
      _history.add(newRoute);
      newRoute.didPush().whenCompleteOrCancel(() {
        if (mounted) {
          for (Route<dynamic> route in removedRoutes)
            route.dispose();
        }
      });
      newRoute.didChangeNext(null);
      if (oldRoute != null)
        oldRoute.didChangeNext(newRoute);
      for (NavigatorObserver observer in widget.observers)
        observer.didPush(newRoute, oldRoute);
    });
    assert(() { _debugLocked = false; return true; }());
    _cancelActivePointers();
    return newRoute.popped;
  }

  /// Push the route with the given name and then remove all the previous routes
  /// until the `predicate` returns true.
  ///
  /// The predicate may be applied to the same route more than once if
  /// [Route.willHandlePopInternally] is true.
  ///
  /// To remove routes until a route with a certain name, use the
  /// [RoutePredicate] returned from [ModalRoute.withName].
  ///
  /// To remove all the routes before the pushed route, use a [RoutePredicate]
  /// that always returns false.
  Future<dynamic> pushNamedAndRemoveUntil(String routeName, RoutePredicate predicate) {
    return pushAndRemoveUntil(_routeNamed(routeName), predicate);
  }

  /// Tries to pop the current route, first giving the active route the chance
  /// to veto the operation using [Route.willPop]. This method is typically
  /// called instead of [pop] when the user uses a back button. For example on
  /// Android it's called by the binding for the system's back button.
  ///
  /// See also:
  ///
  ///  * [Form], which provides a [Form.onWillPop] callback that enables the form
  ///    to veto a [maybePop] initiated by the app's back button.
  ///  * [WillPopScope], a widget that hooks into the route's [Route.willPop]
  ///    mechanism.
  ///  * [ModalRoute], which has as a [ModalRoute.willPop] method that can be
  ///    defined by a list of [WillPopCallback]s.
  Future<bool> maybePop([dynamic result]) async {
    final Route<dynamic> route = _history.last;
    assert(route._navigator == this);
    final RoutePopDisposition disposition = await route.willPop();
    if (disposition != RoutePopDisposition.bubble && mounted) {
      if (disposition == RoutePopDisposition.pop)
        pop(result);
      return true;
    }
    return false;
  }

  /// Removes the top route in the [Navigator]'s history.
  ///
  /// If an argument is provided, that argument will be the return value of the
  /// route (see [Route.didPop]).
  ///
  /// If there are any routes left on the history, the top remaining route is
  /// notified (see [Route.didPopNext]), and the method returns true. In that
  /// case, if the [Navigator] has any [Navigator.observers], they will be notified
  /// as well (see [NavigatorObserver.didPop]). Otherwise, if the popped route
  /// was the last route, the method returns false.
  ///
  /// Ongoing gestures within the current route are canceled when a route is
  /// popped.
  bool pop([dynamic result]) {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; }());
    final Route<dynamic> route = _history.last;
    assert(route._navigator == this);
    bool debugPredictedWouldPop;
    assert(() { debugPredictedWouldPop = !route.willHandlePopInternally; return true; }());
    if (route.didPop(result ?? route.currentResult)) {
      assert(debugPredictedWouldPop);
      if (_history.length > 1) {
        setState(() {
          // We use setState to guarantee that we'll rebuild, since the routes
          // can't do that for themselves, even if they have changed their own
          // state (e.g. ModalScope.isCurrent).
          _history.removeLast();
          // If route._navigator is null, the route called finalizeRoute from
          // didPop, which means the route has already been disposed and doesn't
          // need to be added to _poppedRoutes for later disposal.
          if (route._navigator != null)
            _poppedRoutes.add(route);
          _history.last.didPopNext(route);
          for (NavigatorObserver observer in widget.observers)
            observer.didPop(route, _history.last);
        });
      } else {
        assert(() { _debugLocked = false; return true; }());
        return false;
      }
    } else {
      assert(!debugPredictedWouldPop);
    }
    assert(() { _debugLocked = false; return true; }());
    _cancelActivePointers();
    return true;
  }

  /// Immediately remove `route` and [Route.dispose] it.
  ///
  /// The route's animation does not run and the future returned from pushing
  /// the route will not complete. Ongoing input gestures are cancelled. If
  /// the [Navigator] has any [Navigator.observers], they will be notified with
  /// [NavigatorObserver.didRemove].
  ///
  /// This method is used to dismiss dropdown menus that are up when the screen's
  /// orientation changes.
  void removeRoute(Route<dynamic> route) {
    assert(route != null);
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; }());
    assert(route._navigator == this);
    final int index = _history.indexOf(route);
    assert(index != -1);
    final Route<dynamic> previousRoute = index > 0 ? _history[index - 1] : null;
    final Route<dynamic> nextRoute = (index + 1 < _history.length) ? _history[index + 1] : null;
    setState(() {
      _history.removeAt(index);
      previousRoute?.didChangeNext(nextRoute);
      nextRoute?.didChangePrevious(previousRoute);
      for (NavigatorObserver observer in widget.observers)
        observer.didRemove(route, previousRoute);
      route.dispose();
    });
    assert(() { _debugLocked = false; return true; }());
    _cancelActivePointers();
  }

  /// Complete the lifecycle for a route that has been popped off the navigator.
  ///
  /// When the navigator pops a route, the navigator retains a reference to the
  /// route in order to call [Route.dispose] if the navigator itself is removed
  /// from the tree. When the route is finished with any exit animation, the
  /// route should call this function to complete its lifecycle (e.g., to
  /// receive a call to [Route.dispose]).
  ///
  /// The given `route` must have already received a call to [Route.didPop].
  /// This function may be called directly from [Route.didPop] if [Route.didPop]
  /// will return true.
  void finalizeRoute(Route<dynamic> route) {
    _poppedRoutes.remove(route);
    route.dispose();
  }

  /// Repeatedly calls [pop] until the given `predicate` returns true.
  ///
  /// The predicate may be applied to the same route more than once if
  /// [Route.willHandlePopInternally] is true.
  ///
  /// To pop until a route with a certain name, use the [RoutePredicate]
  /// returned from [ModalRoute.withName].
  void popUntil(RoutePredicate predicate) {
    while (!predicate(_history.last))
      pop();
  }

  /// Whether this navigator can be popped.
  ///
  /// The only route that cannot be popped off the navigator is the initial
  /// route.
  bool canPop() {
    assert(_history.isNotEmpty);
    return _history.length > 1 || _history[0].willHandlePopInternally;
  }

  /// Whether a route is currently being manipulated by the user, e.g.
  /// as during an iOS back gesture.
  bool get userGestureInProgress => _userGesturesInProgress > 0;
  int _userGesturesInProgress = 0;

  /// The navigator is being controlled by a user gesture.
  ///
  /// For example, called when the user beings an iOS back gesture.
  ///
  /// When the gesture finishes, call [didStopUserGesture].
  void didStartUserGesture() {
    _userGesturesInProgress += 1;
    if (_userGesturesInProgress == 1) {
      for (NavigatorObserver observer in widget.observers)
        observer.didStartUserGesture();
    }
  }

  /// A user gesture completed.
  ///
  /// Notifies the navigator that a gesture regarding which the navigator was
  /// previously notified with [didStartUserGesture] has completed.
  void didStopUserGesture() {
    assert(_userGesturesInProgress > 0);
    _userGesturesInProgress -= 1;
    if (_userGesturesInProgress == 0) {
      for (NavigatorObserver observer in widget.observers)
        observer.didStopUserGesture();
    }
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
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      // If we're between frames (SchedulerPhase.idle) then absorb any
      // subsequent pointers from this frame. The absorbing flag will be
      // reset in the next frame, see build().
      final RenderAbsorbPointer absorber = _overlayKey.currentContext?.ancestorRenderObjectOfType(const TypeMatcher<RenderAbsorbPointer>());
      setState(() {
        absorber?.absorbing = true;
      });
    }
    _activePointers.toList().forEach(WidgetsBinding.instance.cancelPointer);
  }

  @override
  Widget build(BuildContext context) {
    assert(!_debugLocked);
    assert(_history.isNotEmpty);
    return new Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUpOrCancel,
      onPointerCancel: _handlePointerUpOrCancel,
      child: new AbsorbPointer(
        absorbing: false, // it's mutated directly by _cancelActivePointers above
        child: new FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: new Overlay(
            key: _overlayKey,
            initialEntries: _initialOverlayEntries,
          ),
        ),
      ),
    );
  }
}
