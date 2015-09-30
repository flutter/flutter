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
    assert(!route.ephemeral);
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
    setState(() {
      while (currentRoute.ephemeral) {
        assert(currentRoute.ephemeral);
        currentRoute.didPop(null);
        _currentPosition -= 1;
      }
      _history.insert(_currentPosition + 1, route);
      _currentPosition += 1;
    });
  }

  void popRoute(Route route, [dynamic result]) {
    assert(_debugCurrentlyHaveRoute(route));
    assert(_currentPosition > 0);
    setState(() {
      while (currentRoute != route) {
        assert(currentRoute.ephemeral);
        currentRoute.didPop(null);
        _currentPosition -= 1;
      }
      assert(_currentPosition > 0);
      currentRoute.didPop(result);
      _currentPosition -= 1;
    });
    assert(!_debugCurrentlyHaveRoute(route));
  }

  void pop([dynamic result]) {
    setState(() {
      while (currentRoute.ephemeral) {
        currentRoute.didPop(null);
        _currentPosition -= 1;
      }
      assert(_currentPosition > 0);
      currentRoute.didPop(result);
      _currentPosition -= 1;
    });
  }

  bool _debugCurrentlyHaveRoute(Route route) {
    int index = _history.indexOf(route);
    return index >= 0 && index <= _currentPosition;
  }

  Widget build(BuildContext context) {
    List<Widget> visibleRoutes = new List<Widget>();
    bool alreadyInsertModalBarrier = false;
    for (int i = _history.length-1; i >= 0; i -= 1) {
      Route route = _history[i];
      if (!route.hasContent) {
        assert(!route.modal);
        continue;
      }
      route.ensurePerformance(
        direction: (i <= _currentPosition) ? Direction.forward : Direction.reverse
      );
      route._onDismissed = () {
        setState(() {
          assert(_history.contains(route));
          _history.remove(route);
        });
      };
      Key key = new ObjectKey(route);
      Widget widget = route.build(key, this);
      visibleRoutes.add(widget);
      if (route.isActuallyOpaque)
        break;
      assert(route.modal || route.ephemeral);
      if (route.modal && i > 0 && !alreadyInsertModalBarrier) {
        visibleRoutes.add(new Listener(
          onPointerDown: (_) { pop(); },
          child: new Container()
        ));
        alreadyInsertModalBarrier = true;
      }
    }
    return new Focus(child: new Stack(visibleRoutes.reversed.toList()));
  }
}


abstract class Route {

  WatchableAnimationPerformance get performance => _performance?.view;
  AnimationPerformance _performance;
  NotificationCallback _onDismissed;

  AnimationPerformance createPerformance() {
    Duration duration = transitionDuration;
    if (duration > Duration.ZERO) {
      return new AnimationPerformance(duration: duration)
        ..addStatusListener((AnimationStatus status) {
          if (status == AnimationStatus.dismissed && _onDismissed != null)
            _onDismissed();
        });
    }
    return null;
  }

  void ensurePerformance({ Direction direction }) {
    assert(direction != null);
    if (_performance == null)
      _performance = createPerformance();
    if (_performance != null) {
      AnimationStatus desiredStatus = direction == Direction.forward ? AnimationStatus.forward : AnimationStatus.reverse;
      if (_performance.status != desiredStatus)
        _performance.play(direction);
    }
  }

  /// If hasContent is true, then the route represents some on-screen state.
  ///
  /// If hasContent is false, then no performance will be created, and the values of
  /// ephemeral, modal, and opaque are ignored. This is useful if the route
  /// represents some state handled by another widget. See
  /// NavigatorState.pushState().
  /// 
  /// Set hasContent to false if you have nothing useful to return from build().
  bool get hasContent => true;

  /// If ephemeral is true, then to explicitly pop the route you have to use
  /// navigator.popRoute() with a reference to this route. navigator.pop()
  /// automatically pops all ephemeral routes before popping the current
  /// top-most non-ephemeral route.
  ///
  /// If ephemeral is false, then the route can be popped with navigator.pop().
  ///
  /// Set ephemeral to true if you want to be automatically popped when another
  /// route is pushed or popped.
  ///
  /// modal must be true if ephemeral is false.
  bool get ephemeral => false;

  /// If modal is true, a hidden layer is inserted in the widget tree that
  /// catches all touches to widgets created by routes below this one, even if
  /// this one is transparent.
  ///
  /// If modal is false, then earlier routes can be interacted with, including
  /// causing new routes to be pushed and/or this route (and maybe others) to be
  /// popped.
  ///
  /// ephemeral must be true if modal is false.
  bool get modal => true;

  /// If opaque is true, then routes below this one will not be built or painted
  /// when the transition to this route is complete.
  ///
  /// If opaque is false, then the previous route will always be painted even if
  /// this route's transition is complete.
  ///
  /// Set this to true if there's no reason to build and paint the route behind
  /// you when your transition is finished, and set it to false if you do not
  /// cover the entire application surface or are in any way semi-transparent.
  bool get opaque => false; 

  /// If this is set to a non-zero [Duration], then an [AnimationPerformance]
  /// object, available via the performance field, will be created when the
  /// route is first built, using the duration described here.
  Duration get transitionDuration => Duration.ZERO;

  bool get isActuallyOpaque => (performance == null || _performance.isCompleted) && opaque;

  Widget build(Key key, NavigatorState navigator);
  void didPop([dynamic result]) {
    if (performance == null && _onDismissed != null)
      _onDismissed();
  }

  String toString() => '$runtimeType()';
}

const Duration _kTransitionDuration = const Duration(milliseconds: 150);
const Point _kTransitionStartPoint = const Point(0.0, 75.0);

class PageRoute extends Route {
  PageRoute(this.builder);

  final RouteBuilder builder;

  bool get opaque => true;

  Duration get transitionDuration => _kTransitionDuration;

  Widget build(Key key, NavigatorState navigator) {
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

  bool get opaque => false;

  void didPop([dynamic result]) {
    assert(result == null);
    if (callback != null)
      callback(this);
    super.didPop(result);
  }

  bool get hasContent => false;
  Widget build(Key key, NavigatorState navigator) => null;
}
