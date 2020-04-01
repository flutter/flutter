// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'navigator.dart';
import 'route_notification_messages.dart';

/// The dispatcher for opening and closing pages of an application.
///
/// This widget listens for routing information from the operating system (e.g.
/// an initial route provided on app startup, a new route obtained when an
/// intent is received, or a notification that the user hit the system back
/// button), parses route information into data of type `T`, and then converts
/// that data into [Page] objects that it passes to a [Navigator].
///
/// Additionally, every single part of that previous sentence can be overridden
/// and configured as desired.
///
/// The [routeNameProvider] can be overridden to change how the name of the
/// route is obtained. the [RouteNameProvider.value] when the [Router] is first
/// created is used as the initial route, and subsequent notifications from the
/// [RouteNameProvider] to its listeners are treated as notifications that the
/// route name has changed.
///
/// The [backButtonDispatcher] can be overridden to change how back button
/// notifications are received. This must be a [BackButtonDispatcher], which is
/// an object where callbacks can be registered, and which can be chained
/// so that back button presses are delegated to subsidiary routers. The
/// callbacks are invoked to indicate that the user is trying to close the
/// current route (by pressing the system back button); the [Router] ensures
/// that when this callback is invoked, the message is passed to the
/// [routerDelegate] and its result is provided back to the
/// [backButtonDispatcher]. Some platforms don't have back buttons and on those
/// platforms it is completely normal that this notification is never sent. The
/// common [backButtonDispatcher] for root router is an instance of
/// [RootBackButtonDispatcher], which uses a [WidgetsBindingObserver] to listen
/// to the `popRoute` notifications from [SystemChannels.navigation]. A
/// common alternative is [ChildBackButtonDispatcher], which must be provided
/// the [BackButtonDispatcher] of its ancestor [Router] (available via
/// [Router.of]).
///
/// The [routeNameParser] can be overridden to change how names obtained from
/// the [routeNameProvider] are interpreted. It must implement the
/// [RouteNameParser] interface, specialized with the same type as the [Router]
/// itself. This type, `T`, represents the data type that the [routeNameParser]
/// will generate.
///
/// The [routerDelegate] can be overridden to change how the output of the
/// [routeNameParser] is interpreted. It must implement the
/// [RouterDelegate] interface, also specialized with `T`; it takes as input
/// the data (of type `T`) from the [routeNameParser], and is responsible for
/// providing a navigational widget to insert into the widget tree. The
/// [RouterDelegate] interface is also [Listenable]; notifications are taken
/// to mean that the [Router] needs to rebuild.
///
/// ## Concerns regarding asynchrony
///
/// Some of the APIs (notably those involving [RouteNameParser] and
/// [RouterDelegate]) are asynchronous.
///
/// When developing objects implementing these APIs, if the work can be done
/// entirely synchronously, then consider using [SynchronousFuture] for the
/// future returned from the relevant methods. This will allow the [Router] to
/// proceed in a completely synchronous way, which removes a number of
/// complications.
///
/// Using asynchronous computation is entirely reasonable, however, and the API
/// is designed to support it. For example, maybe a set of images need to be
/// loaded before a route can be shown; waiting for those images to be loaded
/// before [ParsedRouteHandler.pushRoute] returns is a reasonable approach to
/// handle this case.
///
/// If an asynchronous operation is ongoing when a new one is to be started, the
/// precise behavior will depend on the exact circumstances, as follows:
///
/// If the active operation is a [routeNameParser] parsing a new route name:
/// that operation's result, if it ever completes, will be discarded.
///
/// If the active operation is a [routerDelegate] handling a pop request:
/// the previous pop is immediately completed with "false", claiming that the
/// previous pop was not handled (this may cause the application to close).
///
/// If the active operation is a [routerDelegate] handling an initial route
/// or a pushed route, the result depends on the new operation. If the new
/// operation is a pop request, then the original operation's result, if it ever
/// completes, will be discarded. If the new operation is a push request,
/// however, the [routeNameParser] will be requested to start the parsing, and
/// only if that finishes before the original [routerDelegate] request
/// completes will that original request's result be discarded.
///
/// If the identity of the [Router] widget's delegates change while an
/// asynchronous operation is in progress, to keep matters simple, all active
/// asynchronous operations will have their results discarded. It is generally
/// considered unusual for these delegates to change during the lifetime of the
/// [Router].
///
/// If the [Router] itself is disposed while an an asynchronous operation is in
/// progress, all active asynchronous operations will have their results
/// discarded also.
///
/// No explicit signals are provided to the [routeNameParser] or
/// [routerDelegate] to indicate when any of the above happens, so it is
/// strongly recommended that [RouteNameParser] and [ParsedRouteHandler]
/// implementations not perform extensive computation.
///
/// ## Application architectural design
///
/// An application can have zero, one, or many [Router] widgets, depending on
/// its needs.
///
/// An application might have no [Router] widgets if it has only one "screen",
/// or if the facilities provided by [Navigator] are sufficient.
///
/// A particularly elaborate application might have multiple [Router] widgets,
/// in a tree configuration, with the first handling the entire route parsing
/// and making the result available for routers in the subtree. The routers in
/// the subtree do not participate in route name parsing but merely take the
/// result from the first router to build their sub routes.
///
/// Most applications only need a single [Router].
///
/// ## URL updates for web applications
///
/// In the web platform, it is important to keeps the URL up to date with the
/// app state. This ensures the browser constructs its history entry
/// correctly so that its forward and backward buttons continue to work.
///
/// If a app state change leads to [Router] rebuilds (usually triggered by a
/// navigational method), the [Router] will detect such event and intend to
/// report the new route name back to the web engine by using the
/// [RouterDelegate.currentConfiguration] and the [RouteNameParser.restore].
/// Providing implementations of these two methods in the subclasses enables the
/// [Router] widget to successfully update the URL in the web engine.
///
/// You can also choose to opt out of URL updates. Simply ignore the
/// [RouterDelegate.currentConfiguration] and the [RouteNameParser.restore]
/// without providing the implementations will prevent the [Router] from
/// reporting the URL back to the web engine. You will want to opt out in these
/// cases:
///
/// If you are not writing a web application.
///
/// If you have multiple router widgets in your app, then only one router widget
/// should update the URL (Usually the top-most one).
///
/// If your app does not care about the in-app navigation using the browser's
/// forward and backward buttons.
///
/// Otherwise, we strongly recommend implementing the
/// [RouterDelegate.currentConfiguration] and the [RouteNameParser.restore]
/// to provide optimal experience in the web application.
class Router<T> extends StatefulWidget {
  /// Creates a router.
  ///
  /// The [routeNameProvider] and [routeNameParser] can be null if this
  /// router does not depend on route names. A common example is a sub router
  /// that builds its content completely relies on the app state.
  ///
  /// If the [routeNameProvider] is not null, the [routeNameParser] must
  /// also not be null.
  ///
  /// The [routerDelegate] must not be null.
  const Router({
    Key key,
    this.routeNameProvider,
    this.routeNameParser,
    this.backButtonDispatcher,
    @required this.routerDelegate,
  }) : assert(routeNameProvider == null || routeNameParser != null),
       assert(routerDelegate != null),
       super(key: key);

