// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/widgets/animated_component.dart';
import 'package:sky/widgets/animation_builder.dart';
import 'package:sky/widgets/basic.dart';
import 'package:vector_math/vector_math.dart';

typedef Widget Builder(Navigator navigator, RouteBase route);

abstract class RouteBase {
  RouteBase({ this.key });
  final Object key;
  Widget build(Navigator navigator, RouteBase route);
  void popState() { }
}

class Route extends RouteBase {
  Route({ String name, this.builder }) : super(key: name);
  String get name => key;
  final Builder builder;
  Widget build(Navigator navigator, RouteBase route) => builder(navigator, route);
}

class RouteState extends RouteBase {

  RouteState({ this.callback, this.route, Object key }) : super(key: key);

  RouteBase route;
  Function callback;

  Widget build(Navigator navigator, RouteBase route) => null;

  void popState() {
    if (callback != null)
      callback(this);
  }
}

// TODO(jackson): Refactor this into its own file
// and support multiple transition types
const Duration _kTransitionDuration = const Duration(milliseconds: 200);
const Point _kTransitionStartPoint = const Point(0.0, 100.0);
enum TransitionDirection { forward, reverse }
class Transition extends AnimatedComponent {
  Transition({
    String key,
    this.content,
    this.direction,
    this.onDismissed,
    this.interactive
  }) : super(key: key);
  Widget content;
  TransitionDirection direction;
  bool interactive;
  Function onDismissed;

  AnimatedType<Point> _position;
  AnimatedType<double> _opacity;
  AnimationPerformance _performance;

  void initState() {
    _position = new AnimatedType<Point>(
      _kTransitionStartPoint,
      end: Point.origin,
      curve: easeOut
    );
    _opacity = new AnimatedType<double>(0.0, end: 1.0)
      ..curve = easeOut;
    _performance = new AnimationPerformance()
      ..duration = _kTransitionDuration
      ..variable = new AnimatedList([_position, _opacity])
      ..addListener(_checkDismissed);
    if (direction == TransitionDirection.reverse)
      _performance.progress = 1.0;
    watch(_performance);
    _start();
  }

  void _start() {
    _dismissed = false;
    switch (direction) {
      case TransitionDirection.forward:
      _performance.play();
      break;
      case TransitionDirection.reverse:
      _performance.reverse();
      break;
    }
  }

  void syncFields(Transition source) {
    content = source.content;
    if (direction != source.direction) {
      direction = source.direction;
      _start();
    }
    interactive = source.interactive;
    onDismissed = source.onDismissed;
    super.syncFields(source);
  }

  bool _dismissed = false;
  void _checkDismissed() {
    if (!_dismissed &&
        direction == TransitionDirection.reverse &&
        _performance.isDismissed) {
      if (onDismissed != null)
        onDismissed();
      _dismissed = true;
    }
  }

  Widget build() {
    Matrix4 transform = new Matrix4.identity()
      ..translate(_position.value.x, _position.value.y);
    // TODO(jackson): Hit testing should ignore transform
    // TODO(jackson): Block input unless content is interactive
    return new Transform(
      transform: transform,
      child: new Opacity(
        opacity: _opacity.value,
        child: content
      )
    );
  }
}

class HistoryEntry {
  HistoryEntry({ this.route, this.key });
  final RouteBase route;
  final int key;
  // TODO(jackson): Keep track of the requested transition
}

class NavigationState {

  NavigationState(List<Route> routes) {
    for (Route route in routes) {
      if (route.name != null)
        namedRoutes[route.name] = route;
    }
    history.add(new HistoryEntry(route: routes[0], key: _lastKey++));
  }

  List<HistoryEntry> history = new List<HistoryEntry>();
  int historyIndex = 0;
  int _lastKey = 0;
  Map<String, RouteBase> namedRoutes = new Map<String, RouteBase>();

  RouteBase get currentRoute => history[historyIndex].route;
  bool hasPrevious() => historyIndex > 0;

  void pushNamed(String name) {
    Route route = namedRoutes[name];
    assert(route != null);
    push(route);
  }

  void push(RouteBase route) {
    HistoryEntry historyEntry = new HistoryEntry(route: route, key: _lastKey++);
    history.insert(historyIndex + 1, historyEntry);
    historyIndex++;
  }

  void pop() {
    if (historyIndex > 0) {
      HistoryEntry entry = history[historyIndex];
      entry.route.popState();
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

  void pushState(Object key, Function callback) {
    RouteBase route = new RouteState(
      key: key,
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
    List<Widget> visibleRoutes = new List<Widget>();
    for (int i = 0; i < state.history.length; i++) {
      // TODO(jackson): Avoid building routes that are not visible
      HistoryEntry historyEntry = state.history[i];
      Widget content = historyEntry.route.build(this, historyEntry.route);
      if (i == 0) {
        visibleRoutes.add(content);
        continue;
      }
      if (content == null)
        continue;
      Transition transition = new Transition(
        key: historyEntry.key.toString(),
        content: content,
        direction: (i <= state.historyIndex) ? TransitionDirection.forward : TransitionDirection.reverse,
        interactive: (i == state.historyIndex),
        onDismissed: () {
          setState(() {
            state.history.remove(historyEntry);
          });
        }
      );
      visibleRoutes.add(transition);
    }
    return new Stack(visibleRoutes);
  }
}
