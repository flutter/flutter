// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'binding.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'heroes.dart';
import 'overlay.dart';
import 'routes.dart';
import 'ticker_provider.dart';

// Examples can assume:
// class MyPage extends Placeholder { MyPage({String title}); }
// class MyHomePage extends Placeholder { }
// NavigatorState navigator;
// BuildContext context;

/// Creates a route for the given route settings.
///
/// Used by [Navigator.onGenerateRoute].
///
/// See also:
///
///  * [Navigator], which is where all the [Route]s end up.
typedef RouteFactory = Route<dynamic> Function(RouteSettings settings);

/// Creates a series of one or more routes.
///
/// Used by [Navigator.onGenerateInitialRoutes].
typedef RouteListFactory = List<Route<dynamic>> Function(NavigatorState navigator, String initialRoute);

/// Signature for the [Navigator.popUntil] predicate argument.
typedef RoutePredicate = bool Function(Route<dynamic> route);

/// Signature for a callback that verifies that it's OK to call [Navigator.pop].
///
/// Used by [Form.onWillPop], [ModalRoute.addScopedWillPopCallback],
/// [ModalRoute.removeScopedWillPopCallback], and [WillPopScope].
typedef WillPopCallback = Future<bool> Function();

/// Signature for the [Navigator.onPopPage] callback.
///
/// This callback must call [Route.didPop] on the specified route and must
/// properly update the pages list the next time it is passed into
/// [Navigator.pages] so that it no longer includes the corresponding [Page].
/// (Otherwise, the page will be interpreted as a new page to show when the
/// [Navigator.pages] list is next updated.)
typedef PopPageCallback = bool Function(Route<dynamic> route, dynamic result);

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
  /// If [Route.willPop] returns [bubble] then the back button will be handled
  /// by the [SystemNavigator], which will usually close the application.
  bubble,
}

/// An abstraction for an entry managed by a [Navigator].
///
/// This class defines an abstract interface between the navigator and the
/// "routes" that are pushed on and popped off the navigator. Most routes have
/// visual affordances, which they place in the navigators [Overlay] using one
/// or more [OverlayEntry] objects.
///
/// See [Navigator] for more explanation of how to use a [Route] with
/// navigation, including code examples.
///
/// See [MaterialPageRoute] for a route that replaces the entire screen with a
/// platform-adaptive transition.
///
/// A route can belong to a page if the [settings] are a subclass of [Page]. A
/// page-based route, as opposed to a pageless route, is created from
/// [Page.createRoute] during [Navigator.pages] updates. The page associated
/// with this route may change during the lifetime of the route. If the
/// [Navigator] updates the page of this route, it calls [changedInternalState]
/// to notify the route that the page has been updated.
///
/// The type argument `T` is the route's return type, as used by
/// [currentResult], [popped], and [didPop]. The type `void` may be used if the
/// route does not return a value.
abstract class Route<T> {
  /// Initialize the [Route].
  ///
  /// If the [settings] are not provided, an empty [RouteSettings] object is
  /// used instead.
  Route({ RouteSettings settings }) : _settings = settings ?? const RouteSettings();

  /// The navigator that the route is in, if any.
  NavigatorState get navigator => _navigator;
  NavigatorState _navigator;

  /// The settings for this route.
  ///
  /// See [RouteSettings] for details.
  ///
  /// The settings can change during the route's lifetime. If the settings
  /// change, the route's overlays will be marked dirty (see
  /// [changedInternalState]).
  ///
  /// If the route is created from a [Page] in the [Navigator.pages] list, then
  /// this will be a [Page] subclass, and it will be updated each time its
  /// corresponding [Page] in the [Navigator.pages] has changed. Once the
  /// [Route] is removed from the history, this value stops updating (and
  /// remains with its last value).
  RouteSettings get settings => _settings;
  RouteSettings _settings;

  void _updateSettings(RouteSettings newSettings) {
    assert(newSettings != null);
    if (_settings != newSettings) {
      _settings = newSettings;
      changedInternalState();
    }
  }

  /// The overlay entries of this route.
  ///
  /// These are typically populated by [install]. The [Navigator] is in charge
  /// of adding them to and removing them from the [Overlay].
  ///
  /// There must be at least one entry in this list after [install] has been
  /// invoked.
  ///
  /// The [Navigator] will take care of keeping the entries together if the
  /// route is moved in the history.
  List<OverlayEntry> get overlayEntries => const <OverlayEntry>[];

  /// Called when the route is inserted into the navigator.
  ///
  /// Uses this to populate [overlayEntries]. There must be at least one entry in
  /// this list after [install] has been invoked. The [Navigator] will be in charge
  /// to add them to the [Overlay] or remove them from it by calling
  /// [OverlayEntry.remove].
  @protected
  @mustCallSuper
  void install() { }

  /// Called after [install] when the route is pushed onto the navigator.
  ///
  /// The returned value resolves when the push transition is complete.
  ///
  /// The [didAdd] method will be called instead of [didPush] when the route
  /// immediately appears on screen without any push transition.
  ///
  /// The [didChangeNext] and [didChangePrevious] methods are typically called
  /// immediately after this method is called.
  @protected
  @mustCallSuper
  TickerFuture didPush() {
    return TickerFuture.complete()..then<void>((void _) {
      navigator?.focusScopeNode?.requestFocus();
    });
  }

  /// Called after [install] when the route is added to the navigator.
  ///
  /// This method is called instead of [didPush] when the route immediately
  /// appears on screen without any push transition.
  ///
  /// The [didChangeNext] and [didChangePrevious] methods are typically called
  /// immediately after this method is called.
  @protected
  @mustCallSuper
  void didAdd() {
    // This TickerFuture serves two purposes. First, we want to make sure
    // animations triggered by other operations finish before focusing the
    // navigator. Second, navigator.focusScopeNode might acquire more focused
    // children in Route.install asynchronously. This TickerFuture will wait for
    // it to finish first.
    //
    // The later case can be found when subclasses manage their own focus scopes.
    // For example, ModalRoute create a focus scope in its overlay entries. The
    // focused child can only be attached to navigator after initState which
    // will be guarded by the asynchronous gap.
    TickerFuture.complete().then<void>((void _) {
      // The route can be disposed before the ticker future completes. This can
      // happen when the navigator is under a TabView that warps from one tab to
      // another, non-adjacent tab, with an animation. The TabView reorders its
      // children before and after the warping completes, and that causes its
      // children to be built and disposed within the same frame. If one of its
      // children contains a navigator, the routes in that navigator are also
      // added and disposed within that frame.
      //
      // Since the reference to the navigator will be set to null after it is
      // disposed, we have to do a null-safe operation in case that happens
      // within the same frame when it is added.
      navigator?.focusScopeNode?.requestFocus();
    });
  }

  /// Called after [install] when the route replaced another in the navigator.
  ///
  /// The [didChangeNext] and [didChangePrevious] methods are typically called
  /// immediately after this method is called.
  @protected
  @mustCallSuper
  void didReplace(Route<dynamic> oldRoute) { }

  /// Returns whether calling [Navigator.maybePop] when this [Route] is current
  /// ([isCurrent]) should do anything.
  ///
  /// [Navigator.maybePop] is usually used instead of [Navigator.pop] to handle
  /// the system back button.
  ///
  /// By default, if a [Route] is the first route in the history (i.e., if
  /// [isFirst]), it reports that pops should be bubbled
  /// ([RoutePopDisposition.bubble]). This behavior prevents the user from
  /// popping the first route off the history and being stranded at a blank
  /// screen; instead, the larger scope is popped (e.g. the application quits,
  /// so that the user returns to the previous application).
  ///
  /// In other cases, the default behaviour is to accept the pop
  /// ([RoutePopDisposition.pop]).
  ///
  /// The third possible value is [RoutePopDisposition.doNotPop], which causes
  /// the pop request to be ignored entirely.
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

  /// Whether calling [didPop] would return false.
  bool get willHandlePopInternally => false;

  /// When this route is popped (see [Navigator.pop]) if the result isn't
  /// specified or if it's null, this value will be used instead.
  ///
  /// This fallback is implemented by [didComplete]. This value is used if the
  /// argument to that method is null.
  T get currentResult => null;

  /// A future that completes when this route is popped off the navigator.
  ///
  /// The future completes with the value given to [Navigator.pop], if any, or
  /// else the value of [currentResult]. See [didComplete] for more discussion
  /// on this topic.
  Future<T> get popped => _popCompleter.future;
  final Completer<T> _popCompleter = Completer<T>();

  /// A request was made to pop this route. If the route can handle it
  /// internally (e.g. because it has its own stack of internal state) then
  /// return false, otherwise return true (by returning the value of calling
  /// `super.didPop`). Returning false will prevent the default behavior of
  /// [NavigatorState.pop].
  ///
  /// When this function returns true, the navigator removes this route from
  /// the history but does not yet call [dispose]. Instead, it is the route's
  /// responsibility to call [NavigatorState.finalizeRoute], which will in turn
  /// call [dispose] on the route. This sequence lets the route perform an
  /// exit animation (or some other visual effect) after being popped but prior
  /// to being disposed.
  ///
  /// This method should call [didComplete] to resolve the [popped] future (and
  /// this is all that the default implementation does); routes should not wait
  /// for their exit animation to complete before doing so.
  ///
  /// See [popped], [didComplete], and [currentResult] for a discussion of the
  /// `result` argument.
  @mustCallSuper
  bool didPop(T result) {
    didComplete(result);
    return true;
  }

  /// The route was popped or is otherwise being removed somewhat gracefully.
  ///
  /// This is called by [didPop] and in response to
  /// [NavigatorState.pushReplacement]. If [didPop] was not called, then the
  /// [NavigatorState.finalizeRoute] method must be called immediately, and no exit
  /// animation will run.
  ///
  /// The [popped] future is completed by this method. The `result` argument
  /// specifies the value that this future is completed with, unless it is null,
  /// in which case [currentResult] is used instead.
  ///
  /// This should be called before the pop animation, if any, takes place,
  /// though in some cases the animation may be driven by the user before the
  /// route is committed to being popped; this can in particular happen with the
  /// iOS-style back gesture. See [NavigatorState.didStartUserGesture].
  @protected
  @mustCallSuper
  void didComplete(T result) {
    _popCompleter.complete(result ?? currentResult);
  }

  /// The given route, which was above this one, has been popped off the
  /// navigator.
  ///
  /// This route is now the current route ([isCurrent] is now true), and there
  /// is no next route.
  @protected
  @mustCallSuper
  void didPopNext(Route<dynamic> nextRoute) { }

  /// This route's next route has changed to the given new route.
  ///
  /// This is called on a route whenever the next route changes for any reason,
  /// so long as it is in the history, including when a route is first added to
  /// a [Navigator] (e.g. by [Navigator.push]), except for cases when
  /// [didPopNext] would be called.
  ///
  /// The `nextRoute` argument will be null if there's no new next route (i.e.
  /// if [isCurrent] is true).
  @protected
  @mustCallSuper
  void didChangeNext(Route<dynamic> nextRoute) { }

  /// This route's previous route has changed to the given new route.
  ///
  /// This is called on a route whenever the previous route changes for any
  /// reason, so long as it is in the history, except for immediately after the
  /// route itself has been pushed (in which case [didPush] or [didReplace] will
  /// be called instead).
  ///
  /// The `previousRoute` argument will be null if there's no previous route
  /// (i.e. if [isFirst] is true).
  @protected
  @mustCallSuper
  void didChangePrevious(Route<dynamic> previousRoute) { }

  /// Called whenever the internal state of the route has changed.
  ///
  /// This should be called whenever [willHandlePopInternally], [didPop],
  /// [ModalRoute.offstage], or other internal state of the route changes value.
  /// It is used by [ModalRoute], for example, to report the new information via
  /// its inherited widget to any children of the route.
  ///
  /// See also:
  ///
  ///  * [changedExternalState], which is called when the [Navigator] rebuilds.
  @protected
  @mustCallSuper
  void changedInternalState() { }

  /// Called whenever the [Navigator] has its widget rebuilt, to indicate that
  /// the route may wish to rebuild as well.
  ///
  /// This is called by the [Navigator] whenever the [NavigatorState]'s
  /// [State.widget] changes, for example because the [MaterialApp] has been rebuilt.
  /// This ensures that routes that directly refer to the state of the widget
  /// that built the [MaterialApp] will be notified when that widget rebuilds,
  /// since it would otherwise be difficult to notify the routes that state they
  /// depend on may have changed.
  ///
  /// See also:
  ///
  ///  * [changedInternalState], the equivalent but for changes to the internal
  ///    state of the route.
  @protected
  @mustCallSuper
  void changedExternalState() { }

  /// Discards any resources used by the object.
  ///
  /// This method should not remove its [overlayEntries] from the [Overlay]. The
  /// object's owner is in charge of doing that.
  ///
  /// After this is called, the object is not in a usable state and should be
  /// discarded.
  ///
  /// This method should only be called by the object's owner; typically the
  /// [Navigator] owns a route and so will call this method when the route is
  /// removed, after which the route is no longer referenced by the navigator.
  @mustCallSuper
  @protected
  void dispose() {
    _navigator = null;
  }

  /// Whether this route is the top-most route on the navigator.
  ///
  /// If this is true, then [isActive] is also true.
  bool get isCurrent {
    if (_navigator == null)
      return false;
    final _RouteEntry currentRouteEntry = _navigator._history.lastWhere(
      _RouteEntry.isPresentPredicate,
      orElse: () => null,
    );
    if (currentRouteEntry == null)
      return false;
    return currentRouteEntry.route == this;
  }

  /// Whether this route is the bottom-most route on the navigator.
  ///
  /// If this is true, then [Navigator.canPop] will return false if this route's
  /// [willHandlePopInternally] returns false.
  ///
  /// If [isFirst] and [isCurrent] are both true then this is the only route on
  /// the navigator (and [isActive] will also be true).
  bool get isFirst {
    if (_navigator == null)
      return false;
    final _RouteEntry currentRouteEntry = _navigator._history.firstWhere(
      _RouteEntry.isPresentPredicate,
      orElse: () => null,
    );
    if (currentRouteEntry == null)
      return false;
    return currentRouteEntry.route == this;
  }

  /// Whether this route is on the navigator.
  ///
  /// If the route is not only active, but also the current route (the top-most
  /// route), then [isCurrent] will also be true. If it is the first route (the
  /// bottom-most route), then [isFirst] will also be true.
  ///
  /// If a higher route is entirely opaque, then the route will be active but not
  /// rendered. It is even possible for the route to be active but for the stateful
  /// widgets within the route to not be instantiated. See [ModalRoute.maintainState].
  bool get isActive {
    if (_navigator == null)
      return false;
    return _navigator._history.firstWhere(
      _RouteEntry.isRoutePredicate(this),
      orElse: () => null,
    )?.isPresent == true;
  }
}

/// Data that might be useful in constructing a [Route].
@immutable
class RouteSettings {
  /// Creates data used to construct routes.
  const RouteSettings({
    this.name,
    this.arguments,
  });

  /// Creates a copy of this route settings object with the given fields
  /// replaced with the new values.
  RouteSettings copyWith({
    String name,
    Object arguments,
  }) {
    return RouteSettings(
      name: name ?? this.name,
      arguments: arguments ?? this.arguments,
    );
  }

  /// The name of the route (e.g., "/settings").
  ///
  /// If null, the route is anonymous.
  final String name;

  /// The arguments passed to this route.
  ///
  /// May be used when building the route, e.g. in [Navigator.onGenerateRoute].
  final Object arguments;

  @override
  String toString() => '${objectRuntimeType(this, 'RouteSettings')}("$name", $arguments)';
}

/// Describes the configuration of a [Route].
///
/// The type argument `T` is the corresponding [Route]'s return type, as
/// used by [Route.currentResult], [Route.popped], and [Route.didPop].
///
/// See also:
///
///  * [Navigator.pages], which accepts a list of [Page]s and updates its routes
///    history.
abstract class Page<T> extends RouteSettings {
  /// Creates a page and initializes [key] for subclasses.
  ///
  /// The [arguments] argument must not be null.
  const Page({
    this.key,
    String name,
    Object arguments,
  }) : super(name: name, arguments: arguments);

  /// The key associated with this page.
  ///
  /// This key will be used for comparing pages in [canUpdate].
  final LocalKey key;

  /// Whether this page can be updated with the [other] page.
  ///
  /// Two pages are consider updatable if they have same the [runtimeType] and
  /// [key].
  bool canUpdate(Page<dynamic> other) {
    return other.runtimeType == runtimeType &&
           other.key == key;
  }

  /// Creates the [Route] that corresponds to this page.
  ///
  /// The created [Route] must have its [Route.settings] property set to this [Page].
  @factory
  Route<T> createRoute(BuildContext context);

  @override
  String toString() => '${objectRuntimeType(this, 'Page')}("$name", $key, $arguments)';
}

