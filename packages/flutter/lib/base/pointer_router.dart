// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

typedef void _Route(sky.PointerEvent event);

class PointerRouter {
  final Map<int, List<_Route>> _routeMap = new Map<int, List<_Route>>();

  void addRoute(int pointer, _Route route) {
    List<_Route> routes = _routeMap.putIfAbsent(pointer, () => new List<_Route>());
    assert(!routes.contains(route));
    routes.add(route);
  }

  void removeRoute(int pointer, _Route route) {
    assert(_routeMap.containsKey(pointer));
    List<_Route> routes = _routeMap[pointer];
    assert(routes.contains(route));
    routes.remove(route);
    if (routes.isEmpty)
      _routeMap.remove(pointer);
  }

  void route(sky.PointerEvent event) {
    List<_Route> routes = _routeMap[event.pointer];
    if (routes == null)
      return;
    for (_Route route in new List<_Route>.from(routes))
      route(event);
  }
}
