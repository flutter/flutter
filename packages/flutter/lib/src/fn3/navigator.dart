// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/focus.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:sky/src/fn3/transitions.dart';

typedef Widget RouteBuilder(NavigatorState navigator, Route route);

typedef void NotificationCallback();

abstract class Route {
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

class PageRoute extends Route {
  PageRoute(this.builder);

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
}

typedef void RouteStateCallback(RouteState route);

class RouteState extends Route {
  RouteState({ this.route, this.owner, this.callback });

  Route route;
  State owner;
  RouteStateCallback callback;

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

class Navigator extends StatefulComponent {
  Navigator({ this.routes, Key key }) : super(key: key) {
    // To use a navigator, you must at a minimum define the route with the name '/'.
    assert(routes.containsKey('/'));
  }

  final Map<String, RouteBuilder> routes;

  NavigatorState createState() => new NavigatorState();
}

class NavigatorState extends State<Navigator> {

  List<Route> _history = new List<Route>();
  int _currentPosition = 0;

  Route get currentRoute => _history[_currentPosition];
  bool get hasPreviousRoute => _history.length > 1;

  void initState(BuildContext context) {
    super.initState(context);
    PageRoute route = new PageRoute(config.routes['/']);
    assert(route != null);
    _history.add(route);
  }

  void pushState(State owner, Function callback) {
    push(new RouteState(
      route: currentRoute,
      owner: owner,
      callback: callback
    ));
  }

  void pushNamed(String name) {
    PageRoute route = new PageRoute(config.routes[name]);
    assert(route != null);
    push(route);
  }

  void push(Route route) {
    assert(!_debugCurrentlyHaveRoute(route));
    _history.insert(_currentPosition + 1, route);
    setState(() {
      _currentPosition += 1;
    });
  }

  void pop([dynamic result]) {
    if (_currentPosition > 0) {
      Route route = _history[_currentPosition];
      route.popState(result);
      setState(() {
        _currentPosition -= 1;
      });
    }
  }

  bool _debugCurrentlyHaveRoute(Route route) {
    return _history.any((candidate) => candidate == route);
  }

  Widget build(BuildContext context) {
    List<Widget> visibleRoutes = new List<Widget>();
    for (int i = _history.length-1; i >= 0; i -= 1) {
      Route route = _history[i];
      if (!route.hasContent)
        continue;
      WatchableAnimationPerformance performance = route.ensurePerformance(
        direction: (i <= _currentPosition) ? Direction.forward : Direction.reverse
      );
      route.onDismissed = () {
        setState(() {
          assert(_history.contains(route));
          _history.remove(route);
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