/// An interface for observing the behavior of a [Navigator].
class NavigatorObserver {
  /// The navigator that the observer is observing, if any.
  NavigatorState get navigator => _navigator;
  NavigatorState _navigator;

  /// The [Navigator] pushed `route`.
  ///
  /// The route immediately below that one, and thus the previously active
  /// route, is `previousRoute`.
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) { }

  /// The [Navigator] popped `route`.
  ///
  /// The route immediately below that one, and thus the newly active
  /// route, is `previousRoute`.
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) { }

  /// The [Navigator] removed `route`.
  ///
  /// If only one route is being removed, then the route immediately below
  /// that one, if any, is `previousRoute`.
  ///
  /// If multiple routes are being removed, then the route below the
  /// bottommost route being removed, if any, is `previousRoute`, and this
  /// method will be called once for each removed route, from the topmost route
  /// to the bottommost route.
  void didRemove(Route<dynamic> route, Route<dynamic> previousRoute) { }

  /// The [Navigator] replaced `oldRoute` with `newRoute`.
  void didReplace({ Route<dynamic> newRoute, Route<dynamic> oldRoute }) { }

  /// The [Navigator]'s routes are being moved by a user gesture.
  ///
  /// For example, this is called when an iOS back gesture starts, and is used
  /// to disabled hero animations during such interactions.
  void didStartUserGesture(Route<dynamic> route, Route<dynamic> previousRoute) { }

  /// User gesture is no longer controlling the [Navigator].
  ///
  /// Paired with an earlier call to [didStartUserGesture].
  void didStopUserGesture() { }
}

/// An inherited widget to host a hero controller.
///
/// The hosted hero controller will be picked up by the navigator in the
/// [child] subtree. Once a navigator picks up this controller, the navigator
/// will bar any navigator below its subtree from receiving this controller.
///
/// The hero controller inside the [HeroControllerScope] can only subscribe to
/// one navigator at a time. An assertion will be thrown if the hero controller
/// subscribes to more than one navigators. This can happen when there are
/// multiple navigators under the same [HeroControllerScope] in parallel.
class HeroControllerScope extends InheritedWidget {
  /// Creates a widget to host the input [controller].
  const HeroControllerScope({
    Key key,
    this.controller,
    Widget child,
  }) : assert(controller != null),
       super(key: key, child: child);

  /// Creates a widget to prevent the subtree from receiving the hero controller
  /// above.
  const HeroControllerScope.none({
    Key key,
    Widget child,
  }) : controller = null,
       super(key: key, child: child);

  /// The hero controller that is hosted inside this widget.
  final HeroController controller;

  /// Retrieves the [HeroController] from the closest [HeroControllerScope]
  /// ancestor.
  static HeroController of(BuildContext context) {
    final HeroControllerScope host = context.dependOnInheritedWidgetOfExactType<HeroControllerScope>();
    return host?.controller;
  }

  @override
  bool updateShouldNotify(HeroControllerScope oldWidget) {
    return oldWidget.controller != controller;
  }
}

/// A [Route] wrapper interface that can be staged for [TransitionDelegate] to
/// decide how its underlying [Route] should transition on or off screen.
abstract class RouteTransitionRecord {
  /// Retrieves the wrapped [Route].
  Route<dynamic> get route;

  /// Whether this route is waiting for the decision on how to enter the screen.
  ///
  /// If this property is true, this route requires an explicit decision on how
  /// to transition into the screen. Such a decision should be made in the
  /// [TransitionDelegate.resolve].
  bool get isWaitingForEnteringDecision;

  /// Whether this route is waiting for the decision on how to exit the screen.
  ///
  /// If this property is true, this route requires an explicit decision on how
  /// to transition off the screen. Such a decision should be made in the
  /// [TransitionDelegate.resolve].
  bool get isWaitingForExitingDecision;

  /// Marks the [route] to be pushed with transition.
  ///
  /// During [TransitionDelegate.resolve], this can be called on an entering
  /// route (where [RouteTransitionRecord.isWaitingForEnteringDecision] is true) in indicate that the
  /// route should be pushed onto the [Navigator] with an animated transition.
  void markForPush();

  /// Marks the [route] to be added without transition.
  ///
  /// During [TransitionDelegate.resolve], this can be called on an entering
  /// route (where [RouteTransitionRecord.isWaitingForEnteringDecision] is true) in indicate that the
  /// route should be added onto the [Navigator] without an animated transition.
  void markForAdd();

  /// Marks the [route] to be popped with transition.
  ///
  /// During [TransitionDelegate.resolve], this can be called on an exiting
  /// route to indicate that the route should be popped off the [Navigator] with
  /// an animated transition.
  void markForPop([dynamic result]);

  /// Marks the [route] to be completed without transition.
  ///
  /// During [TransitionDelegate.resolve], this can be called on an exiting
  /// route to indicate that the route should be completed with the provided
  /// result and removed from the [Navigator] without an animated transition.
  void markForComplete([dynamic result]);

  /// Marks the [route] to be removed without transition.
  ///
  /// During [TransitionDelegate.resolve], this can be called on an exiting
  /// route to indicate that the route should be removed from the [Navigator]
  /// without completing and without an animated transition.
  void markForRemove();
}

/// The delegate that decides how pages added and removed from [Navigator.pages]
/// transition in or out of the screen.
///
/// This abstract class implements the API to be called by [Navigator] when it
/// requires explicit decisions on how the routes transition on or off the screen.
///
/// To make route transition decisions, subclass must implement [resolve].
///
/// {@tool sample --template=freeform}
/// The following example demonstrates how to implement a subclass that always
/// removes or adds routes without animated transitions and puts the removed
/// routes at the top of the list.
///
/// ```dart imports
/// import 'package:flutter/widgets.dart';
/// ```
///
/// ```dart
/// class NoAnimationTransitionDelegate extends TransitionDelegate<void> {
///   @override
///   Iterable<RouteTransitionRecord> resolve({
///     List<RouteTransitionRecord> newPageRouteHistory,
///     Map<RouteTransitionRecord, RouteTransitionRecord> locationToExitingPageRoute,
///     Map<RouteTransitionRecord, List<RouteTransitionRecord>> pageRouteToPagelessRoutes,
///   }) {
///     final List<RouteTransitionRecord> results = <RouteTransitionRecord>[];
///
///     for (final RouteTransitionRecord pageRoute in newPageRouteHistory) {
///       if (pageRoute.isWaitingForEnteringDecision) {
///         pageRoute.markForAdd();
///       }
///       results.add(pageRoute);
///
///     }
///     for (final RouteTransitionRecord exitingPageRoute in locationToExitingPageRoute.values) {
///       if (exitingPageRoute.isWaitingForExitingDecision) {
///        exitingPageRoute.markForRemove();
///        final List<RouteTransitionRecord> pagelessRoutes = pageRouteToPagelessRoutes[exitingPageRoute];
///        if (pagelessRoutes != null) {
///          for (final RouteTransitionRecord pagelessRoute in pagelessRoutes) {
///             pagelessRoute.markForRemove();
///           }
///        }
///       }
///       results.add(exitingPageRoute);
///
///     }
///     return results;
///   }
/// }
///
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Navigator.transitionDelegate], which uses this class to make route
///    transition decisions.
///  * [DefaultTransitionDelegate], which implements the default way to decide
///    how routes transition in or out of the screen.
abstract class TransitionDelegate<T> {
  /// Creates a delegate and enables subclass to create a constant class.
  const TransitionDelegate();

  Iterable<RouteTransitionRecord> _transition({
    List<RouteTransitionRecord> newPageRouteHistory,
    Map<RouteTransitionRecord, RouteTransitionRecord> locationToExitingPageRoute,
    Map<RouteTransitionRecord, List<RouteTransitionRecord>> pageRouteToPagelessRoutes,
  }) {
    final Iterable<RouteTransitionRecord> results = resolve(
      newPageRouteHistory: newPageRouteHistory,
      locationToExitingPageRoute: locationToExitingPageRoute,
      pageRouteToPagelessRoutes: pageRouteToPagelessRoutes,
    );
    // Verifies the integrity after the decisions have been made.
    //
    // Here are the rules:
    // - All the entering routes in newPageRouteHistory must either be pushed or
    //   added.
    // - All the exiting routes in locationToExitingPageRoute must either be
    //   popped, completed or removed.
    // - All the pageless routes that belong to exiting routes must either be
    //   popped, completed or removed.
    // - All the entering routes in the result must preserve the same order as
    //   the entering routes in newPageRouteHistory, and the result must contain
    //   all exiting routes.
    //     ex:
    //
    //     newPageRouteHistory = [A, B, C]
    //
    //     locationToExitingPageRoute = {A -> D, C -> E}
    //
    //     results = [A, B ,C ,D ,E] is valid
    //     results = [D, A, B ,C ,E] is also valid because exiting route can be
    //     inserted in any place
    //
    //     results = [B, A, C ,D ,E] is invalid because B must be after A.
    //     results = [A, B, C ,E] is invalid because results must include D.
    assert(() {
      final List<RouteTransitionRecord> resultsToVerify = results.toList(growable: false);
      final Set<RouteTransitionRecord> exitingPageRoutes = locationToExitingPageRoute.values.toSet();
      // Firstly, verifies all exiting routes have been marked.
      for (final RouteTransitionRecord exitingPageRoute in exitingPageRoutes) {
        assert(!exitingPageRoute.isWaitingForExitingDecision);
        if (pageRouteToPagelessRoutes.containsKey(exitingPageRoute)) {
          for (final RouteTransitionRecord pagelessRoute in pageRouteToPagelessRoutes[exitingPageRoute]) {
            assert(!pagelessRoute.isWaitingForExitingDecision);
          }
        }
      }
      // Secondly, verifies the order of results matches the newPageRouteHistory
      // and contains all the exiting routes.
      int indexOfNextRouteInNewHistory = 0;

      for (final _RouteEntry routeEntry in resultsToVerify.cast<_RouteEntry>()) {
        assert(routeEntry != null);
        assert(!routeEntry.isWaitingForEnteringDecision && !routeEntry.isWaitingForExitingDecision);
        if (
          indexOfNextRouteInNewHistory >= newPageRouteHistory.length ||
          routeEntry != newPageRouteHistory[indexOfNextRouteInNewHistory]
        ) {
          assert(exitingPageRoutes.contains(routeEntry));
          exitingPageRoutes.remove(routeEntry);
        } else {
          indexOfNextRouteInNewHistory += 1;
        }
      }

      assert(
        indexOfNextRouteInNewHistory == newPageRouteHistory.length &&
        exitingPageRoutes.isEmpty,
        'The merged result from the $runtimeType.resolve does not include all '
        'required routes. Do you remember to merge all exiting routes?'
      );
      return true;
    }());

    return results;
  }

  /// A method that will be called by the [Navigator] to decide how routes
  /// transition in or out of the screen when [Navigator.pages] is updated.
  ///
  /// The `newPageRouteHistory` list contains all page-based routes in the order
  /// that will be on the [Navigator]'s history stack after this update
  /// completes. If a route in `newPageRouteHistory` has its
  /// [RouteTransitionRecord.isWaitingForEnteringDecision] set to true, this
  /// route requires explicit decision on how it should transition onto the
  /// Navigator. To make a decision, call [RouteTransitionRecord.markForPush] or
  /// [RouteTransitionRecord.markForAdd].
  ///
  /// The `locationToExitingPageRoute` contains the pages-based routes that
  /// are removed from the routes history after page update. This map records
  /// page-based routes to be removed with the location of the route in the
  /// original route history before the update. The keys are the locations
  /// represented by the page-based routes that are directly below the removed
  /// routes, and the value are the page-based routes to be removed. The
  /// location is null if the route to be removed is the bottom most route. If
  /// a route in `locationToExitingPageRoute` has its
  /// [RouteTransitionRecord.isWaitingForExitingDecision] set to true, this
  /// route requires explicit decision on how it should transition off the
  /// Navigator. To make a decision for a removed route, call
  /// [RouteTransitionRecord.markForPop],
  /// [RouteTransitionRecord.markForComplete] or
  /// [RouteTransitionRecord.markForRemove]. It is possible that decisions are
  /// not required for routes in the `locationToExitingPageRoute`. This can
  /// happen if the routes have already been popped in earlier page updates and
  /// are still waiting for popping animations to finish. In such case, those
  /// routes are still included in the `locationToExitingPageRoute` with their
  /// [RouteTransitionRecord.isWaitingForExitingDecision] set to false and no
  /// decisions are required.
  ///
  /// The `pageRouteToPagelessRoutes` records the page-based routes and their
  /// associated pageless routes. If a page-based route is waiting for exiting
  /// decision, its associated pageless routes also require explicit decisions
  /// on how to transition off the screen.
  ///
  /// Once all the decisions have been made, this method must merge the removed
  /// routes (whether or not they require decisions) and the
  /// `newPageRouteHistory` and return the merged result. The order in the
  /// result will be the order the [Navigator] uses for updating the route
  /// history. The return list must preserve the same order of routes in
  /// `newPageRouteHistory`. The removed routes, however, can be inserted into
  /// the return list freely as long as all of them are included.
  ///
  /// For example, consider the following case.
  ///
  /// newPageRouteHistory = [A, B, C]
  ///
  /// locationToExitingPageRoute = {A -> D, C -> E}
  ///
  /// The following outputs are valid.
  ///
  /// result = [A, B ,C ,D ,E] is valid.
  /// result = [D, A, B ,C ,E] is also valid because exiting route can be
  /// inserted in any place.
  ///
  /// The following outputs are invalid.
  ///
  /// result = [B, A, C ,D ,E] is invalid because B must be after A.
  /// result = [A, B, C ,E] is invalid because results must include D.
  ///
  /// See also:
  ///
  ///  * [RouteTransitionRecord.markForPush], which makes route enter the screen
  ///    with an animated transition.
  ///  * [RouteTransitionRecord.markForAdd], which makes route enter the screen
  ///    without an animated transition.
  ///  * [RouteTransitionRecord.markForPop], which makes route exit the screen
  ///    with an animated transition.
  ///  * [RouteTransitionRecord.markForRemove], which does not complete the
  ///    route and makes it exit the screen without an animated transition.
  ///  * [RouteTransitionRecord.markForComplete], which completes the route and
  ///    makes it exit the screen without an animated transition.
  ///  * [DefaultTransitionDelegate.resolve], which implements the default way
  ///    to decide how routes transition in or out of the screen.
  Iterable<RouteTransitionRecord> resolve({
    List<RouteTransitionRecord> newPageRouteHistory,
    Map<RouteTransitionRecord, RouteTransitionRecord> locationToExitingPageRoute,
    Map<RouteTransitionRecord, List<RouteTransitionRecord>> pageRouteToPagelessRoutes,
  });
}

/// The default implementation of [TransitionDelegate] that the [Navigator] will
/// use if its [Navigator.transitionDelegate] is not specified.
///
/// This transition delegate follows two rules. Firstly, all the entering routes
/// are placed on top of the exiting routes if they are at the same location.
/// Secondly, the top most route will always transition with an animated transition.
/// All the other routes below will either be completed with
/// [Route.currentResult] or added without an animated transition.
class DefaultTransitionDelegate<T> extends TransitionDelegate<T> {
  /// Creates a default transition delegate.
  const DefaultTransitionDelegate() : super();

  @override
  Iterable<RouteTransitionRecord> resolve({
    List<RouteTransitionRecord> newPageRouteHistory,
    Map<RouteTransitionRecord, RouteTransitionRecord> locationToExitingPageRoute,
    Map<RouteTransitionRecord, List<RouteTransitionRecord>> pageRouteToPagelessRoutes,
  }) {
    final List<RouteTransitionRecord> results = <RouteTransitionRecord>[];
    // This method will handle the exiting route and its corresponding pageless
    // route at this location. It will also recursively check if there is any
    // other exiting routes above it and handle them accordingly.
    void handleExitingRoute(RouteTransitionRecord location, bool isLast) {
      final RouteTransitionRecord exitingPageRoute = locationToExitingPageRoute[location];
      if (exitingPageRoute == null)
        return;
      if (exitingPageRoute.isWaitingForExitingDecision) {
        final bool hasPagelessRoute = pageRouteToPagelessRoutes.containsKey(exitingPageRoute);
        final bool isLastExitingPageRoute = isLast && !locationToExitingPageRoute.containsKey(exitingPageRoute);
        if (isLastExitingPageRoute && !hasPagelessRoute) {
          exitingPageRoute.markForPop(exitingPageRoute.route.currentResult);
        } else {
          exitingPageRoute.markForComplete(exitingPageRoute.route.currentResult);
        }
        if (hasPagelessRoute) {
          final List<RouteTransitionRecord> pagelessRoutes = pageRouteToPagelessRoutes[exitingPageRoute];
          for (final RouteTransitionRecord pagelessRoute in pagelessRoutes) {
            assert(pagelessRoute.isWaitingForExitingDecision);
            if (isLastExitingPageRoute && pagelessRoute == pagelessRoutes.last) {
              pagelessRoute.markForPop(pagelessRoute.route.currentResult);
            } else {
              pagelessRoute.markForComplete(pagelessRoute.route.currentResult);
            }
          }
        }
      }
      results.add(exitingPageRoute);

      // It is possible there is another exiting route above this exitingPageRoute.
      handleExitingRoute(exitingPageRoute, isLast);
    }

    // Handles exiting route in the beginning of list.
    handleExitingRoute(null, newPageRouteHistory.isEmpty);

    for (final RouteTransitionRecord pageRoute in newPageRouteHistory) {
      final bool isLastIteration = newPageRouteHistory.last == pageRoute;
      if (pageRoute.isWaitingForEnteringDecision) {
        if (!locationToExitingPageRoute.containsKey(pageRoute) && isLastIteration) {
          pageRoute.markForPush();
        } else {
          pageRoute.markForAdd();
        }
      }
      results.add(pageRoute);
      handleExitingRoute(pageRoute, isLastIteration);
    }
    return results;
  }
}