  /// The route name provider for the router.
  ///
  /// The value at the time of first build will be used as the initial route.
  /// The [Router] listens to this provider and rebuilds with new names when
  /// it notifies.
  ///
  /// This can be null if this router does not rely on the route name
  /// to build its content. In such case, the [routeNameParser] can also be
  /// null.
  final RouteNameProvider routeNameProvider;

  /// The back button dispatcher for the router.
  ///
  /// The two common alternatives are the [RootBackButtonDispatcher] for root
  /// router, or the [ChildBackButtonDispatcher] for other routers.
  final BackButtonDispatcher backButtonDispatcher;

  /// The route name parser for the router.
  ///
  /// When the [Router] gets a new route name from the [routeNameProvider],
  /// the [Router] uses this delegate to parse the route name and produce a
  /// configuration. The configuration will be used by [routerDelegate] and
  /// eventually rebuilds the [Router] widget.
  ///
  /// Since this delegate is the primary consumer of the [routeNameProvider],
  /// it must not be null if [routeNameProvider] is not null.
  final RouteNameParser<T> routeNameParser;

  /// The router delegate for the router.
  ///
  /// This delegate consumes the configuration from [routeNameParser] and
  /// builds a navigational widget for the [Router].
  ///
  /// It is also the primary respondent for the [backButtonDispatcher]. The
  /// [Router] relies on the [RouterDelegate.popRoute] to handles the back
  /// button intends.
  ///
  /// If the [RouterDelegate.currentConfiguration] returns a non-null object,
  /// this [Router] will opt for URL updates.
  final RouterDelegate<T> routerDelegate;

  /// Retrieve the router of exact type.
  static Router<R> of<R>(BuildContext context) {
    final _RouterScope scope = context.dependOnInheritedWidgetOfExactType<_RouterScope>();
    assert(scope != null);
    return scope.routerState.widget as Router<R>;
  }

  @override
  State<Router<T>> createState() => _RouterState<T>();
}

typedef _AsyncPassthrough<Q> = Future<Q> Function(Q);

class _RouterState<T> extends State<Router<T>> {
  Object _currentRouteNameParserTransaction;
  Object _currentRouterDelegateTransaction;

