// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'widget_tester.dart';
library;

import 'package:flutter/widgets.dart';

// Examples can assume:
// final TransitionDurationObserver transitionDurationObserver = TransitionDurationObserver();

/// Tracks the page transition duration of the current route.
///
/// Pass an instance to [Navigator.observers] or
/// [WidgetsApp.navigatorObservers], then access [transitionDuration].
class TransitionDurationObserver extends NavigatorObserver {
  TransitionRoute<void>? _currentTransitionRoute;

  /// The total duration of the current route's page transition.
  ///
  /// This does not consider whether a page transition is currently running. For
  /// example, if this is called halfway through a page transition, it will
  /// still return the full duration, not half.
  ///
  /// To pump until the route transition is finished and the previous route is
  /// completely gone, use the following:
  ///
  /// {@tool snippet}
  /// ```dart
  /// await tester.pump();
  /// await tester.pump(transitionDurationObserver.transitionDuration + const Duration(milliseconds: 1));
  /// ```
  /// {@end-tool}
  ///
  /// Throws if there is no current route or if the current route has no
  /// transition duration.
  Duration get transitionDuration {
    if (_currentTransitionRoute == null) {
      throw FlutterError('The current route is not a route with a page transition.');
    }
    return _currentTransitionRoute!.transitionDuration;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _currentTransitionRoute = route is TransitionRoute ? route : null;
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _currentTransitionRoute = previousRoute is TransitionRoute ? previousRoute : null;
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _currentTransitionRoute = previousRoute is TransitionRoute ? previousRoute : null;
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? oldRoute, Route<dynamic>? newRoute}) {
    _currentTransitionRoute = newRoute is TransitionRoute ? newRoute : null;
    super.didReplace(oldRoute: oldRoute, newRoute: newRoute);
  }
}