/// A widget that manages a set of child widgets with a stack discipline.
///
/// Many apps have a navigator near the top of their widget hierarchy in order
/// to display their logical history using an [Overlay] with the most recently
/// visited pages visually on top of the older pages. Using this pattern lets
/// the navigator visually transition from one page to another by moving the widgets
/// around in the overlay. Similarly, the navigator can be used to show a dialog
/// by positioning the dialog widget above the current page.
///
/// ## Using the Navigator API
///
/// Mobile apps typically reveal their contents via full-screen elements
/// called "screens" or "pages". In Flutter these elements are called
/// routes and they're managed by a [Navigator] widget. The navigator
/// manages a stack of [Route] objects and provides two ways for managing
/// the stack, the declarative API [Navigator.pages] or imperative API
/// [Navigator.push] and [Navigator.pop].
///
/// When your user interface fits this paradigm of a stack, where the user
/// should be able to _navigate_ back to an earlier element in the stack,
/// the use of routes and the Navigator is appropriate. On certain platforms,
/// such as Android, the system UI will provide a back button (outside the
/// bounds of your application) that will allow the user to navigate back
/// to earlier routes in your application's stack. On platforms that don't
/// have this build-in navigation mechanism, the use of an [AppBar] (typically
/// used in the [Scaffold.appBar] property) can automatically add a back
/// button for user navigation.
///
/// ## Using the Pages API
///
/// The [Navigator] will convert its [Navigator.pages] into a stack of [Route]s
/// if it is provided. A change in [Navigator.pages] will trigger an update to
/// the stack of [Route]s. The [Navigator] will update its routes to match the
/// new configuration of its [Navigator.pages]. To use this API, one can create
/// a [Page] subclass and defines a list of [Page]s for [Navigator.pages]. A
/// [Navigator.onPopPage] callback is also required to properly clean up the
/// input pages in case of a pop.
///
/// By Default, the [Navigator] will use [DefaultTransitionDelegate] to decide
/// how routes transition in or out of the screen. To customize it, define a
/// [TransitionDelegate] subclass and provide it to the
/// [Navigator.transitionDelegate].
///
/// ### Displaying a full-screen route
///
/// Although you can create a navigator directly, it's most common to use the
/// navigator created by the `Router` which itself is created and configured by
/// a [WidgetsApp] or a [MaterialApp] widget. You can refer to that navigator
/// with [Navigator.of].
///
/// A [MaterialApp] is the simplest way to set things up. The [MaterialApp]'s
/// home becomes the route at the bottom of the [Navigator]'s stack. It is what
/// you see when the app is launched.
///
/// ```dart
/// void main() {
///   runApp(MaterialApp(home: MyAppHome()));
/// }
/// ```
///
/// To push a new route on the stack you can create an instance of
/// [MaterialPageRoute] with a builder function that creates whatever you
/// want to appear on the screen. For example:
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute<void>(
///   builder: (BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('My Page')),
///       body: Center(
///         child: TextButton(
///           child: Text('POP'),
///           onPressed: () {
///             Navigator.pop(context);
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
/// Navigator.pop(context);
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
///   runApp(MaterialApp(
///     home: MyAppHome(), // becomes the route named '/'
///     routes: <String, WidgetBuilder> {
///       '/a': (BuildContext context) => MyPage(title: 'page A'),
///       '/b': (BuildContext context) => MyPage(title: 'page B'),
///       '/c': (BuildContext context) => MyPage(title: 'page C'),
///     },
///   ));
/// }
/// ```
///
/// To show a route by name:
///
/// ```dart
/// Navigator.pushNamed(context, '/b');
/// ```
///
/// ### Routes can return a value
///
/// When a route is pushed to ask the user for a value, the value can be
/// returned via the [pop] method's result parameter.
///
/// Methods that push a route return a [Future]. The Future resolves when the
/// route is popped and the [Future]'s value is the [pop] method's `result`
/// parameter.
///
/// For example if we wanted to ask the user to press 'OK' to confirm an
/// operation we could `await` the result of [Navigator.push]:
///
/// ```dart
/// bool value = await Navigator.push(context, MaterialPageRoute<bool>(
///   builder: (BuildContext context) {
///     return Center(
///       child: GestureDetector(
///         child: Text('OK'),
///         onTap: () { Navigator.pop(context, true); }
///       ),
///     );
///   }
/// ));
/// ```
///
/// If the user presses 'OK' then value will be true. If the user backs
/// out of the route, for example by pressing the Scaffold's back button,
/// the value will be null.
///
/// When a route is used to return a value, the route's type parameter must
/// match the type of [pop]'s result. That's why we've used
/// `MaterialPageRoute<bool>` instead of `MaterialPageRoute<void>` or just
/// `MaterialPageRoute`. (If you prefer to not specify the types, though, that's
/// fine too.)
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
/// The [PageRouteBuilder] class makes it possible to define a custom route
/// in terms of callbacks. Here's an example that rotates and fades its child
/// when the route appears or disappears. This route does not obscure the entire
/// screen because it specifies `opaque: false`, just as a popup route does.
///
/// ```dart
/// Navigator.push(context, PageRouteBuilder(
///   opaque: false,
///   pageBuilder: (BuildContext context, _, __) {
///     return Center(child: Text('My PageRoute'));
///   },
///   transitionsBuilder: (___, Animation<double> animation, ____, Widget child) {
///     return FadeTransition(
///       opacity: animation,
///       child: RotationTransition(
///         turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
///         child: child,
///       ),
///     );
///   }
/// ));
/// ```
///
/// The page route is built in two parts, the "page" and the
/// "transitions". The page becomes a descendant of the child passed to
/// the `transitionsBuilder` function. Typically the page is only built once,
/// because it doesn't depend on its animation parameters (elided with `_`
/// and `__` in this example). The transition is built on every frame
/// for its duration.
///
/// ### Nesting Navigators
///
/// An app can use more than one [Navigator]. Nesting one [Navigator] below
/// another [Navigator] can be used to create an "inner journey" such as tabbed
/// navigation, user registration, store checkout, or other independent journeys
/// that represent a subsection of your overall application.
///
/// #### Example
///
/// It is standard practice for iOS apps to use tabbed navigation where each
/// tab maintains its own navigation history. Therefore, each tab has its own
/// [Navigator], creating a kind of "parallel navigation."
///
/// In addition to the parallel navigation of the tabs, it is still possible to
/// launch full-screen pages that completely cover the tabs. For example: an
/// on-boarding flow, or an alert dialog. Therefore, there must exist a "root"
/// [Navigator] that sits above the tab navigation. As a result, each of the
/// tab's [Navigator]s are actually nested [Navigator]s sitting below a single
/// root [Navigator].
///
/// In practice, the nested [Navigator]s for tabbed navigation sit in the
/// [WidgetsApp] and [CupertinoTabView] widgets and do not need to be explicitly
/// created or managed.
///
/// {@tool sample --template=freeform}
/// The following example demonstrates how a nested [Navigator] can be used to
/// present a standalone user registration journey.
///
/// Even though this example uses two [Navigator]s to demonstrate nested
/// [Navigator]s, a similar result is possible using only a single [Navigator].
///
/// Run this example with `flutter run --route=/signup` to start it with
/// the signup flow instead of on the home page.
///
/// ```dart imports
/// import 'package:flutter/material.dart';
/// ```
///
/// ```dart main
/// void main() => runApp(MyApp());
/// ```
///
/// ```dart
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       title: 'Flutter Code Sample for Navigator',
///       // MaterialApp contains our top-level Navigator
///       initialRoute: '/',
///       routes: {
///         '/': (BuildContext context) => HomePage(),
///         '/signup': (BuildContext context) => SignUpPage(),
///       },
///     );
///   }
/// }
///
/// class HomePage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return DefaultTextStyle(
///       style: Theme.of(context).textTheme.headline4,
///       child: Container(
///         color: Colors.white,
///         alignment: Alignment.center,
///         child: Text('Home Page'),
///       ),
///     );
///   }
/// }
///
/// class CollectPersonalInfoPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return DefaultTextStyle(
///       style: Theme.of(context).textTheme.headline4,
///       child: GestureDetector(
///         onTap: () {
///           // This moves from the personal info page to the credentials page,
///           // replacing this page with that one.
///           Navigator.of(context)
///             .pushReplacementNamed('signup/choose_credentials');
///         },
///         child: Container(
///           color: Colors.lightBlue,
///           alignment: Alignment.center,
///           child: Text('Collect Personal Info Page'),
///         ),
///       ),
///     );
///   }
/// }
///
/// class ChooseCredentialsPage extends StatelessWidget {
///   const ChooseCredentialsPage({
///     this.onSignupComplete,
///   });
///
///   final VoidCallback onSignupComplete;
///
///   @override
///   Widget build(BuildContext context) {
///     return GestureDetector(
///       onTap: onSignupComplete,
///       child: DefaultTextStyle(
///         style: Theme.of(context).textTheme.headline4,
///         child: Container(
///           color: Colors.pinkAccent,
///           alignment: Alignment.center,
///           child: Text('Choose Credentials Page'),
///         ),
///       ),
///     );
///   }
/// }
///
/// class SignUpPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     // SignUpPage builds its own Navigator which ends up being a nested
///     // Navigator in our app.
///     return Navigator(
///       initialRoute: 'signup/personal_info',
///       onGenerateRoute: (RouteSettings settings) {
///         WidgetBuilder builder;
///         switch (settings.name) {
///           case 'signup/personal_info':
///           // Assume CollectPersonalInfoPage collects personal info and then
///           // navigates to 'signup/choose_credentials'.
///             builder = (BuildContext _) => CollectPersonalInfoPage();
///             break;
///           case 'signup/choose_credentials':
///           // Assume ChooseCredentialsPage collects new credentials and then
///           // invokes 'onSignupComplete()'.
///             builder = (BuildContext _) => ChooseCredentialsPage(
///               onSignupComplete: () {
///                 // Referencing Navigator.of(context) from here refers to the
///                 // top level Navigator because SignUpPage is above the
///                 // nested Navigator that it created. Therefore, this pop()
///                 // will pop the entire "sign up" journey and return to the
///                 // "/" route, AKA HomePage.
///                 Navigator.of(context).pop();
///               },
///             );
///             break;
///           default:
///             throw Exception('Invalid route: ${settings.name}');
///         }
///         return MaterialPageRoute(builder: builder, settings: settings);
///       },
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// [Navigator.of] operates on the nearest ancestor [Navigator] from the given
/// [BuildContext]. Be sure to provide a [BuildContext] below the intended
/// [Navigator], especially in large `build` methods where nested [Navigator]s
/// are created. The [Builder] widget can be used to access a [BuildContext] at
/// a desired location in the widget subtree.
class Navigator extends StatefulWidget {
  /// Creates a widget that maintains a stack-based history of child widgets.
  ///
  /// The [onGenerateRoute], [pages], [onGenerateInitialRoutes],
  /// [transitionDelegate], [observers]  arguments must not be null.
  ///
  /// If the [pages] is not empty, the [onPopPage] must not be null.
  const Navigator({
    Key key,
    this.pages = const <Page<dynamic>>[],
    this.onPopPage,
    this.initialRoute,
    this.onGenerateInitialRoutes = Navigator.defaultGenerateInitialRoutes,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.transitionDelegate = const DefaultTransitionDelegate<dynamic>(),
    this.reportsRouteUpdateToEngine = false,
    this.observers = const <NavigatorObserver>[],
  }) : assert(pages != null),
       assert(onGenerateInitialRoutes != null),
       assert(transitionDelegate != null),
       assert(observers != null),
       assert(reportsRouteUpdateToEngine != null),
       super(key: key);

  /// The list of pages with which to populate the history.
  ///
  /// Pages are turned into routes using [Page.createRoute] in a manner
  /// analogous to how [Widget]s are turned into [Element]s (and [State]s or
  /// [RenderObject]s) using [Widget.createElement] (and
  /// [StatefulWidget.createState] or [RenderObjectWidget.createRenderObject]).
  ///
  /// When this list is updated, the new list is compared to the previous
  /// list and the set of routes is updated accordingly.
  ///
  /// Some [Route]s do not correspond to [Page] objects, namely, those that are
  /// added to the history using the [Navigator] API ([push] and friends). A
  /// [Route] that does not correspond to a [Page] object is called a pageless
  /// route and is tied to the [Route] that _does_ correspond to a [Page] object
  /// that is below it in the history.
  ///
  /// Pages that are added or removed may be animated as controlled by the
  /// [transitionDelegate]. If a page is removed that had other pageless routes
  /// pushed on top of it using [push] and friends, those pageless routes are
  /// also removed with or without animation as determined by the
  /// [transitionDelegate].
  ///
  /// To use this API, an [onPopPage] callback must also be provided to properly
  /// clean up this list if a page has been popped.
  ///
  /// If [initialRoute] is non-null when the widget is first created, then
  /// [onGenerateInitialRoutes] is used to generate routes that are above those
  /// corresponding to [pages] in the initial history.
  final List<Page<dynamic>> pages;

  /// Called when [pop] is invoked but the current [Route] corresponds to a
  /// [Page] found in the [pages] list.
  ///
  /// The `result` argument is the value with which the route is to complete
  /// (e.g. the value returned from a dialog).
  ///
  /// This callback is responsible for calling [Route.didPop] and returning
  /// whether this pop is successful.
  ///
  /// The [Navigator] widget should be rebuilt with a [pages] list that does not
  /// contain the [Page] for the given [Route]. The next time the [pages] list
  /// is updated, if the [Page] corresponding to this [Route] is still present,
  /// it will be interpreted as a new route to display.
  final PopPageCallback onPopPage;

  /// The delegate used for deciding how routes transition in or off the screen
  /// during the [pages] updates.
  ///
  /// Defaults to [DefaultTransitionDelegate] if not specified, cannot be null.
  final TransitionDelegate<dynamic> transitionDelegate;

  /// The name of the first route to show.
  ///
  /// Defaults to [Navigator.defaultRouteName].
  ///
  /// The value is interpreted according to [onGenerateInitialRoutes], which
  /// defaults to [defaultGenerateInitialRoutes].
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

  /// The name for the default route of the application.
  ///
  /// See also:
  ///
  ///  * [dart:ui.Window.defaultRouteName], which reflects the route that the
  ///    application was started with.
  static const String defaultRouteName = '/';

  /// Called when the widget is created to generate the initial list of [Route]
  /// objects if [initialRoute] is not null.
  ///
  /// Defaults to [defaultGenerateInitialRoutes].
  ///
  /// The [NavigatorState] and [initialRoute] will be passed to the callback.
  /// The callback must return a list of [Route] objects with which the history
  /// will be primed.
  final RouteListFactory onGenerateInitialRoutes;

  /// Whether this navigator should report route update message back to the
  /// engine when the top-most route changes.
  ///
  /// If the property is set to true, this navigator automatically sends the
  /// route update message to the engine when it detects top-most route changes.
  /// The messages are used by the web engine to update the browser URL bar.
  ///
  /// If there are multiple navigators in the widget tree, at most one of them
  /// can set this property to true (typically, the top-most one created from
  /// the [WidgetsApp]). Otherwise, the web engine may receive multiple route
  /// update messages from different navigators and fail to update the URL
  /// bar.
  ///
  /// Defaults to false.
  final bool reportsRouteUpdateToEngine;

  /// Push a named route onto the navigator that most tightly encloses the given
  /// context.
  ///
  /// {@template flutter.widgets.navigator.pushNamed}
  /// The route name will be passed to the [Navigator.onGenerateRoute]
  /// callback. The returned route will be pushed into the navigator.
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
  ///
  /// The `T` type argument is the type of the return value of the route.
  ///
  /// To use [pushNamed], an [Navigator.onGenerateRoute] callback must be
  /// provided,
  /// {@endtemplate}
  ///
  /// {@template flutter.widgets.navigator.pushNamed.arguments}
  /// The provided `arguments` are passed to the pushed route via
  /// [RouteSettings.arguments]. Any object can be passed as `arguments` (e.g. a
  /// [String], [int], or an instance of a custom `MyRouteArguments` class).
  /// Often, a [Map] is used to pass key-value pairs.
  ///
  /// The `arguments` may be used in [Navigator.onGenerateRoute] or
  /// [Navigator.onUnknownRoute] to construct the route.
  /// {@endtemplate}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _didPushButton() {
  ///   Navigator.pushNamed(context, '/settings');
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// {@tool snippet}
  ///
  /// The following example shows how to pass additional `arguments` to the
  /// route:
  ///
  /// ```dart
  /// void _showBerlinWeather() {
  ///   Navigator.pushNamed(
  ///     context,
  ///     '/weather',
  ///     arguments: <String, String>{
  ///       'city': 'Berlin',
  ///       'country': 'Germany',
  ///     },
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// {@tool snippet}
  ///
  /// The following example shows how to pass a custom Object to the route:
  ///
  /// ```dart
  /// class WeatherRouteArguments {
  ///   WeatherRouteArguments({ this.city, this.country });
  ///   final String city;
  ///   final String country;
  ///
  ///   bool get isGermanCapital {
  ///     return country == 'Germany' && city == 'Berlin';
  ///   }
  /// }
  ///
  /// void _showWeather() {
  ///   Navigator.pushNamed(
  ///     context,
  ///     '/weather',
  ///     arguments: WeatherRouteArguments(city: 'Berlin', country: 'Germany'),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  static Future<T> pushNamed<T extends Object>(
    BuildContext context,
    String routeName, {
    Object arguments,
   }) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Replace the current route of the navigator that most tightly encloses the
  /// given context by pushing the route named [routeName] and then disposing
  /// the previous route once the new route has finished animating in.
  ///
  /// {@template flutter.widgets.navigator.pushReplacementNamed}
  /// If non-null, `result` will be used as the result of the route that is
  /// removed; the future that had been returned from pushing that old route
  /// will complete with `result`. Routes such as dialogs or popup menus
  /// typically use this mechanism to return the value selected by the user to
  /// the widget that created their route. The type of `result`, if provided,
  /// must match the type argument of the class of the old route (`TO`).
  ///
  /// The route name will be passed to the [Navigator.onGenerateRoute]
  /// callback. The returned route will be pushed into the navigator.
  ///
  /// The new route and the route below the removed route are notified (see
  /// [Route.didPush] and [Route.didChangeNext]). If the [Navigator] has any
  /// [Navigator.observers], they will be notified as well (see
  /// [NavigatorObserver.didReplace]). The removed route is notified once the
  /// new route has finished animating (see [Route.didComplete]). The removed
  /// route's exit animation is not run (see [popAndPushNamed] for a variant
  /// that does animated the removed route).
  ///
  /// Ongoing gestures within the current route are canceled when a new route is
  /// pushed.
  ///
  /// Returns a [Future] that completes to the `result` value passed to [pop]
  /// when the pushed route is popped off the navigator.
  ///
  /// The `T` type argument is the type of the return value of the new route,
  /// and `TO` is the type of the return value of the old route.
  ///
  /// To use [pushReplacementNamed], a [Navigator.onGenerateRoute] callback must
  /// be provided.
  /// {@endtemplate}
  ///
  /// {@macro flutter.widgets.navigator.pushNamed.arguments}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _switchToBrightness() {
  ///   Navigator.pushReplacementNamed(context, '/settings/brightness');
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  static Future<T> pushReplacementNamed<T extends Object, TO extends Object>(
    BuildContext context,
    String routeName, {
    TO result,
    Object arguments,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, TO>(routeName, arguments: arguments, result: result);
  }

  /// Pop the current route off the navigator that most tightly encloses the
  /// given context and push a named route in its place.
  ///
  /// {@template flutter.widgets.navigator.popAndPushNamed}
  /// The popping of the previous route is handled as per [pop].
  ///
  /// The new route's name will be passed to the [Navigator.onGenerateRoute]
  /// callback. The returned route will be pushed into the navigator.
  ///
  /// The new route, the old route, and the route below the old route (if any)
  /// are all notified (see [Route.didPop], [Route.didComplete],
  /// [Route.didPopNext], [Route.didPush], and [Route.didChangeNext]). If the
  /// [Navigator] has any [Navigator.observers], they will be notified as well
  /// (see [NavigatorObserver.didPop] and [NavigatorObserver.didPush]). The
  /// animations for the pop and the push are performed simultaneously, so the
  /// route below may be briefly visible even if both the old route and the new
  /// route are opaque (see [TransitionRoute.opaque]).
  ///
  /// Ongoing gestures within the current route are canceled when a new route is
  /// pushed.
  ///
  /// Returns a [Future] that completes to the `result` value passed to [pop]
  /// when the pushed route is popped off the navigator.
  ///
  /// The `T` type argument is the type of the return value of the new route,
  /// and `TO` is the return value type of the old route.
  ///
  /// To use [popAndPushNamed], a [Navigator.onGenerateRoute] callback must be provided.
  ///
  /// {@endtemplate}
  ///
  /// {@macro flutter.widgets.navigator.pushNamed.arguments}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _selectAccessibility() {
  ///   Navigator.popAndPushNamed(context, '/settings/accessibility');
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  static Future<T> popAndPushNamed<T extends Object, TO extends Object>(
    BuildContext context,
    String routeName, {
    TO result,
    Object arguments,
   }) {
    return Navigator.of(context).popAndPushNamed<T, TO>(routeName, arguments: arguments, result: result);
  }

  /// Push the route with the given name onto the navigator that most tightly
  /// encloses the given context, and then remove all the previous routes until
  /// the `predicate` returns true.
  ///
  /// {@template flutter.widgets.navigator.pushNamedAndRemoveUntil}
  /// The predicate may be applied to the same route more than once if
  /// [Route.willHandlePopInternally] is true.
  ///
  /// To remove routes until a route with a certain name, use the
  /// [RoutePredicate] returned from [ModalRoute.withName].
  ///
  /// To remove all the routes below the pushed route, use a [RoutePredicate]
  /// that always returns false (e.g. `(Route<dynamic> route) => false`).
  ///
  /// The removed routes are removed without being completed, so this method
  /// does not take a return value argument.
  ///
  /// The new route's name (`routeName`) will be passed to the
  /// [Navigator.onGenerateRoute] callback. The returned route will be pushed
  /// into the navigator.
  ///
  /// The new route and the route below the bottommost removed route (which
  /// becomes the route below the new route) are notified (see [Route.didPush]
  /// and [Route.didChangeNext]). If the [Navigator] has any
  /// [Navigator.observers], they will be notified as well (see
  /// [NavigatorObserver.didPush] and [NavigatorObserver.didRemove]). The
  /// removed routes are disposed, without being notified, once the new route
  /// has finished animating. The futures that had been returned from pushing
  /// those routes will not complete.
  ///
  /// Ongoing gestures within the current route are canceled when a new route is
  /// pushed.
  ///
  /// Returns a [Future] that completes to the `result` value passed to [pop]
  /// when the pushed route is popped off the navigator.
  ///
  /// The `T` type argument is the type of the return value of the new route.
  ///
  /// To use [pushNamedAndRemoveUntil], an [Navigator.onGenerateRoute] callback
  /// must be provided.
  /// {@endtemplate}
  ///
  /// {@macro flutter.widgets.navigator.pushNamed.arguments}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _resetToCalendar() {
  ///   Navigator.pushNamedAndRemoveUntil(context, '/calendar', ModalRoute.withName('/'));
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  static Future<T> pushNamedAndRemoveUntil<T extends Object>(
    BuildContext context,
    String newRouteName,
    RoutePredicate predicate, {
    Object arguments,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(newRouteName, predicate, arguments: arguments);
  }

  /// Push the given route onto the navigator that most tightly encloses the
  /// given context.
  ///
  /// {@template flutter.widgets.navigator.push}
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
  ///
  /// The `T` type argument is the type of the return value of the route.
  /// {@endtemplate}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _openMyPage() {
  ///   Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => MyPage()));
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  static Future<T> push<T extends Object>(BuildContext context, Route<T> route) {
    return Navigator.of(context).push(route);
  }

  /// Replace the current route of the navigator that most tightly encloses the
  /// given context by pushing the given route and then disposing the previous
  /// route once the new route has finished animating in.
  ///
  /// {@template flutter.widgets.navigator.pushReplacement}
  /// If non-null, `result` will be used as the result of the route that is
  /// removed; the future that had been returned from pushing that old route will
  /// complete with `result`. Routes such as dialogs or popup menus typically
  /// use this mechanism to return the value selected by the user to the widget
  /// that created their route. The type of `result`, if provided, must match
  /// the type argument of the class of the old route (`TO`).
  ///
  /// The new route and the route below the removed route are notified (see
  /// [Route.didPush] and [Route.didChangeNext]). If the [Navigator] has any
  /// [Navigator.observers], they will be notified as well (see
  /// [NavigatorObserver.didReplace]). The removed route is notified once the
  /// new route has finished animating (see [Route.didComplete]).
  ///
  /// Ongoing gestures within the current route are canceled when a new route is
  /// pushed.
  ///
  /// Returns a [Future] that completes to the `result` value passed to [pop]
  /// when the pushed route is popped off the navigator.
  ///
  /// The `T` type argument is the type of the return value of the new route,
  /// and `TO` is the type of the return value of the old route.
  /// {@endtemplate}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _completeLogin() {
  ///   Navigator.pushReplacement(
  ///       context, MaterialPageRoute(builder: (BuildContext context) => MyHomePage()));
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  static Future<T> pushReplacement<T extends Object, TO extends Object>(BuildContext context, Route<T> newRoute, { TO result }) {
    return Navigator.of(context).pushReplacement<T, TO>(newRoute, result: result);
  }

  /// Push the given route onto the navigator that most tightly encloses the
  /// given context, and then remove all the previous routes until the
  /// `predicate` returns true.
  ///
  /// {@template flutter.widgets.navigator.pushAndRemoveUntil}
  /// The predicate may be applied to the same route more than once if
  /// [Route.willHandlePopInternally] is true.
  ///
  /// To remove routes until a route with a certain name, use the
  /// [RoutePredicate] returned from [ModalRoute.withName].
  ///
  /// To remove all the routes below the pushed route, use a [RoutePredicate]
  /// that always returns false (e.g. `(Route<dynamic> route) => false`).
  ///
  /// The removed routes are removed without being completed, so this method
  /// does not take a return value argument.
  ///
  /// The newly pushed route and its preceding route are notified for
  /// [Route.didPush]. After removal, the new route and its new preceding route,
  /// (the route below the bottommost removed route) are notified through
  /// [Route.didChangeNext]). If the [Navigator] has any [Navigator.observers],
  /// they will be notified as well (see [NavigatorObserver.didPush] and
  /// [NavigatorObserver.didRemove]). The removed routes are disposed of and
  /// notified, once the new route has finished animating. The futures that had
  /// been returned from pushing those routes will not complete.
  ///
  /// Ongoing gestures within the current route are canceled when a new route is
  /// pushed.
  ///
  /// Returns a [Future] that completes to the `result` value passed to [pop]
  /// when the pushed route is popped off the navigator.
  ///
  /// The `T` type argument is the type of the return value of the new route.
  /// {@endtemplate}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _finishAccountCreation() {
  ///   Navigator.pushAndRemoveUntil(
  ///     context,
  ///     MaterialPageRoute(builder: (BuildContext context) => MyHomePage()),
  ///     ModalRoute.withName('/'),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  static Future<T> pushAndRemoveUntil<T extends Object>(BuildContext context, Route<T> newRoute, RoutePredicate predicate) {
    return Navigator.of(context).pushAndRemoveUntil<T>(newRoute, predicate);
  }

  /// Replaces a route on the navigator that most tightly encloses the given
  /// context with a new route.
  ///
  /// {@template flutter.widgets.navigator.replace}
  /// The old route must not be currently visible, as this method skips the
  /// animations and therefore the removal would be jarring if it was visible.
  /// To replace the top-most route, consider [pushReplacement] instead, which
  /// _does_ animate the new route, and delays removing the old route until the
  /// new route has finished animating.
  ///
  /// The removed route is removed without being completed, so this method does
  /// not take a return value argument.
  ///
  /// The new route, the route below the new route (if any), and the route above
  /// the new route, are all notified (see [Route.didReplace],
  /// [Route.didChangeNext], and [Route.didChangePrevious]). If the [Navigator]
  /// has any [Navigator.observers], they will be notified as well (see
  /// [NavigatorObserver.didReplace]). The removed route is disposed without
  /// being notified. The future that had been returned from pushing that routes
  /// will not complete.
  ///
  /// This can be useful in combination with [removeRouteBelow] when building a
  /// non-linear user experience.
  ///
  /// The `T` type argument is the type of the return value of the new route.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [replaceRouteBelow], which is the same but identifies the route to be
  ///    removed by reference to the route above it, rather than directly.
  @optionalTypeArgs
  static void replace<T extends Object>(BuildContext context, { @required Route<dynamic> oldRoute, @required Route<T> newRoute }) {
    return Navigator.of(context).replace<T>(oldRoute: oldRoute, newRoute: newRoute);
  }

  /// Replaces a route on the navigator that most tightly encloses the given
  /// context with a new route. The route to be replaced is the one below the
  /// given `anchorRoute`.
  ///
  /// {@template flutter.widgets.navigator.replaceRouteBelow}
  /// The old route must not be current visible, as this method skips the
  /// animations and therefore the removal would be jarring if it was visible.
  /// To replace the top-most route, consider [pushReplacement] instead, which
  /// _does_ animate the new route, and delays removing the old route until the
  /// new route has finished animating.
  ///
  /// The removed route is removed without being completed, so this method does
  /// not take a return value argument.
  ///
  /// The new route, the route below the new route (if any), and the route above
  /// the new route, are all notified (see [Route.didReplace],
  /// [Route.didChangeNext], and [Route.didChangePrevious]). If the [Navigator]
  /// has any [Navigator.observers], they will be notified as well (see
  /// [NavigatorObserver.didReplace]). The removed route is disposed without
  /// being notified. The future that had been returned from pushing that routes
  /// will not complete.
  ///
  /// The `T` type argument is the type of the return value of the new route.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [replace], which is the same but identifies the route to be removed
  ///    directly.
  @optionalTypeArgs
  static void replaceRouteBelow<T extends Object>(BuildContext context, { @required Route<dynamic> anchorRoute, Route<T> newRoute }) {
    return Navigator.of(context).replaceRouteBelow<T>(anchorRoute: anchorRoute, newRoute: newRoute);
  }

  /// Whether the navigator that most tightly encloses the given context can be
  /// popped.
  ///
  /// {@template flutter.widgets.navigator.canPop}
  /// The initial route cannot be popped off the navigator, which implies that
  /// this function returns true only if popping the navigator would not remove
  /// the initial route.
  ///
  /// If there is no [Navigator] in scope, returns false.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [Route.isFirst], which returns true for routes for which [canPop]
  ///    returns false.
  static bool canPop(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context, nullOk: true);
    return navigator != null && navigator.canPop();
  }

  /// Consults the current route's [Route.willPop] method, and acts accordingly,
  /// potentially popping the route as a result; returns whether the pop request
  /// should be considered handled.
  ///
  /// {@template flutter.widgets.navigator.maybePop}
  /// If [Route.willPop] returns [RoutePopDisposition.pop], then the [pop]
  /// method is called, and this method returns true, indicating that it handled
  /// the pop request.
  ///
  /// If [Route.willPop] returns [RoutePopDisposition.doNotPop], then this
  /// method returns true, but does not do anything beyond that.
  ///
  /// If [Route.willPop] returns [RoutePopDisposition.bubble], then this method
  /// returns false, and the caller is responsible for sending the request to
  /// the containing scope (e.g. by closing the application).
  ///
  /// This method is typically called for a user-initiated [pop]. For example on
  /// Android it's called by the binding for the system's back button.
  ///
  /// The `T` type argument is the type of the return value of the current
  /// route. (Typically this isn't known; consider specifying `dynamic` or
  /// `Null`.)
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [Form], which provides an `onWillPop` callback that enables the form
  ///    to veto a [pop] initiated by the app's back button.
  ///  * [ModalRoute], which provides a `scopedWillPopCallback` that can be used
  ///    to define the route's `willPop` method.
  @optionalTypeArgs
  static Future<bool> maybePop<T extends Object>(BuildContext context, [ T result ]) {
    return Navigator.of(context).maybePop<T>(result);
  }

  /// Pop the top-most route off the navigator that most tightly encloses the
  /// given context.
  ///
  /// {@template flutter.widgets.navigator.pop}
  /// The current route's [Route.didPop] method is called first. If that method
  /// returns false, then the route remains in the [Navigator]'s history (the
  /// route is expected to have popped some internal state; see e.g.
  /// [LocalHistoryRoute]). Otherwise, the rest of this description applies.
  ///
  /// If non-null, `result` will be used as the result of the route that is
  /// popped; the future that had been returned from pushing the popped route
  /// will complete with `result`. Routes such as dialogs or popup menus
  /// typically use this mechanism to return the value selected by the user to
  /// the widget that created their route. The type of `result`, if provided,
  /// must match the type argument of the class of the popped route (`T`).
  ///
  /// The popped route and the route below it are notified (see [Route.didPop],
  /// [Route.didComplete], and [Route.didPopNext]). If the [Navigator] has any
  /// [Navigator.observers], they will be notified as well (see
  /// [NavigatorObserver.didPop]).
  ///
  /// The `T` type argument is the type of the return value of the popped route.
  ///
  /// The type of `result`, if provided, must match the type argument of the
  /// class of the popped route (`T`).
  /// {@endtemplate}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage for closing a route is as follows:
  ///
  /// ```dart
  /// void _close() {
  ///   Navigator.pop(context);
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// A dialog box might be closed with a result:
  ///
  /// ```dart
  /// void _accept() {
  ///   Navigator.pop(context, true); // dialog returns true
  /// }
  /// ```
  @optionalTypeArgs
  static void pop<T extends Object>(BuildContext context, [ T result ]) {
    Navigator.of(context).pop<T>(result);
  }

  /// Calls [pop] repeatedly on the navigator that most tightly encloses the
  /// given context until the predicate returns true.
  ///
  /// {@template flutter.widgets.navigator.popUntil}
  /// The predicate may be applied to the same route more than once if
  /// [Route.willHandlePopInternally] is true.
  ///
  /// To pop until a route with a certain name, use the [RoutePredicate]
  /// returned from [ModalRoute.withName].
  ///
  /// The routes are closed with null as their `return` value.
  ///
  /// See [pop] for more details of the semantics of popping a route.
  /// {@endtemplate}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _logout() {
  ///   Navigator.popUntil(context, ModalRoute.withName('/login'));
  /// }
  /// ```
  /// {@end-tool}
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    Navigator.of(context).popUntil(predicate);
  }

  /// Immediately remove `route` from the navigator that most tightly encloses
  /// the given context, and [Route.dispose] it.
  ///
  /// {@template flutter.widgets.navigator.removeRoute}
  /// The removed route is removed without being completed, so this method does
  /// not take a return value argument. No animations are run as a result of
  /// this method call.
  ///
  /// The routes below and above the removed route are notified (see
  /// [Route.didChangeNext] and [Route.didChangePrevious]). If the [Navigator]
  /// has any [Navigator.observers], they will be notified as well (see
  /// [NavigatorObserver.didRemove]). The removed route is disposed without
  /// being notified. The future that had been returned from pushing that routes
  /// will not complete.
  ///
  /// The given `route` must be in the history; this method will throw an
  /// exception if it is not.
  ///
  /// Ongoing gestures within the current route are canceled.
  /// {@endtemplate}
  ///
  /// This method is used, for example, to instantly dismiss dropdown menus that
  /// are up when the screen's orientation changes.
  static void removeRoute(BuildContext context, Route<dynamic> route) {
    return Navigator.of(context).removeRoute(route);
  }

  /// Immediately remove a route from the navigator that most tightly encloses
  /// the given context, and [Route.dispose] it. The route to be removed is the
  /// one below the given `anchorRoute`.
  ///
  /// {@template flutter.widgets.navigator.removeRouteBelow}
  /// The removed route is removed without being completed, so this method does
  /// not take a return value argument. No animations are run as a result of
  /// this method call.
  ///
  /// The routes below and above the removed route are notified (see
  /// [Route.didChangeNext] and [Route.didChangePrevious]). If the [Navigator]
  /// has any [Navigator.observers], they will be notified as well (see
  /// [NavigatorObserver.didRemove]). The removed route is disposed without
  /// being notified. The future that had been returned from pushing that routes
  /// will not complete.
  ///
  /// The given `anchorRoute` must be in the history and must have a route below
  /// it; this method will throw an exception if it is not or does not.
  ///
  /// Ongoing gestures within the current route are canceled.
  /// {@endtemplate}
  static void removeRouteBelow(BuildContext context, Route<dynamic> anchorRoute) {
    return Navigator.of(context).removeRouteBelow(anchorRoute);
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
    bool rootNavigator = false,
    bool nullOk = false,
  }) {
    // Handles the case where the input context is a navigator element.
    NavigatorState navigator;
    if (context is StatefulElement && context.state is NavigatorState) {
        navigator = context.state as NavigatorState;
    }
    if (rootNavigator) {
      navigator = context.findRootAncestorStateOfType<NavigatorState>() ?? navigator;
    } else {
      navigator = navigator ?? context.findAncestorStateOfType<NavigatorState>();
    }

    assert(() {
      if (navigator == null && !nullOk) {
        throw FlutterError(
          'Navigator operation requested with a context that does not include a Navigator.\n'
          'The context used to push or pop routes from the Navigator must be that of a '
          'widget that is a descendant of a Navigator widget.'
        );
      }
      return true;
    }());
    return navigator;
  }

  /// Turn a route name into a set of [Route] objects.
  ///
  /// This is the default value of [onGenerateInitialRoutes], which is used if
  /// [initialRoute] is not null.
  ///
  /// If this string starts with a `/` character and has multiple `/` characters
  /// in it, then the string is split on those characters and substrings from
  /// the start of the string up to each such character are, in turn, used as
  /// routes to push.
  ///
  /// For example, if the route `/stocks/HOOLI` was used as the [initialRoute],
  /// then the [Navigator] would push the following routes on startup: `/`,
  /// `/stocks`, `/stocks/HOOLI`. This enables deep linking while allowing the
  /// application to maintain a predictable route history.
  static List<Route<dynamic>> defaultGenerateInitialRoutes(NavigatorState navigator, String initialRouteName) {
    final List<Route<dynamic>> result = <Route<dynamic>>[];
    if (initialRouteName.startsWith('/') && initialRouteName.length > 1) {
      initialRouteName = initialRouteName.substring(1); // strip leading '/'
      assert(Navigator.defaultRouteName == '/');
      List<String> debugRouteNames;
      assert(() {
        debugRouteNames = <String>[ Navigator.defaultRouteName ];
        return true;
      }());
      result.add(navigator._routeNamed<dynamic>(Navigator.defaultRouteName, arguments: null, allowNull: true));
      final List<String> routeParts = initialRouteName.split('/');
      if (initialRouteName.isNotEmpty) {
        String routeName = '';
        for (final String part in routeParts) {
          routeName += '/$part';
          assert(() {
            debugRouteNames.add(routeName);
            return true;
          }());
          result.add(navigator._routeNamed<dynamic>(routeName, arguments: null, allowNull: true));
        }
      }
      if (result.last == null) {
        assert(() {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception:
                'Could not navigate to initial route.\n'
                'The requested route name was: "/$initialRouteName"\n'
                'There was no corresponding route in the app, and therefore the initial route specified will be '
                'ignored and "${Navigator.defaultRouteName}" will be used instead.'
            ),
          );
          return true;
        }());
        result.clear();
      }
    } else if (initialRouteName != Navigator.defaultRouteName) {
      // If initialRouteName wasn't '/', then we try to get it with allowNull:true, so that if that fails,
      // we fall back to '/' (without allowNull:true, see below).
      result.add(navigator._routeNamed<dynamic>(initialRouteName, arguments: null, allowNull: true));
    }
    // Null route might be a result of gap in initialRouteName
    //
    // For example, routes = ['A', 'A/B/C'], and initialRouteName = 'A/B/C'
    // This should result in result = ['A', null,'A/B/C'] where 'A/B' produces
    // the null. In this case, we want to filter out the null and return
    // result = ['A', 'A/B/C'].
    result.removeWhere((Route<dynamic> route) => route == null);
    if (result.isEmpty)
      result.add(navigator._routeNamed<dynamic>(Navigator.defaultRouteName, arguments: null));
    return result;
  }

  @override
  NavigatorState createState() => NavigatorState();
}