  @override
  void initState() {
    super.initState();
    widget.routeNameProvider?.addListener(_handleRouteNameProviderNotification);
    widget?.backButtonDispatcher?.addCallback(_handleBackButtonDispatcherNotification);
    widget.routerDelegate.addListener(_handleRouterDelegateNotification);
    if (widget.routeNameProvider != null) {
      _processInitialRoute();
    }
  }

  void _reportRouteName() {
    final T configuration = widget.routerDelegate.currentConfiguration;
    if (configuration != null) {
      final String routeName = widget.routeNameParser.restore(configuration);
      assert(routeName != null);
      if (widget.routeNameProvider.value != routeName)
        widget.routeNameProvider.routerReportsNewRouteName(routeName);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reportRouteName();
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _reportRouteName();
  }

  @override
  void didUpdateWidget(Router<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routeNameProvider != oldWidget.routeNameProvider ||
      widget.backButtonDispatcher != oldWidget.backButtonDispatcher ||
      widget.routeNameParser != oldWidget.routeNameParser ||
      widget.routerDelegate != oldWidget.routerDelegate) {
      _currentRouteNameParserTransaction = Object();
      _currentRouterDelegateTransaction = Object();
    }
    if (widget.routeNameProvider != oldWidget.routeNameProvider) {
      oldWidget.routeNameProvider?.removeListener(_handleRouteNameProviderNotification);
      widget.routeNameProvider?.addListener(_handleRouteNameProviderNotification);
    }
    if (widget.backButtonDispatcher != oldWidget.backButtonDispatcher) {
      oldWidget?.backButtonDispatcher?.removeCallback(_handleBackButtonDispatcherNotification);
      widget?.backButtonDispatcher?.addCallback(_handleBackButtonDispatcherNotification);
    }
    if (widget.routerDelegate != oldWidget.routerDelegate) {
      oldWidget.routerDelegate.removeListener(_handleRouterDelegateNotification);
      widget.routerDelegate.addListener(_handleRouterDelegateNotification);
      _reportRouteName();
    }
  }

  @override
  void dispose() {
    widget.routeNameProvider?.removeListener(_handleRouteNameProviderNotification);
    widget?.backButtonDispatcher?.removeCallback(_handleBackButtonDispatcherNotification);
    widget.routerDelegate.removeListener(_handleRouterDelegateNotification);
    _currentRouteNameParserTransaction = null;
    _currentRouterDelegateTransaction = null;
    super.dispose();
  }

  void _processInitialRoute() {
    _currentRouteNameParserTransaction = Object();
    _currentRouterDelegateTransaction = Object();
    widget.routeNameParser.parse(widget.routeNameProvider.value)
      .then<T>(_verifyRouteNameParserStillCurrent(_currentRouteNameParserTransaction, widget))
      .then<void>(widget.routerDelegate.setInitialRoutePath)
      .then<void>(_verifyParsedRouteHandlerPushStillCurrent(_currentRouterDelegateTransaction, widget))
      .then<void>(_rebuild);
  }

  void _handleRouteNameProviderNotification() {
    _currentRouteNameParserTransaction = Object();
    _currentRouterDelegateTransaction = Object();
    widget.routeNameParser.parse(widget.routeNameProvider.value)
      .then<T>(_verifyRouteNameParserStillCurrent(_currentRouteNameParserTransaction, widget))
      .then<void>(widget.routerDelegate.setNewRoutePath)
      .then<void>(_verifyParsedRouteHandlerPushStillCurrent(_currentRouterDelegateTransaction, widget))
      .then<void>(_rebuild);
  }

  Future<bool> _handleBackButtonDispatcherNotification() {
    _currentRouteNameParserTransaction = Object();
    _currentRouterDelegateTransaction = Object();
    return widget.routerDelegate.popRoute()
      .then<bool>(_verifyParsedRouteHandlerPopStillCurrent(_currentRouterDelegateTransaction, widget));
  }

  static final Future<dynamic> _never = Completer<dynamic>().future; // won't ever complete

  _AsyncPassthrough<T> _verifyRouteNameParserStillCurrent(Object transaction, Router<T> originalWidget) {
    return (T data) {
      if (transaction == _currentRouteNameParserTransaction &&
        widget.routeNameProvider == originalWidget.routeNameProvider &&
        widget.backButtonDispatcher == originalWidget.backButtonDispatcher &&
        widget.routeNameParser == originalWidget.routeNameParser &&
        widget.routerDelegate == originalWidget.routerDelegate) {
        return SynchronousFuture<T>(data);
      }
      return _never as Future<T>;
    };
  }

