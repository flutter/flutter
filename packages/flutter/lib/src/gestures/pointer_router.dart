// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'events.dart';

/// A callback that receives a [PointerEvent]
typedef PointerRoute = void Function(PointerEvent event);

/// A routing table for [PointerEvent] events.
class PointerRouter {
  final Map<int, Map<PointerRoute, Matrix4>> _routeMap = <int, Map<PointerRoute, Matrix4>>{};
  final Map<PointerRoute, Matrix4> _globalRoutes = <PointerRoute, Matrix4>{};

  /// Adds a route to the routing table.
  ///
  /// Whenever this object routes a [PointerEvent] corresponding to
  /// pointer, call route.
  ///
  /// Routes added reentrantly within [PointerRouter.route] will take effect when
  /// routing the next event.
  void addRoute(int pointer, PointerRoute route, [Matrix4 transform]) {
    final Map<PointerRoute, Matrix4> routes = _routeMap.putIfAbsent(
      pointer,
      () => <PointerRoute, Matrix4>{},
    );
    assert(!routes.containsKey(route));
    routes[route] = transform;
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
    final Map<PointerRoute, Matrix4> routes = _routeMap[pointer];
    assert(routes.containsKey(route));
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
  void addGlobalRoute(PointerRoute route, [Matrix4 transform]) {
    assert(!_globalRoutes.containsKey(route));
    _globalRoutes[route] = transform;
  }

  /// Removes a route from the global entry in the routing table.
  ///
  /// No longer call route when routing a [PointerEvent]. Requires that this
  /// route was previously added via [addGlobalRoute].
  ///
  /// Routes removed reentrantly within [PointerRouter.route] will take effect
  /// immediately.
  void removeGlobalRoute(PointerRoute route) {
    assert(_globalRoutes.containsKey(route));
    _globalRoutes.remove(route);
  }

  void _dispatch(PointerEvent event, PointerRoute route, Matrix4 transform) {
    try {
      event = event.transformed(transform);
      route(event);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetailsForPointerRouter(
        exception: exception,
        stack: stack,
        library: 'gesture library',
        context: ErrorDescription('while routing a pointer event'),
        router: this,
        route: route,
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
    final Map<PointerRoute, Matrix4> routes = _routeMap[event.pointer];
    final Map<PointerRoute, Matrix4> copiedGlobalRoutes = Map<PointerRoute, Matrix4>.from(_globalRoutes);
    if (routes != null) {
      _dispatchEventToRoutes(
        event,
        routes,
        Map<PointerRoute, Matrix4>.from(routes),
      );
    }
    _dispatchEventToRoutes(event, _globalRoutes, copiedGlobalRoutes);
  }

  void _dispatchEventToRoutes(
    PointerEvent event,
    Map<PointerRoute, Matrix4> referenceRoutes,
    Map<PointerRoute, Matrix4> copiedRoutes,
  ) {
    copiedRoutes.forEach((PointerRoute route, Matrix4 transform) {
      if (referenceRoutes.containsKey(route)) {
        _dispatch(event, route, transform);
      }
    });
  }
}

/// Variant of [FlutterErrorDetails] with extra fields for the gestures
/// library's pointer router ([PointerRouter]).
///
/// See also:
///
///  * [FlutterErrorDetailsForPointerEventDispatcher], which is also used
///    by the gestures library.
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