// The _RouteLifecycle state machine (only goes down):
//
//                    [creation of a _RouteEntry]
//                                 |
//                                 +
//                                 |\
//                                 | \
//                                 | staging
//                                 | /
//                                 |/
//                    +-+----------+--+-------+
//                   /  |             |       |
//                  /   |             |       |
//                 /    |             |       |
//                /     |             |       |
//               /      |             |       |
//      pushReplace   push*         add*   replace*
//               \       |            |       |
//                \      |            |      /
//                 +--pushing#      adding  /
//                          \        /     /
//                           \      /     /
//                           idle--+-----+
//                           /  \
//                          /    \
//                        pop*  remove*
//                        /        \
//                       /       removing#
//                     popping#       |
//                      |             |
//                   [finalizeRoute]  |
//                              \     |
//                              dispose*
//                                 |
//                                 |
//                              disposed
//                                 |
//                                 |
//                  [_RouteEntry garbage collected]
//                          (terminal state)
//
// * These states are transient; as soon as _flushHistoryUpdates is run the
//   route entry will exit that state.
// # These states await futures or other events, then transition automatically.
enum _RouteLifecycle {
  staging, // we will wait for transition delegate to decide what to do with this route.
  //
  // routes that are present:
  //
  add, // we'll want to run install, didAdd, etc; a route created by onGenerateInitialRoutes or by the initial widget.pages
  adding, // we'll waiting for the future from didPush of top-most route to complete
  // routes that are ready for transition.
  push, // we'll want to run install, didPush, etc; a route added via push() and friends
  pushReplace, // we'll want to run install, didPush, etc; a route added via pushReplace() and friends
  pushing, // we're waiting for the future from didPush to complete
  replace, // we'll want to run install, didReplace, etc; a route added via replace() and friends
  idle, // route is being harmless
  //
  // routes that are not present:
  //
  // routes that should be included in route announcement and should still listen to transition changes.
  pop, // we'll want to call didPop
  remove, // we'll want to run didReplace/didRemove etc
  // routes should not be included in route announcement but should still listen to transition changes.
  popping, // we're waiting for the route to call finalizeRoute to switch to dispose
  removing, // we are waiting for subsequent routes to be done animating, then will switch to dispose
  // routes that are completely removed from the navigator and overlay.
  dispose, // we will dispose the route momentarily
  disposed, // we have disposed the route
}

