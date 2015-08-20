// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/focus.dart';
import 'package:sky/widgets/transitions.dart';

typedef Widget RouteBuilder(Navigator navigator, RouteBase route);

abstract class RouteBase {
  Widget build(Navigator navigator, RouteBase route);
  bool get isOpaque;
  void popState([dynamic result]) { assert(result == null); }
  TransitionBase buildTransition({ Key key });
}

class Route extends RouteBase {
  Route({ this.name, this.builder });

  final String name;
  final RouteBuilder builder;

  Widget build(Navigator navigator, RouteBase route) => builder(navigator, route);
  bool get isOpaque => true;
  TransitionBase buildTransition({ Key key }) => new SlideUpFadeTransition(key: key);
}

class RouteState extends RouteBase {
  RouteState({ this.callback, this.route, this.owner });

  Function callback;
  RouteBase route;
  StatefulComponent owner;

  Widget build(Navigator navigator, RouteBase route) => null;
  bool get isOpaque => false;

  void popState([dynamic result]) {
    assert(result == null);
    if (callback != null)
      callback(this);
  }

  TransitionBase buildTransition({ Key key }) {
    // Custom state routes shouldn't be asked to construct a transition
    assert(false);
    return null;
  }
}

// TODO(jackson): Refactor this into its own file
const Duration _kTransitionDuration = const Duration(milliseconds: 150);
const Point _kTransitionStartPoint = const Point(0.0, 75.0);
class SlideUpFadeTransition extends TransitionBase {
  SlideUpFadeTransition({
    Key key,
    Widget child,
    Direction direction,
    Function onDismissed,
    Function onCompleted
  }): super(key: key,
            child: child,
            duration: _kTransitionDuration,
            direction: direction,
            onDismissed: onDismissed,
            onCompleted: onCompleted);

  Widget buildWithChild(Widget child) {
    // TODO(jackson): Hit testing should ignore transform
    // TODO(jackson): Block input unless content is interactive
    return new SlideTransition(
      performance: performance,
      direction: direction,
      position: new AnimatedValue<Point>(_kTransitionStartPoint, end: Point.origin, curve: easeOut),
      child: new FadeTransition(
        performance: performance,
        direction: direction,
        opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: easeOut),
        child: child
      )
    );
  }
}

class HistoryEntry {
  HistoryEntry({ this.route });
  final RouteBase route;
  bool fullyOpaque = false;
  // TODO(jackson): Keep track of the requested transition
}

class NavigationState {

  NavigationState(List<Route> routes) {
    for (Route route in routes) {
      if (route.name != null)
        namedRoutes[route.name] = route;
    }
    history.add(new HistoryEntry(route: routes[0]));
  }

  List<HistoryEntry> history = new List<HistoryEntry>();
  int historyIndex = 0;
  Map<String, RouteBase> namedRoutes = new Map<String, RouteBase>();

  RouteBase get currentRoute => history[historyIndex].route;
  bool hasPrevious() => historyIndex > 0;

  void pushNamed(String name) {
    Route route = namedRoutes[name];
    assert(route != null);
    push(route);
  }

  void push(RouteBase route) {
    HistoryEntry historyEntry = new HistoryEntry(route: route);
    history.insert(historyIndex + 1, historyEntry);
    historyIndex++;
  }

  void pop([dynamic result]) {
    if (historyIndex > 0) {
      HistoryEntry entry = history[historyIndex];
      entry.route.popState(result);
      entry.fullyOpaque = false;
      historyIndex--;
    }
  }
}

class Navigator extends StatefulComponent {

  Navigator(this.state, { Key key }) : super(key: key);

  NavigationState state;

  void syncFields(Navigator source) {
    state = source.state;
  }

  RouteBase get currentRoute => state.currentRoute;

  void pushState(StatefulComponent owner, Function callback) {
    RouteBase route = new RouteState(
      owner: owner,
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

  void pop([dynamic result]) {
    setState(() {
      state.pop(result);
    });
  }

  Widget build() {
    List<Widget> visibleRoutes = new List<Widget>();
    for (int i = 0; i < state.history.length; i++) {
      // Avoid building routes that are not visible
      if (i + 1 < state.history.length && state.history[i + 1].fullyOpaque)
        continue;
      HistoryEntry historyEntry = state.history[i];
      Widget child = historyEntry.route.build(this, historyEntry.route);
      if (i == 0) {
        visibleRoutes.add(child);
        continue;
      }
      if (child == null)
        continue;
      TransitionBase transition = historyEntry.route.buildTransition(key: new Key.fromObjectIdentity(historyEntry))
        ..child = child
        ..direction = (i <= state.historyIndex) ? Direction.forward : Direction.reverse
        ..onDismissed = () {
          setState(() {
            state.history.remove(historyEntry);
          });
        }
        ..onCompleted = () {
          setState(() {
            historyEntry.fullyOpaque = historyEntry.route.isOpaque;
          });
        };
      visibleRoutes.add(transition);
    }
    return new Focus(child: new Stack(visibleRoutes));
  }
}
