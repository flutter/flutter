// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'events.dart';

/// A callback that receives a [PointerEvent]
typedef PointerRoute = void Function(PointerEvent event);

/// A routing table for [PointerEvent] events.
class PointerRouter {
  final Map<int, LinkedHashSet<PointerRoute>> _routeMap = <int, LinkedHashSet<PointerRoute>>{};
  final LinkedHashSet<PointerRoute> _globalRoutes = LinkedHashSet<PointerRoute>();

  /// Adds a route to the routing table.
  ///
  /// Whenever this object routes a [PointerEvent] corresponding to
  /// pointer, call route.
  ///
  /// Routes added reentrantly within [PointerRouter.route] will take effect when
  /// routing the next event.
  void addRoute(int pointer, PointerRoute route) {
    final LinkedHashSet<PointerRoute> routes = _routeMap.putIfAbsent(pointer, () => LinkedHashSet<PointerRoute>());
    assert(!routes.contains(route));
    routes.add(route);
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
    final LinkedHashSet<PointerRoute> routes = _routeMap[pointer];
    assert(routes.contains(route));
    routes.remove(route);
    if (routes.isEmpty)
      _routeMap.remove(pointer);
  }

  /// Adds a route to the global entry in the routing table.
  ///
  /// Whenever this object routes a [PointerEvent], call route.
  ///
  /// Routes added reentrantly within [PointerRouter.route] will take effect when
  /// routing the next event.
  void addGlobalRoute(PointerRoute route) {
    assert(!_globalRoutes.contains(route));
    _globalRoutes.add(route);
  }

  /// Removes a route from the global entry in the routing table.
  ///
  /// No longer call route when routing a [PointerEvent]. Requires that this
  /// route was previously added via [addGlobalRoute].
  ///
  /// Routes removed reentrantly within [PointerRouter.route] will take effect
  /// immediately.
  void removeGlobalRoute(PointerRoute route) {
    assert(_globalRoutes.contains(route));
    _globalRoutes.remove(route);
  }

  void _dispatch(PointerEvent event, PointerRoute route) {
    try {
      route(event);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetailsForPointerRouter(
        exception: exception,
        stack: stack,
        library: 'gesture library',
        context: 'while routing a pointer event',
        router: this,
        route: route,
        event: event,
        informationCollector: (StringBuffer information) {
          information.writeln('Event:');
          information.write('  $event');
        }
      ));
    }
  }

  /// Calls the routes registered for this pointer event.
  ///
  /// Routes are called in the order in which they were added to the
  /// PointerRouter object.
  void route(PointerEvent event) {
    final LinkedHashSet<PointerRoute> routes = _routeMap[event.pointer];
    final List<PointerRoute> globalRoutes = List<PointerRoute>.from(_globalRoutes);
    if (routes != null) {
      for (PointerRoute route in List<PointerRoute>.from(routes)) {
        if (routes.contains(route))
          _dispatch(event, route);
      }
    }
    for (PointerRoute route in globalRoutes) {
      if (_globalRoutes.contains(route))
        _dispatch(event, route);
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
    String context,
    this.router,
    this.route,
    this.event,
    InformationCollector informationCollector,
    bool silent = false
  }) : super(
    exception: exception,
    stack: stack,
    library: library,
    context: context,
    informationCollector: informationCollector,
    silent: silent
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