typedef _RouteEntryPredicate = bool Function(_RouteEntry entry);

class _NotAnnounced extends Route<void> {
  // A placeholder for the lastAnnouncedPreviousRoute, the
  // lastAnnouncedPoppedNextRoute, and the lastAnnouncedNextRoute before any
  // change has been announced.
}

class _RouteEntry extends RouteTransitionRecord {
  _RouteEntry(
    this.route, {
      @required _RouteLifecycle initialState,
    }) : assert(route != null),
         assert(initialState != null),
         assert(
           initialState == _RouteLifecycle.staging ||
           initialState == _RouteLifecycle.add ||
           initialState == _RouteLifecycle.push ||
           initialState == _RouteLifecycle.pushReplace ||
           initialState == _RouteLifecycle.replace
         ),
         currentState = initialState;

  @override
  final Route<dynamic> route;

  static Route<dynamic> notAnnounced = _NotAnnounced();

  _RouteLifecycle currentState;
  Route<dynamic> lastAnnouncedPreviousRoute = notAnnounced; // last argument to Route.didChangePrevious
  Route<dynamic> lastAnnouncedPoppedNextRoute = notAnnounced; // last argument to Route.didPopNext
  Route<dynamic> lastAnnouncedNextRoute = notAnnounced; // last argument to Route.didChangeNext

  bool get hasPage => route.settings is Page;

  bool canUpdateFrom(Page<dynamic> page) {
    if (currentState.index > _RouteLifecycle.idle.index)
      return false;
    if (!hasPage)
      return false;
    final Page<dynamic> routePage = route.settings as Page<dynamic>;
    return page.canUpdate(routePage);
  }

  void handleAdd({ @required NavigatorState navigator, @required Route<dynamic> previousPresent }) {
    assert(currentState == _RouteLifecycle.add);
    assert(navigator != null);
    assert(navigator._debugLocked);
    assert(route._navigator == null);
    route._navigator = navigator;
    route.install();
    assert(route.overlayEntries.isNotEmpty);
    currentState = _RouteLifecycle.adding;
    navigator._observedRouteAdditions.add(
      _NavigatorPushObservation(route, previousPresent)
    );
  }

  void handlePush({ @required NavigatorState navigator, @required bool isNewFirst, @required Route<dynamic> previous, @required Route<dynamic> previousPresent }) {
    assert(currentState == _RouteLifecycle.push || currentState == _RouteLifecycle.pushReplace || currentState == _RouteLifecycle.replace);
    assert(navigator != null);
    assert(navigator._debugLocked);
    assert(
      route._navigator == null,
      'The pushed route has already been used. When pushing a route, a new '
      'Route object must be provided.',
    );
    final _RouteLifecycle previousState = currentState;
    route._navigator = navigator;
    route.install();
    assert(route.overlayEntries.isNotEmpty);
    if (currentState == _RouteLifecycle.push || currentState == _RouteLifecycle.pushReplace) {
      final TickerFuture routeFuture = route.didPush();
      currentState = _RouteLifecycle.pushing;
      routeFuture.whenCompleteOrCancel(() {
        if (currentState == _RouteLifecycle.pushing) {
          currentState = _RouteLifecycle.idle;
          assert(!navigator._debugLocked);
          assert(() { navigator._debugLocked = true; return true; }());
          navigator._flushHistoryUpdates();
          assert(() { navigator._debugLocked = false; return true; }());
        }
      });
    } else {
      assert(currentState == _RouteLifecycle.replace);
      route.didReplace(previous);
      currentState = _RouteLifecycle.idle;
    }
    if (isNewFirst) {
      route.didChangeNext(null);
    }

    if (previousState == _RouteLifecycle.replace || previousState == _RouteLifecycle.pushReplace) {
      navigator._observedRouteAdditions.add(
        _NavigatorReplaceObservation(route, previousPresent)
      );
    } else {
      assert(previousState == _RouteLifecycle.push);
      navigator._observedRouteAdditions.add(
        _NavigatorPushObservation(route, previousPresent)
      );
    }
  }

  void handleDidPopNext(Route<dynamic> poppedRoute) {
    route.didPopNext(poppedRoute);
    lastAnnouncedPoppedNextRoute = poppedRoute;
  }

  void handlePop({ @required NavigatorState navigator, @required Route<dynamic> previousPresent }) {
    assert(navigator != null);
    assert(navigator._debugLocked);
    assert(route._navigator == navigator);
    currentState = _RouteLifecycle.popping;
    navigator._observedRouteDeletions.add(
      _NavigatorPopObservation(route, previousPresent)
    );
  }

  void handleRemoval({ @required NavigatorState navigator, @required Route<dynamic> previousPresent }) {
    assert(navigator != null);
    assert(navigator._debugLocked);
    assert(route._navigator == navigator);
    currentState = _RouteLifecycle.removing;
    if (_reportRemovalToObserver) {
      navigator._observedRouteDeletions.add(
        _NavigatorRemoveObservation(route, previousPresent)
      );
    }
  }

  bool doingPop = false;

  void didAdd({ @required NavigatorState navigator, @required bool isNewFirst}) {
    route.didAdd();
    currentState = _RouteLifecycle.idle;
    if (isNewFirst) {
      route.didChangeNext(null);
    }
  }

  void pop<T>(T result) {
    assert(isPresent);
    doingPop = true;
    if (route.didPop(result) && doingPop) {
      currentState = _RouteLifecycle.pop;
    }
    doingPop = false;
  }

  bool _reportRemovalToObserver = true;

  // Route is removed without being completed.
  void remove({ bool isReplaced = false }) {
    assert(
      !hasPage || isWaitingForExitingDecision,
      'A page-based route cannot be completed using imperative api, provide a '
      'new list without the corresponding Page to Navigator.pages instead. '
    );
    if (currentState.index >= _RouteLifecycle.remove.index)
      return;
    assert(isPresent);
    _reportRemovalToObserver = !isReplaced;
    currentState = _RouteLifecycle.remove;
  }

  // Route completes with `result` and is removed.
  void complete<T>(T result, { bool isReplaced = false }) {
    assert(
      !hasPage || isWaitingForExitingDecision,
      'A page-based route cannot be completed using imperative api, provide a '
      'new list without the corresponding Page to Navigator.pages instead. '
    );
    if (currentState.index >= _RouteLifecycle.remove.index)
      return;
    assert(isPresent);
    _reportRemovalToObserver = !isReplaced;
    route.didComplete(result);
    assert(route._popCompleter.isCompleted); // implies didComplete was called
    currentState = _RouteLifecycle.remove;
  }

