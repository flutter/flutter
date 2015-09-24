// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/focus.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:sky/src/fn3/transitions.dart';

typedef Widget RouteBuilder(NavigatorState navigator, RouteBase route);

typedef void NotificationCallback();

abstract class RouteBase {
  AnimationPerformance _performance;
  NotificationCallback onDismissed;
  NotificationCallback onCompleted;
  AnimationPerformance createPerformance() {
    AnimationPerformance result = new AnimationPerformance(duration: transitionDuration);
    result.addStatusListener((AnimationStatus status) {
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
    return result;
  }
  WatchableAnimationPerformance ensurePerformance({ Direction direction }) {
    assert(direction != null);
    if (_performance == null)
      _performance = createPerformance();
    AnimationStatus desiredStatus = direction == Direction.forward ? AnimationStatus.forward : AnimationStatus.reverse;
    if (_performance.status != desiredStatus)
      _performance.play(direction);
    return _performance.view;
  }
  bool get isActuallyOpaque => _performance != null && _performance.isCompleted && isOpaque;

  bool get hasContent => true; // set to false if you have nothing useful to return from build()

  Duration get transitionDuration;
  bool get isOpaque;
  Widget build(Key key, NavigatorState navigator, WatchableAnimationPerformance performance);
  void popState([dynamic result]) { assert(result == null); }

  String toString() => '$runtimeType()';
}

const Duration _kTransitionDuration = const Duration(milliseconds: 150);
const Point _kTransitionStartPoint = const Point(0.0, 75.0);
class Route extends RouteBase {
  Route({ this.name, this.builder });

  final String name;
  final RouteBuilder builder;

  bool get isOpaque => true;

  Duration get transitionDuration => _kTransitionDuration;

  Widget build(Key key, NavigatorState navigator, WatchableAnimationPerformance performance) {
    // TODO(jackson): Hit testing should ignore transform
    // TODO(jackson): Block input unless content is interactive
    return new SlideTransition(
      key: key,
      performance: performance,
      position: new AnimatedValue<Point>(_kTransitionStartPoint, end: Point.origin, curve: easeOut),
      child: new FadeTransition(
        performance: performance,
        opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: easeOut),
        child: builder(navigator, this)
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

  bool get isOpaque => false;

  void popState([dynamic result]) {
    assert(result == null);
    if (callback != null)
      callback(this);
  }

  bool get hasContent => false;
  Duration get transitionDuration => const Duration();
  Widget build(Key key, NavigatorState navigator, WatchableAnimationPerformance performance) => null;
}

class NavigatorHistory {

  NavigatorHistory(List<Route> routes) {
    for (Route route in routes) {
      if (route.name != null)
        namedRoutes[route.name] = route;
    }
    recents.add(routes[0]);
  }

  List<RouteBase> recents = new List<RouteBase>();
  int index = 0;
  Map<String, RouteBase> namedRoutes = new Map<String, RouteBase>();

  RouteBase get currentRoute => recents[index];
  bool hasPrevious() => index > 0;

  void pushNamed(String name) {
    Route route = namedRoutes[name];
    assert(route != null);
    push(route);
  }

  void push(RouteBase route) {
    assert(!_debugCurrentlyHaveRoute(route));
    recents.insert(index + 1, route);
    index++;
  }

  void pop([dynamic result]) {
    if (index > 0) {
      RouteBase route = recents[index];
      route.popState(result);
      index--;
    }
  }

  bool _debugCurrentlyHaveRoute(RouteBase route) {
    return recents.any((candidate) => candidate == route);
  }
}

class Navigator extends StatefulComponent {
  Navigator(this.history, { Key key }) : super(key: key);

  final NavigatorHistory history;

  NavigatorState createState() => new NavigatorState(this);
}

class NavigatorState extends ComponentState<Navigator> {
  NavigatorState(Navigator config) : super(config);

  RouteBase get currentRoute => config.history.currentRoute;

  void pushState(StatefulComponent owner, Function callback) {
    RouteBase route = new RouteState(
      owner: owner,
      callback: callback,
      route: currentRoute
    );
    push(route);
  }

  void pushNamed(String name) {
    setState(() {
      config.history.pushNamed(name);
    });
  }

  void push(RouteBase route) {
    setState(() {
      config.history.push(route);
    });
  }

  void pop([dynamic result]) {
    setState(() {
      config.history.pop(result);
    });
  }

  Widget build(BuildContext context) {
    List<Widget> visibleRoutes = new List<Widget>();
    for (int i = config.history.recents.length-1; i >= 0; i -= 1) {
      RouteBase route = config.history.recents[i];
      if (!route.hasContent)
        continue;
      WatchableAnimationPerformance performance = route.ensurePerformance(
        direction: (i <= config.history.index) ? Direction.forward : Direction.reverse
      );
      route.onDismissed = () {
        setState(() {
          assert(config.history.recents.contains(route));
          config.history.recents.remove(route);
        });
      };
      Key key = new ObjectKey(route);
      Widget widget = route.build(key, this, performance);
      visibleRoutes.add(widget);
      if (route.isActuallyOpaque)
        break;
    }
    if (visibleRoutes.length > 1) {
      visibleRoutes.insert(1, new Listener(
        onPointerDown: (_) { pop(); },
        child: new Container()
      ));
    }
    return new Focus(child: new Stack(visibleRoutes.reversed.toList()));
  }
}
