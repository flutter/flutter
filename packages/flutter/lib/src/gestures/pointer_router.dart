// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'events.dart';

/// A callback that receives a [PointerEvent]
typedef PointerRoute = void Function(PointerEvent event);

/// A routing table for [PointerEvent] events.
class PointerRouter {
  final Map<int, LinkedHashSet<_RouteEntry>> _routeMap = <int, LinkedHashSet<_RouteEntry>>{};
  final LinkedHashSet<_RouteEntry> _globalRoutes = LinkedHashSet<_RouteEntry>();

  /// Adds a route to the routing table.
  ///
  /// Whenever this object routes a [PointerEvent] corresponding to
  /// pointer, call route.
  ///
  /// Routes added reentrantly within [PointerRouter.route] will take effect when
  /// routing the next event.
  void addRoute(int pointer, PointerRoute route, [Matrix4 transform]) {
    final LinkedHashSet<_RouteEntry> routes = _routeMap.putIfAbsent(pointer, () => LinkedHashSet<_RouteEntry>());
    assert(!routes.any(_RouteEntry.isRoutePredicate(route)));
    routes.add(_RouteEntry(route: route, transform: transform));
  }

  /// Removes a route from the routing table.
  ///
  /// No longer call route when routing a [PointerEvent] corresponding to
  /// pointer. Requires that this route was previously added to the router.
  ///
  /// Routes removed reentrantly within [PointerRouter.route] will take effect
  /// immediately.
  void removeRoute(int pointer, PointerRoute route) {
    assert(_routeMap.containsKey(pointer));
    final LinkedHashSet<_RouteEntry> routes = _routeMap[pointer];
    assert(routes.any(_RouteEntry.isRoutePredicate(route)));
    routes.removeWhere(_RouteEntry.isRoutePredicate(route));
    if (routes.isEmpty)
      _routeMap.remove(pointer);
  }

  /// Adds a route to the global entry in the routing table.
  ///
  /// Whenever this object routes a [PointerEvent], call route.
  ///
  /// Routes added reentrantly within [PointerRouter.route] will take effect when
  /// routing the next event.
  void addGlobalRoute(PointerRoute route, [Matrix4 transform]) {
    assert(!_globalRoutes.any(_RouteEntry.isRoutePredicate(route)));
    _globalRoutes.add(_RouteEntry(route: route, transform: transform));
  }

  /// Removes a route from the global entry in the routing table.
  ///
  /// No longer call route when routing a [PointerEvent]. Requires that this
  /// route was previously added via [addGlobalRoute].
  ///
  /// Routes removed reentrantly within [PointerRouter.route] will take effect
  /// immediately.
  void removeGlobalRoute(PointerRoute route) {
    assert(_globalRoutes.any(_RouteEntry.isRoutePredicate(route)));
    _globalRoutes.removeWhere(_RouteEntry.isRoutePredicate(route));
  }

  void _dispatch(PointerEvent event, _RouteEntry entry) {
    try {
      event = event.transformed(entry.transform);
      entry.route(event);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetailsForPointerRouter(
        exception: exception,
        stack: stack,
        library: 'gesture library',
        context: ErrorDescription('while routing a pointer event'),
        router: this,
        route: entry.route,
        event: event,
        informationCollector: () sync* {
          yield DiagnosticsProperty<PointerEvent>('Event', event, style: DiagnosticsTreeStyle.errorProperty);
        },
      ));
    }
  }

  /// Calls the routes registered for this pointer event.
  ///
  /// Routes are called in the order in which they were added to the
  /// PointerRouter object.
  void route(PointerEvent event) {
    final LinkedHashSet<_RouteEntry> routes = _routeMap[event.pointer];
    final List<_RouteEntry> globalRoutes = List<_RouteEntry>.from(_globalRoutes);
    if (routes != null) {
      for (_RouteEntry entry in List<_RouteEntry>.from(routes)) {
        if (routes.any(_RouteEntry.isRoutePredicate(entry.route)))
          _dispatch(event, entry);
      }
    }
    for (_RouteEntry entry in globalRoutes) {
      if (_globalRoutes.any(_RouteEntry.isRoutePredicate(entry.route)))
        _dispatch(event, entry);
    }
  }
}

/// Variant of [FlutterErrorDetails] with extra fields for the gestures
/// library's pointer router ([PointerRouter]).
///
/// See also [FlutterErrorDetailsForPointerEventDispatcher], which is also used
/// by the gestures library.
class FlutterErrorDetailsForPointerRouter extends FlutterErrorDetails {
  /// Creates a [FlutterErrorDetailsForPointerRouter] object with the given
  /// arguments setting the object's properties.
  ///
  /// The gestures library calls this constructor when catching an exception
  /// that will subsequently be reported using [FlutterError.onError].
  const FlutterErrorDetailsForPointerRouter({
    dynamic exception,
    StackTrace stack,
    String library,
    DiagnosticsNode context,
    this.router,
    this.route,
    this.event,
    InformationCollector informationCollector,
    bool silent = false,
  }) : super(
    exception: exception,
    stack: stack,
    library: library,
    context: context,
    informationCollector: informationCollector,
    silent: silent,
  );

  /// The pointer router that caught the exception.
  ///
  /// In a typical application, this is the value of [GestureBinding.pointerRouter] on
  /// the binding ([GestureBinding.instance]).
  final PointerRouter router;

  /// The callback that threw the exception.
  final PointerRoute route;

  /// The pointer event that was being routed when the exception was raised.
  final PointerEvent event;
}

typedef _RouteEntryPredicate = bool Function(_RouteEntry entry);

class _RouteEntry {
  const _RouteEntry({
    @required this.route,
    @required this.transform,
  });

  final PointerRoute route;
  final Matrix4 transform;

  static _RouteEntryPredicate isRoutePredicate(PointerRoute route) {
    return (_RouteEntry entry) => entry.route == route;
  }
}
