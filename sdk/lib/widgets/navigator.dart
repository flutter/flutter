// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';

typedef Widget Builder(Navigator navigator, RouteBase route);

abstract class RouteBase {
  RouteBase({ this.name });
  final String name;
  Widget build(Navigator navigator, RouteBase route);
  void popState() { }
}

class Route extends RouteBase {
  Route({ String name, this.builder }) : super(name: name);
  final Builder builder;
  Widget build(Navigator navigator, RouteBase route) => builder(navigator, route);
}

class RouteState extends RouteBase {

  RouteState({this.callback, this.route, String name}) : super(name: name);

  RouteBase route;
  Function callback;

  Widget build(Navigator navigator, _) => route.build(navigator, this);

  void popState() {
    if (callback != null)
      callback(this);
  }
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
      history[historyIndex].popState();
      history.removeLast();
      historyIndex--;
    }
  }
}

class Navigator extends StatefulComponent {

  Navigator(this.state, { String key }) : super(key: key);

  NavigationState state;

  void syncFields(Navigator source) {
    state = source.state;
  }

  RouteBase get currentRoute => state.currentRoute;

  void pushState(String name, Function callback) {
    RouteBase route = new RouteState(
      name: name,
      callback: callback,
      route: state.currentRoute
    );
    push(route);
  }

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

  Widget build() {
    return state.currentRoute.build(this, state.currentRoute);
  }
}
