// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/focus.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/transitions.dart';

typedef Widget RouteBuilder(Navigator navigator, RouteBase route);

typedef void NotificationCallback();

abstract class RouteBase {
  Widget build(Navigator navigator, RouteBase route);
  bool get isOpaque;
  void popState([dynamic result]) { assert(result == null); }

  AnimationPerformance _performance;
  NotificationCallback onDismissed;
  NotificationCallback onCompleted;
  WatchableAnimationPerformance ensurePerformance({ Direction direction }) {
    assert(direction != null);
    if (_performance == null) {
      _performance = new AnimationPerformance(duration: transitionDuration);
      _performance.addStatusListener((AnimationStatus status) {
        switch (status) {
          case AnimationStatus.dismissed:
            if (onDismissed != null)
              onDismissed();
            break;
          case AnimationStatus.completed:
            if (onCompleted != null)
              onCompleted();
            break;
          default:
            ;
        }
      });
    }
    AnimationStatus desiredStatus = direction == Direction.forward ? AnimationStatus.forward : AnimationStatus.reverse;
    if (_performance.status != desiredStatus)
      _performance.play(direction);
    return _performance.view;
  }

  Duration get transitionDuration;
  TransitionBase buildTransition({ Key key, Widget child, WatchableAnimationPerformance performance });

  String toString() => '$runtimeType()';
}

const Duration _kTransitionDuration = const Duration(milliseconds: 150);
const Point _kTransitionStartPoint = const Point(0.0, 75.0);
class Route extends RouteBase {
  Route({ this.name, this.builder });

  final String name;
  final RouteBuilder builder;

  Widget build(Navigator navigator, RouteBase route) => builder(navigator, route);
  bool get isOpaque => true;

  Duration get transitionDuration => _kTransitionDuration;
  TransitionBase buildTransition({ Key key, Widget child, WatchableAnimationPerformance performance }) {
    // TODO(jackson): Hit testing should ignore transform
    // TODO(jackson): Block input unless content is interactive
    return new SlideTransition(
      key: key,
      performance: performance,
      position: new AnimatedValue<Point>(_kTransitionStartPoint, end: Point.origin, curve: easeOut),
      child: new FadeTransition(
        performance: performance,
        opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: easeOut),
        child: child
      )
    );
  }

  String toString() => '$runtimeType(name="$name")';
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

  // Custom state routes shouldn't be asked to construct a transition
  Duration get transitionDuration {
    assert(false);
    return const Duration();
  }
  TransitionBase buildTransition({ Key key, Widget child, WatchableAnimationPerformance performance }) {
    assert(false);
    return null;
  }
}

class HistoryEntry {
  HistoryEntry({ this.route });
  final RouteBase route;
  bool fullyOpaque = false;
  // TODO(jackson): Keep track of the requested transition
  String toString() => "HistoryEntry($route, hashCode=$hashCode)";
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
    assert(!_debugCurrentlyHaveRoute(route));
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

  bool _debugCurrentlyHaveRoute(RouteBase route) {
    return history.any((entry) => entry.route == route);
  }
}

class Navigator extends StatefulComponent {

  Navigator(this.state, { Key key }) : super(key: key);

  NavigationState state;

  void syncConstructorArguments(Navigator source) {
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
      WatchableAnimationPerformance performance = historyEntry.route.ensurePerformance(
        direction: (i <= state.historyIndex) ? Direction.forward : Direction.reverse
      );
      historyEntry.route.onDismissed = () {
        setState(() {
          assert(state.history.contains(historyEntry));
          state.history.remove(historyEntry);
        });
      };
      historyEntry.route.onCompleted = () {
        setState(() {
          historyEntry.fullyOpaque = historyEntry.route.isOpaque;
        });
      };
      TransitionBase transition = historyEntry.route.buildTransition(
        key: new ObjectKey(historyEntry),
        child: child,
        performance: performance
      );
      visibleRoutes.add(transition);
    }
    return new Focus(child: new Stack(visibleRoutes));
  }
}
