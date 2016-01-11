// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/services.dart';

import 'events.dart';

/// A callback that receives a [PointerEvent]
typedef void PointerRoute(PointerEvent event);

typedef void PointerExceptionHandler(PointerRouter source, PointerEvent event, PointerRoute route, dynamic exception, StackTrace stack);

/// A routing table for [PointerEvent] events.
class PointerRouter {
  final Map<int, LinkedHashSet<PointerRoute>> _routeMap = new Map<int, LinkedHashSet<PointerRoute>>();

  /// Adds a route to the routing table.
  ///
  /// Whenever this object routes a [PointerEvent] corresponding to
  /// pointer, call route.
  void addRoute(int pointer, PointerRoute route) {
    LinkedHashSet<PointerRoute> routes = _routeMap.putIfAbsent(pointer, () => new LinkedHashSet<PointerRoute>());
    assert(!routes.contains(route));
    routes.add(route);
  }

  /// Removes a route from the routing table.
  ///
  /// No longer call route when routing a [PointerEvent] corresponding to
  /// pointer. Requires that this route was previously added to the router.
  void removeRoute(int pointer, PointerRoute route) {
    assert(_routeMap.containsKey(pointer));
    LinkedHashSet<PointerRoute> routes = _routeMap[pointer];
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
  /// argument contains the stack trace. If no handler is registered, then the
  /// human-readable parts of this information (the exception, event, and stack
  /// trace) will be printed to the console instead.
  PointerExceptionHandler debugPointerExceptionHandler;

  /// Calls the routes registered for this pointer event.
  ///
  /// Routes are called in the order in which they were added to the
  /// PointerRouter object.
  void route(PointerEvent event) {
    LinkedHashSet<PointerRoute> routes = _routeMap[event.pointer];
    if (routes == null)
      return;
    for (PointerRoute route in new List<PointerRoute>.from(routes)) {
      if (!routes.contains(route))
        continue;
      try {
        route(event);
      } catch (exception, stack) {
        if (debugPointerExceptionHandler != null) {
          debugPointerExceptionHandler(this, event, route, exception, stack);
        } else {
          debugPrint('-- EXCEPTION CAUGHT BY GESTURE LIBRARY ---------------------------------');
          debugPrint('The following exception was raised while routing a pointer event:');
          debugPrint('$exception');
          debugPrint('Event:');
          debugPrint('$event');
          debugPrint('Stack trace:');
          debugPrint('$stack');
          debugPrint('------------------------------------------------------------------------');
        }
      }
    }
  }
}