  _AsyncPassthrough<void> _verifyParsedRouteHandlerPushStillCurrent(Object transaction, Router<T> originalWidget) {
    return (void data) {
      if (transaction == _currentRouterDelegateTransaction &&
        widget.routeNameProvider == originalWidget.routeNameProvider &&
        widget.backButtonDispatcher == originalWidget.backButtonDispatcher &&
        widget.routeNameParser == originalWidget.routeNameParser &&
        widget.routerDelegate == originalWidget.routerDelegate)
        return SynchronousFuture<void>(data);
      return _never;
    };
  }

  _AsyncPassthrough<bool> _verifyParsedRouteHandlerPopStillCurrent(Object transaction, Router<T> originalWidget) {
    return (bool data) {
      if (transaction == _currentRouterDelegateTransaction &&
        widget.routeNameProvider == originalWidget.routeNameProvider &&
        widget.backButtonDispatcher == originalWidget.backButtonDispatcher &&
        widget.routeNameParser == originalWidget.routeNameParser &&
        widget.routerDelegate == originalWidget.routerDelegate)
        return SynchronousFuture<bool>(data);
      return SynchronousFuture<bool>(false);
    };
  }

  Future<void> _rebuild(void value) {
    setState(() { /* routerDelegate is ready to rebuild */ });
    return SynchronousFuture<void>(value);
  }

  void _handleRouterDelegateNotification() {
    setState(() { /* routerDelegate wants to rebuild */ });
  }

  @override
  Widget build(BuildContext context) {
    return _RouterScope(
      routeNameProvider: widget.routeNameProvider,
      backButtonDispatcher: widget.backButtonDispatcher,
      routeNameParser: widget.routeNameParser,
      routerDelegate: widget.routerDelegate,
      routerState: this,
      child: Builder(
        // We use a Builder so that the build method below
        // will have a BuildContext that contains the _RouterScope.
        builder: widget.routerDelegate.build,
      ),
    );
  }
}

class _RouterScope extends InheritedWidget {
  const _RouterScope({
    Key key,
    @required this.routeNameProvider,
    @required this.backButtonDispatcher,
    @required this.routeNameParser,
    @required this.routerDelegate,
    @required this.routerState,
    @required Widget child,
  }) : assert(routeNameProvider == null || routeNameParser != null),
       assert(routerDelegate != null),
       assert(routerState != null),
       super(key: key, child: child);

  final ValueListenable<String> routeNameProvider;
  final BackButtonDispatcher backButtonDispatcher;
  final RouteNameParser<dynamic> routeNameParser;
  final RouterDelegate<dynamic> routerDelegate;
  final _RouterState<dynamic> routerState;

  @override
  bool updateShouldNotify(_RouterScope oldWidget) {
    return routeNameProvider != oldWidget.routeNameProvider
      || backButtonDispatcher != oldWidget.backButtonDispatcher
      || routeNameParser != oldWidget.routeNameParser
      || routerDelegate != oldWidget.routerDelegate
      || routerState != oldWidget.routerState;
  }
}

/// A class that can be extended or mixed in that invokes a single callback,
/// which then returns a value.
///
/// While multiple callbacks can be registered, when a notification is
/// dispatched there must be only a single callback. The return values of
/// multiple callbacks are not aggregated.
///
/// `T` is the return value expected from the callback.
///
/// See also:
///
///  * [Listenable] and its subclasses, which provide a similar mechanism for
///    one-way signalling.
class _CallbackHookProvider<T> {
  final ObserverList<ValueGetter<T>> _callbacks = ObserverList<ValueGetter<T>>();

  /// Whether a callback is currently registered.
  @protected
  bool get hasCallbacks {
    return _callbacks.isNotEmpty;
  }

  /// Register the callback to be called when the object changes.
  ///
  /// If other callbacks have already been registered, they must be removed
  /// (with [removeCallback]) before the callback is next called.
  void addCallback(ValueGetter<T> callback) {
    _callbacks.add(callback);
  }

  /// Remove a previously registered callback.
  ///
  /// If the given callback is not registered, the call is ignored.
  void removeCallback(ValueGetter<T> callback) {
    _callbacks.remove(callback);
  }

  /// Calls the (single) registered callback and returns its result.
  ///
  /// If no callback is registered, or if the callback throws, returns
  /// `defaultValue`.
  ///
  /// Call this method whenever the callback is to be invoked. If there is more
  /// than one callback registered, this method will throw a [StateError].
  ///
  /// Exceptions thrown by callbacks will be caught and reported using
  /// [FlutterError.reportError].
  @protected
  T invokeCallback(T defaultValue) {
    if (_callbacks.isEmpty)
      return defaultValue;
    try {
      return _callbacks.single();
    } catch (exception, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widget library',
          context: ErrorDescription('while invoking the callback for $runtimeType'),
          informationCollector: () sync* {
            yield DiagnosticsProperty<_CallbackHookProvider<T>>(
              'The $runtimeType that invoked the callback was:',
              this,
              style: DiagnosticsTreeStyle.errorProperty,
            );
          },
        )
      );
      return defaultValue;
    }
  }
}