  void finalize() {
    assert(currentState.index < _RouteLifecycle.dispose.index);
    currentState = _RouteLifecycle.dispose;
  }

  void dispose() {
    assert(currentState.index < _RouteLifecycle.disposed.index);
    route.dispose();
    currentState = _RouteLifecycle.disposed;
  }

  bool get willBePresent {
    return currentState.index <= _RouteLifecycle.idle.index &&
           currentState.index >= _RouteLifecycle.add.index;
  }

  bool get isPresent {
    return currentState.index <= _RouteLifecycle.remove.index &&
           currentState.index >= _RouteLifecycle.add.index;
  }

  bool get suitableForAnnouncement {
    return currentState.index <= _RouteLifecycle.removing.index &&
           currentState.index >= _RouteLifecycle.push.index;
  }

  bool get suitableForTransitionAnimation {
    return currentState.index <= _RouteLifecycle.remove.index &&
           currentState.index >= _RouteLifecycle.push.index;
  }

  bool shouldAnnounceChangeToNext(Route<dynamic> nextRoute) {
    assert(nextRoute != lastAnnouncedNextRoute);
    // Do not announce if `next` changes from a just popped route to null. We
    // already announced this change by calling didPopNext.
    return !(
      nextRoute == null &&
        lastAnnouncedPoppedNextRoute != null &&
        lastAnnouncedPoppedNextRoute == lastAnnouncedNextRoute
    );
  }

  static final _RouteEntryPredicate isPresentPredicate = (_RouteEntry entry) => entry.isPresent;
  static final _RouteEntryPredicate suitableForTransitionAnimationPredicate = (_RouteEntry entry) => entry.suitableForTransitionAnimation;
  static final _RouteEntryPredicate willBePresentPredicate = (_RouteEntry entry) => entry.willBePresent;

  static _RouteEntryPredicate isRoutePredicate(Route<dynamic> route) {
    return (_RouteEntry entry) => entry.route == route;
  }

  @override
  bool get isWaitingForEnteringDecision => currentState == _RouteLifecycle.staging;

  @override
  bool get isWaitingForExitingDecision => _isWaitingForExitingDecision;
  bool _isWaitingForExitingDecision = false;

  void markNeedsExitingDecision() => _isWaitingForExitingDecision = true;

  @override
  void markForPush() {
    assert(
      isWaitingForEnteringDecision && !isWaitingForExitingDecision,
      'This route cannot be marked for push. Either a decision has already been '
      'made or it does not require an explicit decision on how to transition in.'
    );
    currentState = _RouteLifecycle.push;
  }

  @override
  void markForAdd() {
    assert(
      isWaitingForEnteringDecision && !isWaitingForExitingDecision,
      'This route cannot be marked for add. Either a decision has already been '
      'made or it does not require an explicit decision on how to transition in.'
    );
    currentState = _RouteLifecycle.add;
  }

  @override
  void markForPop([dynamic result]) {
    assert(
      !isWaitingForEnteringDecision && isWaitingForExitingDecision && isPresent,
      'This route cannot be marked for pop. Either a decision has already been '
      'made or it does not require an explicit decision on how to transition out.'
    );
    pop<dynamic>(result);
    _isWaitingForExitingDecision = false;
  }

  @override
  void markForComplete([dynamic result]) {
    assert(
      !isWaitingForEnteringDecision && isWaitingForExitingDecision && isPresent,
      'This route cannot be marked for complete. Either a decision has already '
      'been made or it does not require an explicit decision on how to transition '
      'out.'
    );
    complete<dynamic>(result);
    _isWaitingForExitingDecision = false;
  }

  @override
  void markForRemove() {
    assert(
      !isWaitingForEnteringDecision && isWaitingForExitingDecision && isPresent,
      'This route cannot be marked for remove. Either a decision has already '
      'been made or it does not require an explicit decision on how to transition '
      'out.'
    );
    remove();
    _isWaitingForExitingDecision = false;
  }
}

abstract class _NavigatorObservation {
  _NavigatorObservation(
    this.primaryRoute,
    this.secondaryRoute,
  );
  final Route<dynamic> primaryRoute;
  final Route<dynamic> secondaryRoute;

  void notify(NavigatorObserver observer);
}

class _NavigatorPushObservation extends _NavigatorObservation {
  _NavigatorPushObservation(
    Route<dynamic> primaryRoute,
    Route<dynamic> secondaryRoute
  ) : super(primaryRoute, secondaryRoute);

  @override
  void notify(NavigatorObserver observer) {
    observer.didPush(primaryRoute, secondaryRoute);
  }
}

class _NavigatorPopObservation extends _NavigatorObservation {
  _NavigatorPopObservation(
    Route<dynamic> primaryRoute,
    Route<dynamic> secondaryRoute
  ) : super(primaryRoute, secondaryRoute);

  @override
  void notify(NavigatorObserver observer) {
    observer.didPop(primaryRoute, secondaryRoute);
  }
}

class _NavigatorRemoveObservation extends _NavigatorObservation {
  _NavigatorRemoveObservation(
    Route<dynamic> primaryRoute,
    Route<dynamic> secondaryRoute
  ) : super(primaryRoute, secondaryRoute);

  @override
  void notify(NavigatorObserver observer) {
    observer.didRemove(primaryRoute, secondaryRoute);
  }
}

class _NavigatorReplaceObservation extends _NavigatorObservation {
  _NavigatorReplaceObservation(
    Route<dynamic> primaryRoute,
    Route<dynamic> secondaryRoute
  ) : super(primaryRoute, secondaryRoute);

  @override
  void notify(NavigatorObserver observer) {
    observer.didReplace(newRoute: primaryRoute, oldRoute: secondaryRoute);
  }
}

/// The state for a [Navigator] widget.
///
/// A reference to this class can be obtained by calling [Navigator.of].
class NavigatorState extends State<Navigator> with TickerProviderStateMixin {
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();
  List<_RouteEntry> _history = <_RouteEntry>[];
  final Queue<_NavigatorObservation> _observedRouteAdditions = Queue<_NavigatorObservation>();
  final Queue<_NavigatorObservation> _observedRouteDeletions = Queue<_NavigatorObservation>();

  /// The [FocusScopeNode] for the [FocusScope] that encloses the routes.
  final FocusScopeNode focusScopeNode = FocusScopeNode(debugLabel: 'Navigator Scope');

  bool _debugLocked = false; // used to prevent re-entrant calls to push, pop, and friends

  HeroController _heroControllerFromScope;

  List<NavigatorObserver> _effectiveObservers;

