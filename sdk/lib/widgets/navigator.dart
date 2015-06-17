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

class NavigationState {

  NavigationState(List<Route> routes) {
    for (Route route in routes) {
      if (route.name != null)
        namedRoutes[route.name] = route;
    }
    history.add(routes[0]);
  }

  List<RouteBase> history = new List<RouteBase>();
  int historyIndex = 0;
  Map<String, RouteBase> namedRoutes = new Map<String, RouteBase>();

  RouteBase get currentRoute => history[historyIndex];
  bool hasPrevious() => historyIndex > 0;
  bool hasNext() => history.length > historyIndex + 1;

  void pushNamed(String name) {
    Route route = namedRoutes[name];
    assert(route != null);
    push(route);
  }

  void push(RouteBase route) {
    // Discard future history
    history.removeRange(historyIndex + 1, history.length);
    historyIndex = history.length;
    history.add(route);
  }

  void pop() {
    if (historyIndex > 0) {
      history.removeLast();
      historyIndex--;
    }
  }

  void back() {
    if (historyIndex > 0)
      historyIndex--;
  }

  void forward() {
    historyIndex++;
    assert(historyIndex < history.length);
  }
}

class Navigator extends Component {

  Navigator(this.state, { String key }) : super(key: key);

  NavigationState state;

  void pushNamed(String name) {
    setState(() {
      state.pushNamed(name);
    });
  }

  void push(RouteBase route) {
    setState(() {
      state.push(route);
    });
  }

  void pop() {
    setState(() {
      state.pop();
    });
  }

  void back() {
    setState(() {
      state.back();
    });
  }

  void forward() {
    setState(() {
      state.forward();
    });
  }

  Widget build() {
    return state.currentRoute.build(this);
  }
}
