// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'events.dart';

/// A callback that receives a [PointerEvent]
typedef void PointerRoute(PointerEvent event);

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

  /// Call the routes registed for this pointer event.
  ///
  /// Calls the routes in the order in which they were added to the route.
  void route(PointerEvent event) {
    List<PointerRoute> routes = _routeMap[event.pointer];
    if (routes == null)
      return;
    for (PointerRoute route in new List<PointerRoute>.from(routes))
      route(event);
  }
}