  @override
  void initState() {
    super.initState();
    assert(
      widget.pages.isEmpty || widget.onPopPage != null,
      'The Navigator.onPopPage must be provided to use the Navigator.pages API',
    );
    for (final NavigatorObserver observer in widget.observers) {
      assert(observer.navigator == null);
      observer._navigator = this;
    }
    _effectiveObservers = widget.observers;

    // We have to manually extract the inherited widget in initState because
    // the current context is not fully initialized.
    final HeroControllerScope heroControllerScope = context
      .getElementForInheritedWidgetOfExactType<HeroControllerScope>()
      ?.widget as HeroControllerScope;
    _updateHeroController(heroControllerScope?.controller);

    String initialRoute = widget.initialRoute;
    if (widget.pages.isNotEmpty) {
      _history.addAll(
        widget.pages.map((Page<dynamic> page) => _RouteEntry(
          page.createRoute(context),
          initialState: _RouteLifecycle.add,
        ))
      );
    } else {
      // If there is no page provided, we will need to provide default route
      // to initialize the navigator.
      initialRoute = initialRoute ?? Navigator.defaultRouteName;
    }
    if (initialRoute != null) {
      _history.addAll(
        widget.onGenerateInitialRoutes(
          this,
          widget.initialRoute ?? Navigator.defaultRouteName
        ).map((Route<dynamic> route) =>
          _RouteEntry(
            route,
            initialState: _RouteLifecycle.add,
          ),
        ),
      );
    }
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; }());
    _flushHistoryUpdates();
    assert(() { _debugLocked = false; return true; }());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateHeroController(HeroControllerScope.of(context));
  }

  void _updateHeroController(HeroController newHeroController) {
    if (_heroControllerFromScope != newHeroController) {
      if (newHeroController != null) {
        // Makes sure the same hero controller is not shared between two navigators.
        assert(() {
          // It is possible that the hero controller subscribes to an existing
          // navigator. We are fine as long as that navigator gives up the hero
          // controller at the end of the build.
          if (newHeroController.navigator != null) {
            final NavigatorState previousOwner = newHeroController.navigator;
            ServicesBinding.instance.addPostFrameCallback((Duration timestamp) {
              // We only check if this navigator still owns the hero controller.
              if (_heroControllerFromScope == newHeroController) {
                assert(_heroControllerFromScope._navigator == this);
                assert(previousOwner._heroControllerFromScope != newHeroController);
              }
            });
          }
          return true;
        }());
        newHeroController._navigator = this;
      }
      // Only unsubscribe the hero controller when it is currently subscribe to
      // this navigator.
      if (_heroControllerFromScope?._navigator == this)
        _heroControllerFromScope?._navigator = null;
      _heroControllerFromScope = newHeroController;
      _updateEffectiveObservers();
    }
  }

  void _updateEffectiveObservers() {
    if (_heroControllerFromScope != null)
      _effectiveObservers = widget.observers + <NavigatorObserver>[_heroControllerFromScope];
    else
      _effectiveObservers = widget.observers;
  }

  @override
  void didUpdateWidget(Navigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(
      widget.pages.isEmpty || widget.onPopPage != null,
      'The Navigator.onPopPage must be provided to use the Navigator.pages API',
    );
    if (oldWidget.observers != widget.observers) {
      for (final NavigatorObserver observer in oldWidget.observers)
        observer._navigator = null;
      for (final NavigatorObserver observer in widget.observers) {
        assert(observer.navigator == null);
        observer._navigator = this;
      }
      _updateEffectiveObservers();
    }
    if (oldWidget.pages != widget.pages) {
      assert(
        widget.pages.isNotEmpty,
        'To use the Navigator.pages, there must be at least one page in the list.'
      );
      _updatePages();
    }

    for (final _RouteEntry entry in _history)
      entry.route.changedExternalState();
  }

  void _debugCheckDuplicatedPageKeys() {
    assert((){
      final Set<Key> keyReservation = <Key>{};
      for (final Page<dynamic> page in widget.pages) {
        if (page.key != null) {
          assert(!keyReservation.contains(page.key));
          keyReservation.add(page.key);
        }
      }
      return true;
    }());
  }

  @override
  void dispose() {
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    _updateHeroController(null);
    for (final NavigatorObserver observer in _effectiveObservers)
      observer._navigator = null;
    focusScopeNode.dispose();
    for (final _RouteEntry entry in _history)
      entry.dispose();
    super.dispose();
    // don't unlock, so that the object becomes unusable
    assert(_debugLocked);
  }

  /// The overlay this navigator uses for its visual presentation.
  OverlayState get overlay => _overlayKey.currentState;

  Iterable<OverlayEntry> get _allRouteOverlayEntries sync* {
    for (final _RouteEntry entry in _history)
      yield* entry.route.overlayEntries;
  }

  String _lastAnnouncedRouteName;

  bool _debugUpdatingPage = false;
  void _updatePages() {
    assert(() {
      assert(!_debugUpdatingPage);
      _debugCheckDuplicatedPageKeys();
      _debugUpdatingPage = true;
      return true;
    }());

    // This attempts to diff the new pages list (widget.pages) with
    // the old _RouteEntry[s] list (_history), and produces a new list of
    // _RouteEntry[s] to be the new list of _history. This method roughly
    // follows the same outline of RenderObjectElement.updateChildren.
    //
    // The cases it tries to optimize for are:
    //  - the old list is empty
    //  - All the pages in the new list can match the page-based routes in the old
    //    list, and their orders are the same.
    //  - there is an insertion or removal of one or more page-based route in
    //    only one place in the list
    // If a page-based route with a key is in both lists, it will be synced.
    // Page-based routes without keys might be synced but there is no guarantee.

    // The general approach is to sync the entire new list backwards, as follows:
    // 1. Walk the lists from the bottom, syncing nodes, and record pageless routes,
    //    until you no longer have matching nodes.
    // 2. Walk the lists from the top, without syncing nodes, until you no
    //    longer have matching nodes. We'll sync these nodes at the end. We
    //    don't sync them now because we want to sync all the nodes in order
    //    from beginning to end.
    // At this point we narrowed the old and new lists to the point
    // where the nodes no longer match.
    // 3. Walk the narrowed part of the old list to get the list of
    //    keys.
    // 4. Walk the narrowed part of the new list forwards:
    //     * Create a new _RouteEntry for non-keyed items and record them for
    //       transitionDelegate.
    //     * Sync keyed items with the source if it exists.
    // 5. Walk the narrowed part of the old list again to records the
    //    _RouteEntry[s], as well as pageless routes, needed to be removed for
    //    transitionDelegate.
    // 5. Walk the top of the list again, syncing the nodes and recording
    //    pageless routes.
    // 6. Use transitionDelegate for explicit decisions on how _RouteEntry[s]
    //    transition in or off the screens.
    // 7. Fill pageless routes back into the new history.

    bool needsExplicitDecision = false;
    int newPagesBottom = 0;
    int oldEntriesBottom = 0;
    int newPagesTop = widget.pages.length - 1;
    int oldEntriesTop = _history.length - 1;

    final List<_RouteEntry> newHistory = <_RouteEntry>[];
    final Map<_RouteEntry, List<_RouteEntry>> pageRouteToPagelessRoutes = <_RouteEntry, List<_RouteEntry>>{};

    // Updates the bottom of the list.
    _RouteEntry previousOldPageRouteEntry;
    while (oldEntriesBottom <= oldEntriesTop) {
      final _RouteEntry oldEntry = _history[oldEntriesBottom];
      assert(oldEntry != null && oldEntry.currentState != _RouteLifecycle.disposed);
      // Records pageless route. The bottom most pageless routes will be
      // stored in key = null.
      if (!oldEntry.hasPage) {
        final List<_RouteEntry> pagelessRoutes = pageRouteToPagelessRoutes.putIfAbsent(
          previousOldPageRouteEntry,
          () => <_RouteEntry>[],
        );
        pagelessRoutes.add(oldEntry);
        oldEntriesBottom += 1;
        continue;
      }
      if (newPagesBottom > newPagesTop)
        break;
      final Page<dynamic> newPage = widget.pages[newPagesBottom];
      if (!oldEntry.canUpdateFrom(newPage))
        break;
      previousOldPageRouteEntry = oldEntry;
      oldEntry.route._updateSettings(newPage);
      newHistory.add(oldEntry);
      newPagesBottom += 1;
      oldEntriesBottom += 1;
    }

    int pagelessRoutesToSkip = 0;
    // Scans the top of the list until we found a page-based route that cannot be
    // updated.
    while ((oldEntriesBottom <= oldEntriesTop) && (newPagesBottom <= newPagesTop)) {
      final _RouteEntry oldEntry = _history[oldEntriesTop];
      assert(oldEntry != null && oldEntry.currentState != _RouteLifecycle.disposed);
      if (!oldEntry.hasPage) {
        // This route might need to be skipped if we can not find a page above.
        pagelessRoutesToSkip += 1;
        oldEntriesTop -= 1;
        continue;
      }
      final Page<dynamic> newPage = widget.pages[newPagesTop];
      if (!oldEntry.canUpdateFrom(newPage))
        break;
      // We found the page for all the consecutive pageless routes below. Those
      // pageless routes do not need to be skipped.
      pagelessRoutesToSkip = 0;
      oldEntriesTop -= 1;
      newPagesTop -= 1;
    }
    // Reverts the pageless routes that cannot be updated.
    oldEntriesTop += pagelessRoutesToSkip;

    // Scans middle of the old entries and records the page key to old entry map.
    int oldEntriesBottomToScan = oldEntriesBottom;
    final Map<LocalKey, _RouteEntry> pageKeyToOldEntry = <LocalKey, _RouteEntry>{};
    while (oldEntriesBottomToScan <= oldEntriesTop) {
      final _RouteEntry oldEntry = _history[oldEntriesBottomToScan];
      oldEntriesBottomToScan += 1;
      assert(
        oldEntry != null &&
        oldEntry.currentState != _RouteLifecycle.disposed
      );
      // Pageless routes will be recorded when we update the middle of the old
      // list.
      if (!oldEntry.hasPage)
        continue;

      assert(oldEntry.hasPage);

      final Page<dynamic> page = oldEntry.route.settings as Page<dynamic>;
      if (page.key == null)
        continue;

      assert(!pageKeyToOldEntry.containsKey(page.key));
      pageKeyToOldEntry[page.key] = oldEntry;
    }

    // Updates the middle of the list.
    while (newPagesBottom <= newPagesTop) {
      final Page<dynamic> nextPage = widget.pages[newPagesBottom];
      newPagesBottom += 1;
      if (
        nextPage.key == null ||
        !pageKeyToOldEntry.containsKey(nextPage.key) ||
        !pageKeyToOldEntry[nextPage.key].canUpdateFrom(nextPage)
      ) {
        // There is no matching key in the old history, we need to create a new
        // route and wait for the transition delegate to decide how to add
        // it into the history.
        final _RouteEntry newEntry = _RouteEntry(
          nextPage.createRoute(context),
          initialState: _RouteLifecycle.staging,
        );
        needsExplicitDecision = true;
        assert(
          newEntry.route.settings == nextPage,
          'The settings getter of a page-based Route must return a Page object. '
          'Please set the settings to the Page in the Page.createRoute method.'
        );
        newHistory.add(newEntry);
      } else {
        // Removes the key from pageKeyToOldEntry to indicate it is taken.
        final _RouteEntry matchingEntry = pageKeyToOldEntry.remove(nextPage.key);
        assert(matchingEntry.canUpdateFrom(nextPage));
        matchingEntry.route._updateSettings(nextPage);
        newHistory.add(matchingEntry);
      }
    }

    // Any remaining old routes that do not have a match will need to be removed.
    final Map<RouteTransitionRecord, RouteTransitionRecord> locationToExitingPageRoute = <RouteTransitionRecord, RouteTransitionRecord>{};
    while (oldEntriesBottom <= oldEntriesTop) {
      final _RouteEntry potentialEntryToRemove = _history[oldEntriesBottom];
      oldEntriesBottom += 1;

      if (!potentialEntryToRemove.hasPage) {
        assert(previousOldPageRouteEntry != null);
        final List<_RouteEntry> pagelessRoutes = pageRouteToPagelessRoutes
          .putIfAbsent(
            previousOldPageRouteEntry,
            () => <_RouteEntry>[],
          );
        pagelessRoutes.add(potentialEntryToRemove);
        if (previousOldPageRouteEntry.isWaitingForExitingDecision)
          potentialEntryToRemove.markNeedsExitingDecision();
        continue;
      }

      final Page<dynamic> potentialPageToRemove = potentialEntryToRemove.route.settings as Page<dynamic>;
      // Marks for transition delegate to remove if this old page does not have
      // a key or was not taken during updating the middle of new page.
      if (
        potentialPageToRemove.key == null ||
        pageKeyToOldEntry.containsKey(potentialPageToRemove.key)
      ) {
        locationToExitingPageRoute[previousOldPageRouteEntry] = potentialEntryToRemove;
        // We only need a decision if it has not already been popped.
        if (potentialEntryToRemove.isPresent)
          potentialEntryToRemove.markNeedsExitingDecision();
      }
      previousOldPageRouteEntry = potentialEntryToRemove;
    }

    // We've scanned the whole list.
    assert(oldEntriesBottom == oldEntriesTop + 1);
    assert(newPagesBottom == newPagesTop + 1);
    newPagesTop = widget.pages.length - 1;
    oldEntriesTop = _history.length - 1;
    // Verifies we either reach the bottom or the oldEntriesBottom must be updatable
    // by newPagesBottom.
    assert(() {
      if (oldEntriesBottom <= oldEntriesTop)
        return newPagesBottom <= newPagesTop &&
          _history[oldEntriesBottom].hasPage &&
          _history[oldEntriesBottom].canUpdateFrom(widget.pages[newPagesBottom]);
      else
        return newPagesBottom > newPagesTop;
    }());

    // Updates the top of the list.
    while ((oldEntriesBottom <= oldEntriesTop) && (newPagesBottom <= newPagesTop)) {
      final _RouteEntry oldEntry = _history[oldEntriesBottom];
      assert(oldEntry != null && oldEntry.currentState != _RouteLifecycle.disposed);
      if (!oldEntry.hasPage) {
        assert(previousOldPageRouteEntry != null);
        final List<_RouteEntry> pagelessRoutes = pageRouteToPagelessRoutes
          .putIfAbsent(
          previousOldPageRouteEntry,
            () => <_RouteEntry>[]
        );
        pagelessRoutes.add(oldEntry);
        continue;
      }
      previousOldPageRouteEntry = oldEntry;
      final Page<dynamic> newPage = widget.pages[newPagesBottom];
      assert(oldEntry.canUpdateFrom(newPage));
      oldEntry.route._updateSettings(newPage);
      newHistory.add(oldEntry);
      oldEntriesBottom += 1;
      newPagesBottom += 1;
    }

    // Finally, uses transition delegate to make explicit decision if needed.
    needsExplicitDecision = needsExplicitDecision || locationToExitingPageRoute.isNotEmpty;
    Iterable<_RouteEntry> results = newHistory;
    if (needsExplicitDecision) {
      results = widget.transitionDelegate._transition(
        newPageRouteHistory: newHistory,
        locationToExitingPageRoute: locationToExitingPageRoute,
        pageRouteToPagelessRoutes: pageRouteToPagelessRoutes,
      ).cast<_RouteEntry>();
    }
    _history = <_RouteEntry>[];
    // Adds the leading pageless routes if there is any.
    if (pageRouteToPagelessRoutes.containsKey(null)) {
      _history.addAll(pageRouteToPagelessRoutes[null]);
    }
    for (final _RouteEntry result in results) {
      _history.add(result);
      if (pageRouteToPagelessRoutes.containsKey(result)) {
        _history.addAll(pageRouteToPagelessRoutes[result]);
      }
    }
    assert(() {_debugUpdatingPage = false; return true;}());
    assert(() { _debugLocked = true; return true; }());
    _flushHistoryUpdates();
    assert(() { _debugLocked = false; return true; }());
  }

  void _flushHistoryUpdates({bool rearrangeOverlay = true}) {
    assert(_debugLocked && !_debugUpdatingPage);
    // Clean up the list, sending updates to the routes that changed. Notably,
    // we don't send the didChangePrevious/didChangeNext updates to those that
    // did not change at this point, because we're not yet sure exactly what the
    // routes will be at the end of the day (some might get disposed).
    int index = _history.length - 1;
    _RouteEntry next;
    _RouteEntry entry = _history[index];
    _RouteEntry previous = index > 0 ? _history[index - 1] : null;
    bool canRemoveOrAdd = false; // Whether there is a fully opaque route on top to silently remove or add route underneath.
    Route<dynamic> poppedRoute; // The route that should trigger didPopNext on the top active route.
    bool seenTopActiveRoute = false; // Whether we've seen the route that would get didPopNext.
    final List<_RouteEntry> toBeDisposed = <_RouteEntry>[];
    while (index >= 0) {
      switch (entry.currentState) {
        case _RouteLifecycle.add:
          assert(rearrangeOverlay);
          entry.handleAdd(
            navigator: this,
            previousPresent: _getRouteBefore(index - 1, _RouteEntry.isPresentPredicate)?.route,
          );
          assert(entry.currentState == _RouteLifecycle.adding);
          continue;
        case _RouteLifecycle.adding:
          if (canRemoveOrAdd || next == null) {
            entry.didAdd(
              navigator: this,
              isNewFirst: next == null
            );
            assert(entry.currentState == _RouteLifecycle.idle);
            continue;
          }
          break;
        case _RouteLifecycle.push:
        case _RouteLifecycle.pushReplace:
        case _RouteLifecycle.replace:
          assert(rearrangeOverlay);
          entry.handlePush(
            navigator: this,
            previous: previous?.route,
            previousPresent: _getRouteBefore(index - 1, _RouteEntry.isPresentPredicate)?.route,
            isNewFirst: next == null,
          );
          assert(entry.currentState != _RouteLifecycle.push);
          assert(entry.currentState != _RouteLifecycle.pushReplace);
          assert(entry.currentState != _RouteLifecycle.replace);
          if (entry.currentState == _RouteLifecycle.idle) {
            continue;
          }
          break;
        case _RouteLifecycle.pushing: // Will exit this state when animation completes.
          if (!seenTopActiveRoute && poppedRoute != null)
            entry.handleDidPopNext(poppedRoute);
          seenTopActiveRoute = true;
          break;
        case _RouteLifecycle.idle:
          if (!seenTopActiveRoute && poppedRoute != null)
            entry.handleDidPopNext(poppedRoute);
          seenTopActiveRoute = true;
          // This route is idle, so we are allowed to remove subsequent (earlier)
          // routes that are waiting to be removed silently:
          canRemoveOrAdd = true;
          break;
        case _RouteLifecycle.pop:
          if (!seenTopActiveRoute) {
            if (poppedRoute != null)
              entry.handleDidPopNext(poppedRoute);
            poppedRoute = entry.route;
          }
          entry.handlePop(
            navigator: this,
            previousPresent: _getRouteBefore(index, _RouteEntry.willBePresentPredicate)?.route,
          );
          assert(entry.currentState == _RouteLifecycle.popping);
          canRemoveOrAdd = true;
          break;
        case _RouteLifecycle.popping:
          // Will exit this state when animation completes.
          break;
        case _RouteLifecycle.remove:
          if (!seenTopActiveRoute) {
            if (poppedRoute != null)
              entry.route.didPopNext(poppedRoute);
            poppedRoute = null;
          }
          entry.handleRemoval(
            navigator: this,
            previousPresent: _getRouteBefore(index, _RouteEntry.willBePresentPredicate)?.route,
          );
          assert(entry.currentState == _RouteLifecycle.removing);
          continue;
        case _RouteLifecycle.removing:
          if (!canRemoveOrAdd && next != null) {
            // We aren't allowed to remove this route yet.
            break;
          }
          entry.currentState = _RouteLifecycle.dispose;
          continue;
        case _RouteLifecycle.dispose:
          // Delay disposal until didChangeNext/didChangePrevious have been sent.
          toBeDisposed.add(_history.removeAt(index));
          entry = next;
          break;
        case _RouteLifecycle.disposed:
        case _RouteLifecycle.staging:
          assert(false);
          break;
      }
      index -= 1;
      next = entry;
      entry = previous;
      previous = index > 0 ? _history[index - 1] : null;
    }

    // Informs navigator observers about route changes.
    _flushObserverNotifications();

    // Now that the list is clean, send the didChangeNext/didChangePrevious
    // notifications.
    _flushRouteAnnouncement();

    // Announces route name changes.
    if (widget.reportsRouteUpdateToEngine) {
      final _RouteEntry lastEntry = _history.lastWhere(
        _RouteEntry.isPresentPredicate, orElse: () => null);
      final String routeName = lastEntry?.route?.settings?.name;
      if (routeName != _lastAnnouncedRouteName) {
        SystemNavigator.routeUpdated(
          routeName: routeName,
          previousRouteName: _lastAnnouncedRouteName
        );
        _lastAnnouncedRouteName = routeName;
      }
    }

    // Lastly, removes the overlay entries of all marked entries and disposes
    // them.
    for (final _RouteEntry entry in toBeDisposed) {
      for (final OverlayEntry overlayEntry in entry.route.overlayEntries)
        overlayEntry.remove();
      entry.dispose();
    }
    if (rearrangeOverlay)
      overlay?.rearrange(_allRouteOverlayEntries);
  }

  void _flushObserverNotifications() {
    if (_effectiveObservers.isEmpty) {
      _observedRouteDeletions.clear();
      _observedRouteAdditions.clear();
      return;
    }
    while (_observedRouteAdditions.isNotEmpty) {
      final _NavigatorObservation observation = _observedRouteAdditions.removeLast();
      _effectiveObservers.forEach(observation.notify);
    }

    while (_observedRouteDeletions.isNotEmpty) {
      final _NavigatorObservation observation = _observedRouteDeletions.removeFirst();
      _effectiveObservers.forEach(observation.notify);
    }
  }

  void _flushRouteAnnouncement() {
    int index = _history.length - 1;
    while (index >= 0) {
      final _RouteEntry entry = _history[index];
      if (!entry.suitableForAnnouncement) {
        index -= 1;
        continue;
      }
      final _RouteEntry next = _getRouteAfter(index + 1, _RouteEntry.suitableForTransitionAnimationPredicate);

      if (next?.route != entry.lastAnnouncedNextRoute) {
        if (entry.shouldAnnounceChangeToNext(next?.route)) {
          entry.route.didChangeNext(next?.route);
        }
        entry.lastAnnouncedNextRoute = next?.route;
      }
      final _RouteEntry previous = _getRouteBefore(index - 1, _RouteEntry.suitableForTransitionAnimationPredicate);
      if (previous?.route != entry.lastAnnouncedPreviousRoute) {
        entry.route.didChangePrevious(previous?.route);
        entry.lastAnnouncedPreviousRoute = previous?.route;
      }
      index -= 1;
    }
  }

  _RouteEntry _getRouteBefore(int index, _RouteEntryPredicate predicate) {
    index = _getIndexBefore(index, predicate);
    return index >= 0 ? _history[index] : null;
  }

  int _getIndexBefore(int index, _RouteEntryPredicate predicate) {
    while(index >= 0 && !predicate(_history[index])) {
      index -= 1;
    }
    return index;
  }

  _RouteEntry _getRouteAfter(int index, _RouteEntryPredicate predicate) {
    while (index < _history.length && !predicate(_history[index])) {
      index += 1;
    }
    return index < _history.length ? _history[index] : null;
  }

  Route<T> _routeNamed<T>(String name, { @required Object arguments, bool allowNull = false }) {
    assert(!_debugLocked);
    assert(name != null);
    if (allowNull && widget.onGenerateRoute == null)
      return null;
    assert(() {
      if (widget.onGenerateRoute == null) {
        throw FlutterError(
          'Navigator.onGenerateRoute was null, but the route named "$name" was referenced.\n'
          'To use the Navigator API with named routes (pushNamed, pushReplacementNamed, or '
          'pushNamedAndRemoveUntil), the Navigator must be provided with an '
          'onGenerateRoute handler.\n'
          'The Navigator was:\n'
          '  $this'
        );
      }
      return true;
    }());
    final RouteSettings settings = RouteSettings(
      name: name,
      arguments: arguments,
    );
    Route<T> route = widget.onGenerateRoute(settings) as Route<T>;
    if (route == null && !allowNull) {
      assert(() {
        if (widget.onUnknownRoute == null) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('Navigator.onGenerateRoute returned null when requested to build route "$name".'),
            ErrorDescription(
              'The onGenerateRoute callback must never return null, unless an onUnknownRoute '
              'callback is provided as well.'
            ),
            DiagnosticsProperty<NavigatorState>('The Navigator was', this, style: DiagnosticsTreeStyle.errorProperty),
          ]);
        }
        return true;
      }());
      route = widget.onUnknownRoute(settings) as Route<T>;
      assert(() {
        if (route == null) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('Navigator.onUnknownRoute returned null when requested to build route "$name".'),
            ErrorDescription('The onUnknownRoute callback must never return null.'),
            DiagnosticsProperty<NavigatorState>('The Navigator was', this, style: DiagnosticsTreeStyle.errorProperty),
          ]);
        }
        return true;
      }());
    }
    assert(route != null || allowNull);
    return route;
  }

  /// Push a named route onto the navigator.
  ///
  /// {@macro flutter.widgets.navigator.pushNamed}
  ///
  /// {@macro flutter.widgets.navigator.pushNamed.arguments}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _aaronBurrSir() {
  ///   navigator.pushNamed('/nyc/1776');
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  Future<T> pushNamed<T extends Object>(
    String routeName, {
    Object arguments,
  }) {
    return push<T>(_routeNamed<T>(routeName, arguments: arguments));
  }

  /// Replace the current route of the navigator by pushing the route named
  /// [routeName] and then disposing the previous route once the new route has
  /// finished animating in.
  ///
  /// {@macro flutter.widgets.navigator.pushReplacementNamed}
  ///
  /// {@macro flutter.widgets.navigator.pushNamed.arguments}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _startBike() {
  ///   navigator.pushReplacementNamed('/jouett/1781');
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  Future<T> pushReplacementNamed<T extends Object, TO extends Object>(
    String routeName, {
    TO result,
    Object arguments,
  }) {
    return pushReplacement<T, TO>(_routeNamed<T>(routeName, arguments: arguments), result: result);
  }

  /// Pop the current route off the navigator and push a named route in its
  /// place.
  ///
  /// {@macro flutter.widgets.navigator.popAndPushNamed}
  ///
  /// {@macro flutter.widgets.navigator.pushNamed.arguments}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _begin() {
  ///   navigator.popAndPushNamed('/nyc/1776');
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  Future<T> popAndPushNamed<T extends Object, TO extends Object>(
    String routeName, {
    TO result,
    Object arguments,
  }) {
    pop<TO>(result);
    return pushNamed<T>(routeName, arguments: arguments);
  }

  /// Push the route with the given name onto the navigator, and then remove all
  /// the previous routes until the `predicate` returns true.
  ///
  /// {@macro flutter.widgets.navigator.pushNamedAndRemoveUntil}
  ///
  /// {@macro flutter.widgets.navigator.pushNamed.arguments}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _handleOpenCalendar() {
  ///   navigator.pushNamedAndRemoveUntil('/calendar', ModalRoute.withName('/'));
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  Future<T> pushNamedAndRemoveUntil<T extends Object>(
    String newRouteName,
    RoutePredicate predicate, {
    Object arguments,
  }) {
    return pushAndRemoveUntil<T>(_routeNamed<T>(newRouteName, arguments: arguments), predicate);
  }

  /// Push the given route onto the navigator.
  ///
  /// {@macro flutter.widgets.navigator.push}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _openPage() {
  ///   navigator.push(MaterialPageRoute(builder: (BuildContext context) => MyPage()));
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  Future<T> push<T extends Object>(Route<T> route) {
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    assert(route != null);
    assert(route._navigator == null);
    _history.add(_RouteEntry(route, initialState: _RouteLifecycle.push));
    _flushHistoryUpdates();
    assert(() {
      _debugLocked = false;
      return true;
    }());
    _afterNavigation(route);
    return route.popped;
  }

  void _afterNavigation<T>(Route<T> route) {
    if (!kReleaseMode) {
      // Among other uses, performance tools use this event to ensure that perf
      // stats reflect the time interval since the last navigation event
      // occurred, ensuring that stats only reflect the current page.

      Map<String, dynamic> routeJsonable;
      if (route != null) {
        routeJsonable = <String, dynamic>{};

        String description;
        if (route is TransitionRoute<T>) {
          final TransitionRoute<T> transitionRoute = route;
          description = transitionRoute.debugLabel;
        } else {
          description = '$route';
        }
        routeJsonable['description'] = description;

        final RouteSettings settings = route.settings;
        final Map<String, dynamic> settingsJsonable = <String, dynamic> {
          'name': settings.name,
        };
        if (settings.arguments != null) {
          settingsJsonable['arguments'] = jsonEncode(
            settings.arguments,
            toEncodable: (Object object) => '$object',
          );
        }
        routeJsonable['settings'] = settingsJsonable;
      }

      developer.postEvent('Flutter.Navigation', <String, dynamic>{
        'route': routeJsonable,
      });
    }
    _cancelActivePointers();
  }

  /// Replace the current route of the navigator by pushing the given route and
  /// then disposing the previous route once the new route has finished
  /// animating in.
  ///
  /// {@macro flutter.widgets.navigator.pushReplacement}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _doOpenPage() {
  ///   navigator.pushReplacement(
  ///       MaterialPageRoute(builder: (BuildContext context) => MyHomePage()));
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  Future<T> pushReplacement<T extends Object, TO extends Object>(Route<T> newRoute, { TO result }) {
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    assert(newRoute != null);
    assert(newRoute._navigator == null);
    assert(_history.isNotEmpty);
    assert(_history.any(_RouteEntry.isPresentPredicate), 'Navigator has no active routes to replace.');
    _history.lastWhere(_RouteEntry.isPresentPredicate).complete(result, isReplaced: true);
    _history.add(_RouteEntry(newRoute, initialState: _RouteLifecycle.pushReplace));
    _flushHistoryUpdates();
    assert(() {
      _debugLocked = false;
      return true;
    }());
    _afterNavigation(newRoute);
    return newRoute.popped;
  }

  /// Push the given route onto the navigator, and then remove all the previous
  /// routes until the `predicate` returns true.
  ///
  /// {@macro flutter.widgets.navigator.pushAndRemoveUntil}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _resetAndOpenPage() {
  ///   navigator.pushAndRemoveUntil(
  ///     MaterialPageRoute(builder: (BuildContext context) => MyHomePage()),
  ///     ModalRoute.withName('/'),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  Future<T> pushAndRemoveUntil<T extends Object>(Route<T> newRoute, RoutePredicate predicate) {
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    assert(newRoute != null);
    assert(newRoute._navigator == null);
    assert(newRoute.overlayEntries.isEmpty);
    assert(predicate != null);
    int index = _history.length - 1;
    _history.add(_RouteEntry(newRoute, initialState: _RouteLifecycle.push));
    while (index >= 0 && !predicate(_history[index].route)) {
      if (_history[index].isPresent)
        _history[index].remove();
      index -= 1;
    }
    _flushHistoryUpdates();

    assert(() {
      _debugLocked = false;
      return true;
    }());
    _afterNavigation(newRoute);
    return newRoute.popped;
  }

  /// Replaces a route on the navigator with a new route.
  ///
  /// {@macro flutter.widgets.navigator.replace}
  ///
  /// See also:
  ///
  ///  * [replaceRouteBelow], which is the same but identifies the route to be
  ///    removed by reference to the route above it, rather than directly.
  @optionalTypeArgs
  void replace<T extends Object>({ @required Route<dynamic> oldRoute, @required Route<T> newRoute }) {
    assert(!_debugLocked);
    assert(oldRoute != null);
    assert(newRoute != null);
    if (oldRoute == newRoute)
      return;
    assert(() {
      _debugLocked = true;
      return true;
    }());
    assert(oldRoute._navigator == this);
    assert(newRoute._navigator == null);
    final int index = _history.indexWhere(_RouteEntry.isRoutePredicate(oldRoute));
    assert(index >= 0, 'This Navigator does not contain the specified oldRoute.');
    assert(_history[index].isPresent, 'The specified oldRoute has already been removed from the Navigator.');
    final bool wasCurrent = oldRoute.isCurrent;
    _history.insert(index + 1, _RouteEntry(newRoute, initialState: _RouteLifecycle.replace));
    _history[index].remove(isReplaced: true);
    _flushHistoryUpdates();
    assert(() {
      _debugLocked = false;
      return true;
    }());
    if (wasCurrent)
      _afterNavigation(newRoute);
  }

  /// Replaces a route on the navigator with a new route. The route to be
  /// replaced is the one below the given `anchorRoute`.
  ///
  /// {@macro flutter.widgets.navigator.replaceRouteBelow}
  ///
  /// See also:
  ///
  ///  * [replace], which is the same but identifies the route to be removed
  ///    directly.
  @optionalTypeArgs
  void replaceRouteBelow<T extends Object>({ @required Route<dynamic> anchorRoute, @required Route<T> newRoute }) {
    assert(!_debugLocked);
    assert(() { _debugLocked = true; return true; }());
    assert(anchorRoute != null);
    assert(anchorRoute._navigator == this);
    assert(newRoute != null);
    assert(newRoute._navigator == null);
    final int anchorIndex = _history.indexWhere(_RouteEntry.isRoutePredicate(anchorRoute));
    assert(anchorIndex >= 0, 'This Navigator does not contain the specified anchorRoute.');
    assert(_history[anchorIndex].isPresent, 'The specified anchorRoute has already been removed from the Navigator.');
    int index = anchorIndex - 1;
    while (index >= 0) {
      if (_history[index].isPresent)
        break;
      index -= 1;
    }
    assert(index >= 0, 'There are no routes below the specified anchorRoute.');
    _history.insert(index + 1, _RouteEntry(newRoute, initialState: _RouteLifecycle.replace));
    _history[index].remove(isReplaced: true);
    _flushHistoryUpdates();
    assert(() { _debugLocked = false; return true; }());
  }

  /// Whether the navigator can be popped.
  ///
  /// {@macro flutter.widgets.navigator.canPop}
  ///
  /// See also:
  ///
  ///  * [Route.isFirst], which returns true for routes for which [canPop]
  ///    returns false.
  bool canPop() {
    final Iterator<_RouteEntry> iterator = _history.where(_RouteEntry.isPresentPredicate).iterator;
    if (!iterator.moveNext())
      return false; // we have no active routes, so we can't pop
    if (iterator.current.route.willHandlePopInternally)
      return true; // the first route can handle pops itself, so we can pop
    if (!iterator.moveNext())
      return false; // there's only one route, so we can't pop
    return true; // there's at least two routes, so we can pop
  }

  /// Consults the current route's [Route.willPop] method, and acts accordingly,
  /// potentially popping the route as a result; returns whether the pop request
  /// should be considered handled.
  ///
  /// {@macro flutter.widgets.navigator.maybePop}
  ///
  /// See also:
  ///
  ///  * [Form], which provides an `onWillPop` callback that enables the form
  ///    to veto a [pop] initiated by the app's back button.
  ///  * [ModalRoute], which provides a `scopedWillPopCallback` that can be used
  ///    to define the route's `willPop` method.
  Future<bool> maybePop<T extends Object>([ T result ]) async {
    final _RouteEntry lastEntry = _history.lastWhere(_RouteEntry.isPresentPredicate, orElse: () => null);
    if (lastEntry == null)
      return false;
    assert(lastEntry.route._navigator == this);
    final RoutePopDisposition disposition = await lastEntry.route.willPop(); // this is asynchronous
    assert(disposition != null);
    if (!mounted)
      return true; // forget about this pop, we were disposed in the meantime
    final _RouteEntry newLastEntry = _history.lastWhere(_RouteEntry.isPresentPredicate, orElse: () => null);
    if (lastEntry != newLastEntry)
      return true; // forget about this pop, something happened to our history in the meantime
    switch (disposition) {
      case RoutePopDisposition.bubble:
        return false;
      case RoutePopDisposition.pop:
        pop(result);
        return true;
      case RoutePopDisposition.doNotPop:
        return true;
    }
    return null;
  }

  /// Pop the top-most route off the navigator.
  ///
  /// {@macro flutter.widgets.navigator.pop}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage for closing a route is as follows:
  ///
  /// ```dart
  /// void _handleClose() {
  ///   navigator.pop();
  /// }
  /// ```
  /// {@end-tool}
  /// {@tool snippet}
  ///
  /// A dialog box might be closed with a result:
  ///
  /// ```dart
  /// void _handleAccept() {
  ///   navigator.pop(true); // dialog returns true
  /// }
  /// ```
  /// {@end-tool}
  @optionalTypeArgs
  void pop<T extends Object>([ T result ]) {
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    final _RouteEntry entry = _history.lastWhere(_RouteEntry.isPresentPredicate);
    if (entry.hasPage) {
      if (widget.onPopPage(entry.route, result))
        entry.currentState = _RouteLifecycle.pop;
    } else {
      entry.pop<T>(result);
    }
    if (entry.currentState == _RouteLifecycle.pop) {
      // Flush the history if the route actually wants to be popped (the pop
      // wasn't handled internally).
      _flushHistoryUpdates(rearrangeOverlay: false);
      assert(entry.route._popCompleter.isCompleted);
    }
    assert(() {
      _debugLocked = false;
      return true;
    }());
    _afterNavigation<dynamic>(entry.route);
  }

  /// Calls [pop] repeatedly until the predicate returns true.
  ///
  /// {@macro flutter.widgets.navigator.popUntil}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// void _doLogout() {
  ///   navigator.popUntil(ModalRoute.withName('/login'));
  /// }
  /// ```
  /// {@end-tool}
  void popUntil(RoutePredicate predicate) {
    _RouteEntry candidate = _history.lastWhere(_RouteEntry.isPresentPredicate, orElse: () => null);
    while(candidate != null) {
      if (predicate(candidate.route))
        return;
      pop();
      candidate = _history.lastWhere(_RouteEntry.isPresentPredicate, orElse: () => null);
    }
  }

  /// Immediately remove `route` from the navigator, and [Route.dispose] it.
  ///
  /// {@macro flutter.widgets.navigator.removeRoute}
  void removeRoute(Route<dynamic> route) {
    assert(route != null);
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    assert(route._navigator == this);
    final bool wasCurrent = route.isCurrent;
    final _RouteEntry entry = _history.firstWhere(_RouteEntry.isRoutePredicate(route), orElse: () => null);
    assert(entry != null);
    entry.remove();
    _flushHistoryUpdates(rearrangeOverlay: false);
    assert(() {
      _debugLocked = false;
      return true;
    }());
    if (wasCurrent)
      _afterNavigation<dynamic>(
        _history.lastWhere(
          _RouteEntry.isPresentPredicate,
          orElse: () => null
        )?.route
      );
  }

  /// Immediately remove a route from the navigator, and [Route.dispose] it. The
  /// route to be removed is the one below the given `anchorRoute`.
  ///
  /// {@macro flutter.widgets.navigator.removeRouteBelow}
  void removeRouteBelow(Route<dynamic> anchorRoute) {
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    assert(anchorRoute != null);
    assert(anchorRoute._navigator == this);
    final int anchorIndex = _history.indexWhere(_RouteEntry.isRoutePredicate(anchorRoute));
    assert(anchorIndex >= 0, 'This Navigator does not contain the specified anchorRoute.');
    assert(_history[anchorIndex].isPresent, 'The specified anchorRoute has already been removed from the Navigator.');
    int index = anchorIndex - 1;
    while (index >= 0) {
      if (_history[index].isPresent)
        break;
      index -= 1;
    }
    assert(index >= 0, 'There are no routes below the specified anchorRoute.');
    _history[index].remove();
    _flushHistoryUpdates(rearrangeOverlay: false);
    assert(() {
      _debugLocked = false;
      return true;
    }());
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
    // FinalizeRoute may have been called while we were already locked as a
    // responds to route.didPop(). Make sure to leave in the state we were in
    // before the call.
    bool wasDebugLocked;
    assert(() { wasDebugLocked = _debugLocked; _debugLocked = true; return true; }());
    assert(_history.where(_RouteEntry.isRoutePredicate(route)).length == 1);
    final _RouteEntry entry =  _history.firstWhere(_RouteEntry.isRoutePredicate(route));
    if (entry.doingPop) {
      // We were called synchronously from Route.didPop(), but didn't process
      // the pop yet. Let's do that now before finalizing.
      entry.currentState = _RouteLifecycle.pop;
      _flushHistoryUpdates(rearrangeOverlay: false);
    }
    assert(entry.currentState != _RouteLifecycle.pop);
    entry.finalize();
    _flushHistoryUpdates(rearrangeOverlay: false);
    assert(() { _debugLocked = wasDebugLocked; return true; }());
  }

  int get _userGesturesInProgress => _userGesturesInProgressCount;
  int _userGesturesInProgressCount = 0;
  set _userGesturesInProgress(int value) {
    _userGesturesInProgressCount = value;
    userGestureInProgressNotifier.value = _userGesturesInProgress > 0;
  }

  /// Whether a route is currently being manipulated by the user, e.g.
  /// as during an iOS back gesture.
  ///
  /// See also:
  ///
  ///  * [userGestureInProgressNotifier], which notifies its listeners if
  ///    the value of [userGestureInProgress] changes.
  bool get userGestureInProgress => userGestureInProgressNotifier.value;

  /// Notifies its listeners if the value of [userGestureInProgress] changes.
  final ValueNotifier<bool> userGestureInProgressNotifier = ValueNotifier<bool>(false);


  /// The navigator is being controlled by a user gesture.
  ///
  /// For example, called when the user beings an iOS back gesture.
  ///
  /// When the gesture finishes, call [didStopUserGesture].
  void didStartUserGesture() {
    _userGesturesInProgress += 1;
    if (_userGesturesInProgress == 1) {
      final int routeIndex = _getIndexBefore(
        _history.length - 1,
        _RouteEntry.willBePresentPredicate,
      );
      assert(routeIndex != null);
      final Route<dynamic> route = _history[routeIndex].route;
      Route<dynamic> previousRoute;
      if (!route.willHandlePopInternally && routeIndex > 0) {
        previousRoute = _getRouteBefore(
          routeIndex - 1,
          _RouteEntry.willBePresentPredicate,
        ).route;
      }
      for (final NavigatorObserver observer in _effectiveObservers)
        observer.didStartUserGesture(route, previousRoute);
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
      for (final NavigatorObserver observer in _effectiveObservers)
        observer.didStopUserGesture();
    }
  }

  final Set<int> _activePointers = <int>{};

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
      final RenderAbsorbPointer absorber = _overlayKey.currentContext?.findAncestorRenderObjectOfType<RenderAbsorbPointer>();
      setState(() {
        absorber?.absorbing = true;
        // We do this in setState so that we'll reset the absorbing value back
        // to false on the next frame.
      });
    }
    _activePointers.toList().forEach(WidgetsBinding.instance.cancelPointer);
  }

  @override
  Widget build(BuildContext context) {
    assert(!_debugLocked);
    assert(_history.isNotEmpty);
    // Hides the HeroControllerScope for the widget subtree so that the other
    // nested navigator underneath will not pick up the hero controller above
    // this level.
    return HeroControllerScope.none(
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerUpOrCancel,
        onPointerCancel: _handlePointerUpOrCancel,
        child: AbsorbPointer(
          absorbing: false, // it's mutated directly by _cancelActivePointers above
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: Overlay(
              key: _overlayKey,
              initialEntries: overlay == null ?  _allRouteOverlayEntries.toList(growable: false) : const <OverlayEntry>[],
            ),
          ),
        ),
      ),
    );
  }
}
