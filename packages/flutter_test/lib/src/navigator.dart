// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'widget_tester.dart';
library;

import 'package:flutter/widgets.dart';

// Examples can assume:
// final TransitionDurationObserver transitionDurationObserver = TransitionDurationObserver();

/// Tracks the duration of the most recent page transition.
///
/// Pass an instance to [Navigator.observers] or
/// [WidgetsApp.navigatorObservers], then access [transitionDuration].
class TransitionDurationObserver extends NavigatorObserver {
  Duration? _transitionDuration;

  /// The total duration of the most recent page transition.
  ///
  /// When called during a page transition, it will return the full duration of
  /// the currently active page transition. If called immediately after a call
  /// to `Navigator.pop`, for example, it will return the duration of the
  /// transition triggered by that call. If called halfway through a page
  /// transition, it will still return the full duration, not half.
  ///
  /// To pump until the route transition is finished and the previous route is
  /// completely gone, use the following:
  ///
  /// {@tool snippet}
  /// ```dart
  /// testWidgets('MyWidget', (WidgetTester tester) async {
  ///   // ...Pump the app and start a page transition, then:
  ///   await tester.pump();
  ///   await tester.pump(transitionDurationObserver.transitionDuration + const Duration(milliseconds: 1));
  /// });
  /// ```
  /// {@end-tool}
  ///
  /// Throws if there has never been a page transition.
  Duration get transitionDuration {
    if (_transitionDuration == null) {
      throw FlutterError(
        'No route transition has occurred, but the transition duration was requested.',
      );
    }
    return _transitionDuration!;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // When pushing, the incoming route determines the transition duration.
    if (route is TransitionRoute) {
      _transitionDuration = route.transitionDuration;
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // When popping, the outgoing route's reverseTransitionDuration determines
    // the transition duration.
    if (route is TransitionRoute) {
      _transitionDuration = route.reverseTransitionDuration;
    }
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? oldRoute, Route<dynamic>? newRoute}) {
    // When replacing, the new route determines the transition duration.
    if (newRoute is TransitionRoute) {
      _transitionDuration = newRoute.transitionDuration;
    }
    super.didReplace(oldRoute: oldRoute, newRoute: newRoute);
  }

  // didRemove is not included because it does not trigger a page transition.
}