/// Report to a [Router] when the user taps the back button on platforms that
/// support back buttons (such as Android).
///
/// When [Router] widgets are nested, consider using a
/// [ChildBackButtonDispatcher], passing it the parent [BackButtonDispatcher],
/// so that the back button requests get dispatched to the appropriate [Router].
/// To make this work properly, it's important that whenever a [Router] thinks
/// it should get the back button messages (e.g. after the user taps inside it),
/// it calls [takePriority] on its [BackButtonDispatcher] (or
/// [ChildBackButtonDispatcher]) instance.
///
/// The class takes a single callback, which must return a [Future<bool>]. The
/// callback's semantics match [WidgetsFlutterBinding.didPopRoute]'s, namely,
/// the callback should return a future that completes to true if it can handle
/// the pop request, and a future that completes to false otherwise.
abstract class BackButtonDispatcher extends _CallbackHookProvider<Future<bool>> {
  LinkedHashSet<ChildBackButtonDispatcher> _children;

  @override
  bool get hasCallbacks => super.hasCallbacks || (_children != null && _children.isNotEmpty);

  /// Handles a pop route request.
  ///
  /// This method prioritizes the children list in reverse order and calls
  /// [ChildBackButtonDispatcher.notifiedByParent] on them. If any of them
  /// handles the request (by returning a future with true), it exits this
  /// method by returning this future. Otherwise, it keeps moving on to the next
  /// child until a child handles the request. If none of the children handles
  /// the request, this back button dispatcher will then try to handle the request
  /// by itself. This back button dispatcher handles the request by notifying the
  /// router which in turn calls the [RouterDelegate.popRoute] and returns its
  /// result.
  ///
  /// To decide whether this back button dispatcher will handle the pop route
  /// request, you can override the [RouterDelegate.popRoute] of the router
  /// delegate you pass into the route with this back button dispatcher to
  /// return a future of true or false.
  @override
  Future<bool> invokeCallback(Future<bool> defaultValue) {
    if (_children != null && _children.isNotEmpty) {
      final List<ChildBackButtonDispatcher> children = _children.toList();
      int childIndex = children.length - 1;

      Future<bool> notifyNextChild(bool result) {
        // If the previous child handles the callback, we returns the result.
        if (result)
          return SynchronousFuture<bool>(result);
        // If the previous child did not handle the callback, we ask the next
        // child to handle the it.
        if (childIndex > 0) {
          childIndex -= 1;
          return children[childIndex].notifiedByParent(defaultValue).then<bool>(notifyNextChild);
        }
        // If none of the child handles the callback, the parent will then handle it.
        return super.invokeCallback(defaultValue);
      }
      return children[childIndex].notifiedByParent(defaultValue).then<bool>(notifyNextChild);
    }
    return super.invokeCallback(defaultValue);
  }

  /// Creates a [ChildBackButtonDispatcher] that is a direct decedent of this
  /// back button dispatcher.
  ///
  /// To participate in handling the pop route request, call the [takePriority]
  /// on the [ChildBackButtonDispatcher] created from this method.
  ///
  /// When the pop route request is handled by this back button dispatcher, it
  /// propagate the request to its direct decedents that has called the
  /// [takePriority] method. If there are multiple candidates, the latest one
  /// that called the [takePriority] wins the right to handle the request. If
  /// the latest one does not handle the request (by returning a future of
  /// false in [ChildBackButtonDispatcher.notifiedByParent]), the second latest
  /// one will then have the right to handle the request. This dispatcher
  /// continues finding the next candidate until there are no more candidates
  /// and finally handle the request itself.
  ChildBackButtonDispatcher createChildBackButtonDispatcher() {
    return ChildBackButtonDispatcher(this);
  }

  /// Make this [BackButtonDispatcher] take priority among its peers.
  ///
  /// This has no effect when a [BackButtonDispatcher] has no parents and no
  /// children. If a [BackButtonDispatcher] does have parents or children,
  /// however, it causes this object to be the one to dispatch the notification
  /// when the parent would normally notify its callback.
  ///
  /// The [BackButtonDispatcher] must have a listener registered before it can
  /// be told to take priority.
  void takePriority() {
    if (_children != null)
      _children.clear();
  }

