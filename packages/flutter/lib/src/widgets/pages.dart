// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'routes.dart';

/// A modal route that replaces the entire screen.
abstract class PageRoute<T> extends ModalRoute<T> {
  /// Creates a modal route that replaces the entire screen.
  PageRoute({
    RouteSettings settings: const RouteSettings(),
    this.fullscreenDialog: false,
  }) : super(settings: settings);

  /// Whether this page route is a full-screen dialog.
  ///
  /// In Material and Cupertino, being fullscreen has the effects of making
  /// the app bars have a close button instead of a back button. On
  /// iOS, dialogs transitions animate differently and are also not closeable
  /// with the back swipe gesture.
  final bool fullscreenDialog;

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => nextRoute is PageRoute<dynamic>;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> nextRoute) => nextRoute is PageRoute<dynamic>;

  @override
  AnimationController createAnimationController() {
    final AnimationController controller = super.createAnimationController();
    if (settings.isInitialRoute)
      controller.value = 1.0;
    return controller;
  }

  /// Subclasses can override this method to customize how heroes are inserted.
  void insertHeroOverlayEntry(OverlayEntry entry, Object tag, OverlayState overlay) {
    overlay.insert(entry);
  }
}

/// Signature for the [PageRouteBuilder] function that builds the route's
/// primary contents.
///
/// See [ModalRoute.buildPage] for complete definition of the parameters.
typedef Widget RoutePageBuilder(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation);

/// Signature for the [PageRouteBuilder] function that builds the route's
/// transitions.
///
/// See [ModalRoute.buildTransitions] for complete definition of the parameters.
typedef Widget RouteTransitionsBuilder(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child);

Widget _defaultTransitionsBuilder(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  return child;
}

/// A utility class for defining one-off page routes in terms of callbacks.
///
/// Callers must define the [pageBuilder] function which creates the route's
/// primary contents. To add transitions define the [transitionsBuilder] function.
class PageRouteBuilder<T> extends PageRoute<T> {
  /// Creates a route that deletates to builder callbacks.
  ///
  /// The [pageBuilder], [transitionsBuilder], [opaque], [barrierDismissible],
  /// and [maintainState] arguments must not be null.
  PageRouteBuilder({
    RouteSettings settings: const RouteSettings(),
    @required this.pageBuilder,
    this.transitionsBuilder: _defaultTransitionsBuilder,
    this.transitionDuration: const Duration(milliseconds: 300),
    this.opaque: true,
    this.barrierDismissible: false,
    this.barrierColor: null,
    this.maintainState: true,
  }) : assert(pageBuilder != null),
       assert(transitionsBuilder != null),
       assert(opaque != null),
       assert(barrierDismissible != null),
       assert(maintainState != null),
       super(settings: settings);

  /// Used build the route's primary contents.
  ///
  /// See [ModalRoute.buildPage] for complete definition of the parameters.
  final RoutePageBuilder pageBuilder;

  /// Used to build the route's transitions.
  ///
  /// See [ModalRoute.buildTransitions] for complete definition of the parameters.
  final RouteTransitionsBuilder transitionsBuilder;

  @override
  final Duration transitionDuration;

  @override
  final bool opaque;

  @override
  final bool barrierDismissible;

  @override
  final Color barrierColor;

  @override
  final bool maintainState;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return pageBuilder(context, animation, secondaryAnimation);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return transitionsBuilder(context, animation, secondaryAnimation, child);
  }

}

/// A [Navigator] observer that notifies [PageRouteAware]s of changes to the
/// state of their [PageRoute].
///
/// To make a [StatefulWidget] aware of its current [PageRoute] state, implement
/// [PageRouteAware] in its [State] and subscribe it to the [PageRouteObserver]:
///
/// ```dart
/// class PageRouteAwareWidgetState extends State<PageRouteAwareWidget> with PageRouteAware {
///   @override
///   void didChangeDependencies() {
///     super.didChangeDependencies();
///     pageRouteObserver.subscribe(this, ModalRoute.of(context));
///   }
///
///   @override
///   void dispose() {
///     pageRouteObserver.unsubscribe(this);
///     super.dispose();
///   }
///
///   @override
///   void didPush() {
///     // Do something
///   }
///
///   @override
///   void didPopNext() {
///     // Do something
///   }
///
/// }
/// ```
class PageRouteObserver extends NavigatorObserver {
  final Map<PageRoute<dynamic>, PageRouteAware> _listeners = <PageRoute<dynamic>, PageRouteAware>{};

  void subscribe(PageRouteAware routeAware, PageRoute<dynamic> route) {
    assert(routeAware != null);
    assert(route != null);
    if (!_listeners.containsKey(route)) {
      routeAware.didPush();
      _listeners[route] = routeAware;
    }
  }

  void unsubscribe(PageRouteAware routeAware) {
    assert(routeAware != null);
    _listeners.remove(routeAware);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route is PageRoute && previousRoute is PageRoute) {
      _listeners[previousRoute]?.didPopNext();
      _listeners[route]?.didPop();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route is PageRoute && previousRoute is PageRoute) {
      _listeners[previousRoute]?.didPushNext();
    }
  }
}

/// A interface that is aware of its current PageRoute.
abstract class PageRouteAware {
  /// Called when the top route has been popped off, and the current route
  /// shows up.
  void didPopNext() {}

  /// Called when the current route has been pushed.
  void didPush() {}

  /// Called when the current route has been popped off.
  void didPop() {}

  /// Called when a new route has been pushed, and the current route is no
  /// longer visible.
  void didPushNext() {}
}