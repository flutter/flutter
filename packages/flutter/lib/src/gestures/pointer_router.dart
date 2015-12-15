// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

import 'events.dart';

/// A callback that receives a [PointerEvent]
typedef void PointerRoute(PointerEvent event);

typedef void PointerExceptionHandler(PointerRouter source, PointerEvent event, PointerRoute route, dynamic exception, StackTrace stack);

/// A routing table for [PointerEvent] events.
class PointerRouter {
  final Map<int, List<PointerRoute>> _routeMap = new Map<int, List<PointerRoute>>();

  /// Adds a route to the routing table.
  ///
  /// Whenever this object routes a [PointerEvent] corresponding to
  /// pointer, call route.
  void addRoute(int pointer, PointerRoute route) {
    List<PointerRoute> routes = _routeMap.putIfAbsent(pointer, () => new List<PointerRoute>());
    assert(!routes.contains(route));
    routes.add(route);
  }

  /// Removes a route from the routing table.
  ///
  /// No longer call route when routing a [PointerEvent] corresponding to
  /// pointer. Requires that this route was previously added to the router.
  void removeRoute(int pointer, PointerRoute route) {
    assert(_routeMap.containsKey(pointer));
    List<PointerRoute> routes = _routeMap[pointer];
    assert(routes.contains(route));
    routes.remove(route);
    if (routes.isEmpty)
      _routeMap.remove(pointer);
  }

  /// This callback is invoked whenever an exception is caught by the pointer
  /// router. The 'source' argument is the [PointerRouter] object that caught
  /// the exception. The 'event' argument is the pointer event that was being
  /// routed. The 'route' argument is the callback that threw the exception. The
  /// 'exception' argument contains the object that was thrown, and the 'stack'
  /// argument contains the stack trace. The callback is invoked after the
  /// information (exception, stack trace, and event; not the route callback
  /// itself) is printed to the console.
  PointerExceptionHandler debugPointerExceptionHandler;

  /// Calls the routes registered for this pointer event.
  ///
  /// Routes are called in the order in which they were added to the
  /// PointerRouter object.
  void route(PointerEvent event) {
    List<PointerRoute> routes = _routeMap[event.pointer];
    if (routes == null)
      return;
    for (PointerRoute route in new List<PointerRoute>.from(routes)) {
      try {
        route(event);
      } catch (exception, stack) {
        debugPrint('-- EXCEPTION --');
        debugPrint('The following exception was raised while routing a pointer event:');
        debugPrint('$exception');
        debugPrint('Stack trace:');
        debugPrint('$stack');
        debugPrint('Event:');
        debugPrint('$event');
        if (debugPointerExceptionHandler != null)
          debugPointerExceptionHandler(this, event, route, exception, stack);
      }
    }
  }
}