  /// Mark the given child as taking priority over this object and the other
  /// children.
  ///
  /// This causes [invokeCallback] to defer to the given child instead of
  /// calling this object's callback.
  ///
  /// Children are stored in a list, so that if the current child is removed
  /// using [forget], a previous child will return to take its place. When
  /// [takePriority] is called, the list is cleared.
  ///
  /// Calling this again without first calling [forget] moves the child back to
  /// the head of the list.
  ///
  // (Actually it moves it to the end of the list and we treat the end of the
  // list to be the priority end, but that's an implementation detail.)
  //
  /// The [BackButtonDispatcher] must have a listener registered before it can
  /// be told to defer to a child.
  void deferTo(ChildBackButtonDispatcher child) {
    assert(hasCallbacks);
    _children ??= <ChildBackButtonDispatcher>{} as LinkedHashSet<ChildBackButtonDispatcher>;
    _children.remove(child); // child may or may not be in the set already
    _children.add(child);
  }

  /// Causes the given child to be removed from the list of children to which
  /// this object might defer, as if [deferTo] had never been called for that
  /// child.
  ///
  /// This should only be called once per child, even if [deferTo] was called
  /// multiple times for that child.
  ///
  /// If no children are left in the list, this object will stop deferring to
  /// its children. (This is not the same as calling [takePriority], since, if
  /// this object itself is a [ChildBackButtonDispatcher], [takePriority] would
  /// additionally attempt to claim priority from its parent, whereas removing
  /// the last child does not.)
  void forget(ChildBackButtonDispatcher child) {
    assert(_children != null);
    assert(_children.contains(child));
    _children.remove(child);
  }
}

/// The default implementation of back button dispatcher for the root router.
///
/// This dispatcher listens to platform pop route notifications. When the
/// platform wants to pop the current route, this dispatcher calls the
/// [BackButtonDispatcher.invokeCallback] method to handle the request.
class RootBackButtonDispatcher extends BackButtonDispatcher with WidgetsBindingObserver {
  /// Create a root back button dispatcher.
  RootBackButtonDispatcher();

  @override
  void addCallback(ValueGetter<Future<bool>> callback) {
    if (!hasCallbacks)
      WidgetsBinding.instance.addObserver(this);
    super.addCallback(callback);
  }

  @override
  void removeCallback(ValueGetter<Future<bool>> callback) {
    super.removeCallback(callback);
    if (!hasCallbacks)
      WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Future<bool> didPopRoute() => invokeCallback(Future<bool>.value(false));
}

/// A variant of [BackButtonDispatcher] which listens to notifications from a
/// parent back button dispatcher, and can take priority from its parent for the
/// handling of such notifications.
///
/// Useful when [Router]s are being nested within each other.
///
/// Use [Router.of] to obtain a reference to the nearest ancestor [Router], from
/// which the [Router.backButtonDispatcher] can be found, and then used as the
/// [parent] of the [ChildBackButtonDispatcher].
class ChildBackButtonDispatcher extends BackButtonDispatcher {
  /// Creates a back button dispatcher that acts as the child of another.
  ///
  /// The [parent] must not be null.
  ChildBackButtonDispatcher(this.parent) : assert(parent != null);

  /// The back button dispatcher that this object will attempt to take priority
  /// over when [takePriority] is called.
  ///
  /// The parent must have a listener registered before this child object can
  /// have its [takePriority] or [deferTo] methods used.
  final BackButtonDispatcher parent;

  /// The parent of this child back button dispatcher decide to let this
  /// child to handle the invoke the  callback request in
  /// [BackButtonDispatcher.invokeCallback].
  ///
  /// Return a boolean future with true if this child will handle the request;
  /// otherwise, return a boolean future with false.
  @protected
  Future<bool> notifiedByParent(Future<bool> defaultValue) {
    return invokeCallback(defaultValue);
  }

  @override
  void takePriority() {
    parent.deferTo(this);
    super.takePriority();
  }

  @override
  void deferTo(ChildBackButtonDispatcher child) {
    assert(hasCallbacks);
    super.deferTo(child);
  }

  @override
  void removeCallback(ValueGetter<Future<bool>> callback) {
    super.removeCallback(callback);
    if (!hasCallbacks)
      parent.forget(this);
  }
}

/// A delegate that is used by the [Router] widget to parse string route name
/// into a configuration of type T.
///
/// This delegate is used when the [Router] widget is first built with initial
/// route name from [Router.routeNameProvider] and any subsequent new route
/// notifications from it. The [Router] widget calls the [parse] with the string
/// route name.
abstract class RouteNameParser<T> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const RouteNameParser();

  /// Converts the given string into parsed data to pass to a
  /// [ParsedRouteHandler].
  ///
  /// The method should return a future which completes when the parsing is
  /// complete. The parsing may be asynchronous if, e.g., the parser needs to
  /// communicate with the OEM thread to obtain additional data about the route.
  ///
  /// Consider using a [SynchronousFuture] if the result can be computed
  /// synchronously, so that the [Router] does not need to wait for the next
  /// microtask to pass the data to the [ParsedRouteHandler].
  Future<T> parse(String routeName);

