// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';

typedef Widget Builder(Navigator navigator);

abstract class RouteBase {
  RouteBase({ this.name });
  final String name;
  Widget build(Navigator navigator);
}

class Route extends RouteBase {
  Route({ String name, this.builder }) : super(name: name);
  final Builder builder;
  Widget build(Navigator navigator) => builder(navigator);
}

class Navigator extends Component {
  Navigator({ Object key, RouteBase defaultRoute, List<RouteBase> routes })
    : super(key: key, stateful: true) {
    if (routes != null) {
      if (defaultRoute == null)
        defaultRoute = routes[0];
      for (Route route in routes) {
        if (route.name != null)
          namedRoutes[route.name] = route;
      }
    }
    assert(defaultRoute != null);
    _history.add(defaultRoute);
  }

  List<RouteBase> _history = new List<RouteBase>();
  int _historyIndex = 0;
  Map<String, RouteBase> namedRoutes = new Map<String, RouteBase>();

  void syncFields(Navigator source) {
    namedRoutes = source.namedRoutes;
  }

  void pushNamed(String name) {
    Route route = namedRoutes[name];
    assert(route != null);
    push(route);
  }

  void push(RouteBase route) {
    setState(() {
      // Discard future history
      _history.removeRange(_historyIndex + 1, _history.length);
      _historyIndex = _history.length;
      _history.add(route);
    });
  }

  void pop() {
    setState(() {
      if (_historyIndex > 0) {
        _history.removeLast();
        _historyIndex--;
      }
    });
  }

  void back() {
    setState(() {
      if (_historyIndex > 0)
        _historyIndex--;
    });
  }

  void forward() {
    setState(() {
      _historyIndex++;
      assert(_historyIndex < _history.length);
    });
  }

  Widget build() {
    return _history[_historyIndex].build(this);
  }
}
