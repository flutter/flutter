// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';

typedef UINode Builder(Navigator navigator);

abstract class RouteBase {
  RouteBase({this.name});
  final String name;
  UINode build(Navigator navigator);
}

class Route extends RouteBase {
  Route({String name, this.builder}) : super(name: name);
  final Builder builder;
  UINode build(Navigator navigator) => builder(navigator);
}

class Navigator extends Component {
  Navigator({Object key, this.currentRoute, this.routes})
    : super(key: key, stateful: true);

  RouteBase currentRoute;
  List<RouteBase> routes;
 
  void syncFields(Navigator source) {
    currentRoute = source.currentRoute;
    routes = source.routes;
  }

  void pushNamedRoute(String name) {
    assert(routes != null);
    for (RouteBase route in routes) {
      if (route.name == name) {
        setState(() {
          currentRoute = route;
        });
        return;
      }
    }
    assert(false);  // route not found
  }

  void pushRoute(RouteBase route) {
    setState(() {
      currentRoute = route;
    });
  }

  UINode build() {
    Route route = currentRoute == null ? routes[0] : currentRoute;
    assert(route != null);
    return route.build(this);
  }
}