  /// Restore the route name from the given configuration.
  ///
  /// This is not required if you do not opt for the route name reporting, which
  /// is used for updating browser history for the web application. If you
  /// decides to opt in, you must also overrides this method to return a
  /// string route name.
  ///
  /// In practice, the route name returns from this method must be able to
  /// produce the same configuration when it is parsed by this route name parser
  String restore(T configuration) => null;
}

/// A delegate that is used by the [router] widget to build and configure a
/// navigational widget.
///
/// This delegate is the core piece of the [Router] widget. It responds to
/// push route and pop route intent from the engine and notifies the [Router]
/// to rebuild. It also act as a builder for the [Router] widget and builds a
/// navigational widget, typically a [Navigator], when the [Router] widget
/// builds.
///
/// When engine pushes a new route, the route name is parsed by the
/// [RouteNameParser] to produce a configuration of type T. The router delegate
/// receives the configuration through [setInitialRoutePath] or
/// [setNewRoutePath] to configure itself and builds the latest navigational
/// widget upon asked.
///
/// When implementing subclass, consider defining a listenable app
/// state to be used for building the navigational widget. The router delegate
/// should update the app state accordingly and notify the listener know the app
/// state has changed when it receive route related engine intents (e.g.
/// [setNewRoutePath], [setInitialRoutePath], or [popRoute]).
///
/// All subclass must implement [setNewRoutePath], [popRoute], and [build].
///
/// See also:
///
///  * [RouteNameParser], which is responsible for parsing the string route name
///    to a configuration before passing in to router delegate.
///  * [Router], which is the widget that wires all the delegates together to
///    provide a fully functional routing solution.
abstract class RouterDelegate<T> extends Listenable {
  /// Called by the [Router] at startup with the structure that the
  /// [RouteNameParser] obtained from parsing the initial route.
  ///
  /// This should configure the [RouterDelegate] so that when [build] is
  /// invoked, it will create a widget tree that matches the initial route.
  ///
  /// By default, this method forwards the [configuration] to [setNewRoutePath].
  ///
  /// Consider using a [SynchronousFuture] if the result can be computed
  /// synchronously, so that the [Router] does not need to wait for the next
  /// microtask to schedule a build.
  Future<void> setInitialRoutePath(T configuration) {
    return setNewRoutePath(configuration);
  }

  /// Called by the [Router] when the [Router.routeNameProvider] reports that a
  /// new route has been pushed to the application by the operating system.
  ///
  /// Consider using a [SynchronousFuture] if the result can be computed
  /// synchronously, so that the [Router] does not need to wait for the next
  /// microtask to schedule a build.
  Future<void> setNewRoutePath(T configuration);

  /// Called by the [Router] when the [Router.backButtonDispatcher] reports that
  /// the operating system is requesting that the current route be popped.
  ///
  /// The method should return a boolean [Future] to indicate whether this
  /// delegate handles the request. Returning false will cause the entire app
  /// to be popped.
  ///
  /// If the app state has changed as a result the pop, make sure to call the
  /// [notifyListeners] so that the listener, typically the [Router], can
  /// respond accordingly.
  ///
  /// Consider using a [SynchronousFuture] if the result can be computed
  /// synchronously, so that the [Router] does not need to wait for the next
  /// microtask to schedule a build.
  Future<bool> popRoute();

  /// Called by the [Router] when it detects a route name may have changed as a
  /// result of rebuild.
  ///
  /// If this getter returns non-null, the [Router] will start to report new
  /// route name back to the engine. In the web application, the new route
  /// names are used for populating browser history in order to support the
  /// forward and the backward buttons; Otherwise, this is not required for
  /// other platforms.
  ///
  /// By default, this getter returns null that prevents the [Router] to report
  /// the route name. To opt in, subclass can override this getter to return
  /// the current configuration.
  ///
  /// At most one [Router] can opt in to route name reporting. In common use
  /// case, only the top-most [Router] created by [WidgetsApp.router] should
  /// opt for route name reporting.
  T get currentConfiguration => null;

  /// Discards any resources used by the object.
  ///
  /// After this is called, the object is not in a usable state and should be
  /// discarded.
  ///
  /// This method should only be called by the object's owner.
  @mustCallSuper
  void dispose() { }

  /// Called by the [Router] to obtain the widget tree that represents the
  /// current state.
  ///
  /// This is called whenever the [setInitialRoutePath] method's future
  /// completes, the [setNewRoutePath] method's future completes with the value
  /// true, the [popRoute] method's future completes with the value true, or
  /// this object notifies its clients (see the [Listenable] interface, which
  /// this interface includes). In addition, it may be called at other times. It
  /// is important, therefore, that the methods above do not update the state
  /// that the [build] method uses before they complete their respective
  /// futures.
  ///
  /// Typically this method returns a suitably-configured [Navigator]. If you do
  /// plan to create a navigator, consider using the
  /// [PopNavigatorRouterDelegateMixin].
  ///
  /// This method must not return null.
  ///
  /// The `context` is the [Router]'s build context.
  Widget build(BuildContext context);
}

/// A route name provider that provides route name for the [Router] widget
///
/// This provider is responsible for handing the route name through [value]
/// getter and notifies listeners, typically the [Router] widget, when a new
/// route name is available.
///
/// If you decide to opt for the route name reporting (by overrides the
/// [RouterDelegate.currentConfiguration] to return non-null), overrides the
/// [routerReportsNewRouteName] method to reports the route name back to
/// the engine or uses the [RouteNameProviderReportBack] mixin to do so.
///
/// See also:
///
///  * [PlatformRouteNameProvider], which wires up the provider with the
///    [WidgetsBindingObserver.didPushRoute] to propagate platform push route
///    intent to the [Router] widget.
///  * [RouteNameProviderReportBack], which provides the implementation of
///    [routerReportsNewRouteName].
abstract class RouteNameProvider extends ValueListenable<String> {
  /// A callback called when the [Router] widget has a new route name that is
  /// different from the existing route name in this provider.
  void routerReportsNewRouteName(String routeName) { }

  /// Discards any resources used by the object.
  ///
  /// After this is called, the object is not in a usable state and should be
  /// discarded.
  ///
  /// This method should only be called by the object's owner.
  @mustCallSuper
  void dispose() { }
}

/// The route name provider that propagates the platform route name changes.
///
/// This provides also reports the new route name from the [Router] widget
/// back to engine using message channel method, the
/// [RouteNotificationMessages.maybeNotifyRouteChange].
class PlatformRouteNameProvider extends RouteNameProvider with WidgetsBindingObserver, ChangeNotifier {
  /// Create a platform route name provider.
  ///
  /// Use the [initialRouteName] to set the default route name for this
  /// provider.
  PlatformRouteNameProvider({
    String initialRouteName
  }) : _currentRouteNameInEngine = initialRouteName;

  String _currentRouteNameInEngine;

  @override
  void routerReportsNewRouteName(String routeName) {
    assert(_currentRouteNameInEngine != routeName);
    RouteNotificationMessages.maybeNotifyRouteChange(routeName, _currentRouteNameInEngine);
    _currentRouteNameInEngine = routeName;
  }


  @override
  String get value => _currentRouteNameInEngine;
  set value(String newValue) {
    if (_currentRouteNameInEngine == newValue)
      return;
    super.routerReportsNewRouteName(newValue);
    notifyListeners();
  }

  void _updateAndNotify(String newValue) {
    assert(_currentRouteNameInEngine != newValue);
    _currentRouteNameInEngine = newValue;
    notifyListeners();
  }

  void _platformReportsNewRouteName(String routeName) {
    if (_currentRouteNameInEngine == routeName)
      return;
    _updateAndNotify(routeName);
    // We can't use the _mayBeReportRouteName because we don't want to report
    // it back to the engine again.
    _currentRouteNameInEngine = routeName;
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners)
      WidgetsBinding.instance.addObserver(this);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners)
      WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void dispose() {
    // In practice, this will rarely be called. We assume that the listeners
    // will be added and removed in a coherent fashion such that when the object
    // is no longer being used, there's no listener, and so it will get garbage
    // collected.
    if (hasListeners)
      WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPushRoute(String route) async {
    assert(hasListeners);
    _platformReportsNewRouteName(route);
    return true;
  }
}

/// A mixin that wires [RouterDelegate.popRoute] to the [Navigator] it builds.
///
/// This mixin calls [Navigator.maybePop] when it receives an android back
/// button intent through the [RouterDelegate.popRoute]. Using this mixin
/// guarantees that the back button still respects pageless route in the
/// navigator.
///
/// Only use this mixin if you plan to build a navigator in the
/// [RouterDelegate.build].
mixin PopNavigatorRouterDelegateMixin<T> on RouterDelegate<T> {
  /// The key used for retrieving the current navigator.
  ///
  /// When using this mixin, be sure to use the same key to create the
  /// navigator.
  GlobalKey<NavigatorState> get navigatorKey;

  @override
  Future<bool> popRoute() {
    final NavigatorState navigator = navigatorKey?.currentState;
    if (navigator == null)
      return SynchronousFuture<bool>(false);
    return navigator.maybePop();
  }
}
