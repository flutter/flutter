// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'focus.dart';
import 'framework.dart';
import 'heroes.dart';
import 'transitions.dart';
import 'gridpaper.dart';

/// Set this to true to overlay a pixel grid on the screen, with every 100
/// pixels marked with a thick maroon line and every 10 pixels marked with a
/// thin maroon line. This can help with verifying widget positions.
bool debugShowGrid = false;
Color debugGridColor = const Color(0x7F7F2020);

const String kDefaultRouteName = '/';

class RouteArguments {
  const RouteArguments(this.navigator, { this.previousPerformance, this.nextPerformance });
  final NavigatorState navigator;
  final PerformanceView previousPerformance;
  final PerformanceView nextPerformance;
}

typedef Widget RouteBuilder(RouteArguments args);
typedef RouteBuilder RouteGenerator(String name);
typedef void StateRouteCallback(StateRoute route);

class Navigator extends StatefulComponent {
  Navigator({
    Key key,
    this.routes,
    this.onGenerateRoute, // you need to implement this if you pushNamed() to names that might not be in routes.
    this.onUnknownRoute // 404 generator. You only need to implement this if you have a way to navigate to arbitrary names.
  }) : super(key: key) {
    // To use a navigator, you must at a minimum define the route with the name '/'.
    assert(routes != null);
    assert(routes.containsKey(kDefaultRouteName));
  }

  final Map<String, RouteBuilder> routes;
  final RouteGenerator onGenerateRoute;
  final RouteBuilder onUnknownRoute;

  static NavigatorState of(BuildContext context) {
    NavigatorState result;
    bool visitor(Element element) {
      if (element is StatefulComponentElement) {
        if (element.state is NavigatorState) {
          result = element.state;
          return false;
        }
      }
      return true;
    }
    if (visitor(context))
      context.visitAncestorElements(visitor);
    return result;
  }

  NavigatorState createState() => new NavigatorState();
}

// The navigator tracks which "page" we are on.
// It also animates between these pages.
// Pages can have "heroes", which are UI elements that animate from point to point.
// These animations are called journeys.
//
// Journeys can start in two conditions:
//  - Everything is calm, and we have no heroes in flight. In this case, we will
//    have to collect the heroes from the route we're starting at and the route
//    we're going to, and try to transition from one set to the other.
//  - We already have heroes in flight. In that case, we just want to look at
//    the heroes of our destination, and then try to transition to them from the
//    in-flight heroes.

class _HeroTransitionInstruction {
  Route from;
  Route to;
  void update(Route newFrom, Route newTo) {
    assert(newFrom != null);
    assert(newTo != null);
    if (!newFrom.canHaveHeroes || !newTo.canHaveHeroes)
      return;
    assert(newFrom.performance != null);
    assert(newTo.performance != null);
    if (from == null)
      from = newFrom;
    to = newTo;
    if (from == to)
      reset();
  }
  void reset() {
    assert(hasInstructions);
    from = null;
    to = null;
  }
  bool get hasInstructions => from != null || to != null;
}

class NavigatorState extends State<Navigator> {

  List<Route> _history = new List<Route>();
  int _currentPosition = 0; // which route is "current"

  Route get currentRoute => _history[_currentPosition];
  bool get hasPreviousRoute => _history.length > 1;

  void initState() {
    super.initState();
    _activeHeroes = new HeroParty(onQuestFinished: _handleHeroQuestFinished);
    PageRoute route = new PageRoute(config.routes[kDefaultRouteName], name: kDefaultRouteName);
    assert(route.hasContent);
    assert(!route.ephemeral);
    _insertRoute(route);
  }

  void pushState(State owner, StateRouteCallback onPop) {
    push(new StateRoute(
      route: currentRoute,
      owner: owner,
      onPop: onPop
    ));
  }

  void pushNamed(String name, { Set<Key> mostValuableKeys }) {
    RouteBuilder generateRoute() {
      assert(config.onGenerateRoute != null);
      return config.onGenerateRoute(name);
    }
    final RouteBuilder builder = config.routes[name] ?? generateRoute() ?? config.onUnknownRoute;
    assert(builder != null); // 404 getting your 404!
    push(new PageRoute(builder, name: name, mostValuableKeys: mostValuableKeys));
  }

  final _HeroTransitionInstruction _desiredHeroes = new _HeroTransitionInstruction();
  HeroParty _activeHeroes;

  void _handleHeroQuestFinished() {
    for (Route route in _history)
      route._hasActiveHeroes = false;
  }

  void push(Route route) {
    assert(!_debugCurrentlyHaveRoute(route));
    setState(() {
      // pop ephemeral routes (like popup menus)
      while (currentRoute.ephemeral) {
        currentRoute.didPop(null);
        _currentPosition -= 1;
      }
      // find the most recent active route that might have heroes
      if (route.hasContent) {
        int index = _currentPosition;
        while (index > 0 && !_history[index].hasContent)
          index -= 1;
        assert(_history[index].hasContent);
        _desiredHeroes.update(_history[index], route);
      }
      // add the new route
      _currentPosition += 1;
      _insertRoute(route);
    });
  }

  void popRoute(Route route, [dynamic result]) {
    assert(_debugCurrentlyHaveRoute(route));
    assert(_currentPosition > 0);
    setState(() {
      // pop any routes above this one (they must be ephemeral, otherwise there's an error)
      while (currentRoute != route) {
        assert(currentRoute.ephemeral);
        currentRoute.didPop(null);
        _currentPosition -= 1;
      }
    });
    pop(result);
    assert(!_debugCurrentlyHaveRoute(route));
  }

  void pop([dynamic result]) {
    setState(() {
      assert(_currentPosition > 0);
      // find the most recent previous route that might have heroes
      if (currentRoute.hasContent) {
        int index = _currentPosition - 1;
        while (index > 0 && !_history[index].hasContent)
          index -= 1;
        assert(_history[index].hasContent);
        _desiredHeroes.update(currentRoute, _history[index]);
      }
      // pop the route
      currentRoute.didPop(result);
      _currentPosition -= 1;
    });
  }

  bool _debugCurrentlyHaveRoute(Route route) {
    int index = _history.indexOf(route);
    return index >= 0 && index <= _currentPosition;
  }

  void _didCompleteRoute(Route route) {
    assert(_history.contains(route));
    if (route.isActuallyOpaque) {
      setState(() {
        // we need to rebuild because our build function depends on
        // whether the route is opaque or not.
      });
    }
  }

  void _didDismissRoute(Route route) {
    assert(_history.contains(route));
    if (_history.lastIndexOf(route) <= _currentPosition)
      popRoute(route);
  }

  void _insertRoute(Route route) {
    _history.insert(_currentPosition, route);
    route.didPush(this);
  }

  void _removeRoute(Route route) {
    assert(_history.contains(route));
    setState(() {
      if (_desiredHeroes.hasInstructions) {
        if (_desiredHeroes.from == route || _desiredHeroes.to == route)
          _desiredHeroes.reset();
      }
      _history.remove(route);
    });
  }

  PerformanceView _currentHeroPerformance;

  Widget build(BuildContext context) {
    List<Widget> visibleRoutes = <Widget>[];

    assert(() {
      if (debugShowGrid)
        visibleRoutes.add(new GridPaper(color: debugGridColor));
      return true;
    });


    bool alreadyInsertedHeroes = false;
    bool alreadyInsertedModalBarrier = false;
    Route nextContentRoute;
    PerformanceView nextHeroPerformance;
    for (int i = _history.length-1; i >= 0; i -= 1) {
      final Route route = _history[i];
      if (!route.hasContent) {
        assert(!route.modal);
        assert(!_desiredHeroes.hasInstructions || (_desiredHeroes.from != route && _desiredHeroes.to != route));
        assert(!route._hasActiveHeroes);
        continue;
      }
      if (route._hasActiveHeroes && !alreadyInsertedHeroes) {
        visibleRoutes.addAll(_activeHeroes.getWidgets(context, _currentHeroPerformance));
        alreadyInsertedHeroes = true;
      }
      if (_desiredHeroes.hasInstructions) {
        if ((_desiredHeroes.to == route || _desiredHeroes.from == route) && nextHeroPerformance == null)
          nextHeroPerformance = route.performance;
        visibleRoutes.add(route._internalBuild(nextContentRoute, buildTargetHeroes: _desiredHeroes.to == route));
      } else {
        visibleRoutes.add(route._internalBuild(nextContentRoute));
      }
      if (route.isActuallyOpaque) {
        assert(!_desiredHeroes.hasInstructions ||
               (_history.indexOf(_desiredHeroes.from) >= i && _history.indexOf(_desiredHeroes.to) >= i));
        break;
      }
      assert(route.modal || route.ephemeral);
      if (route.modal && i > 0 && !alreadyInsertedModalBarrier) {
        visibleRoutes.add(new Listener(
          onPointerDown: (_) { pop(); },
          child: new Container()
        ));
        alreadyInsertedModalBarrier = true;
      }
      nextContentRoute = route;
    }

    if (_desiredHeroes.hasInstructions) {
      assert(nextHeroPerformance != null);
      scheduler.requestPostFrameCallback((Duration timestamp) {
        Map<Object, HeroHandle> heroesFrom;
        Map<Object, HeroHandle> heroesTo;
        Set<Key> mostValuableKeys = new Set<Key>();
        if (_desiredHeroes.from.mostValuableKeys != null)
          mostValuableKeys.addAll(_desiredHeroes.from.mostValuableKeys);
        if (_desiredHeroes.to.mostValuableKeys != null)
          mostValuableKeys.addAll(_desiredHeroes.to.mostValuableKeys);
        if (_activeHeroes.isEmpty) {
          assert(!_desiredHeroes.from._hasActiveHeroes);
          heroesFrom = _desiredHeroes.from.getHeroesToAnimate(mostValuableKeys);
          _desiredHeroes.from._hasActiveHeroes = heroesFrom.length > 0;
        } else {
          assert(_desiredHeroes.from._hasActiveHeroes);
          heroesFrom = _activeHeroes.getHeroesToAnimate();
        }
        heroesTo = _desiredHeroes.to.getHeroesToAnimate(mostValuableKeys);
        _desiredHeroes.to._hasActiveHeroes = heroesTo.length > 0;
        _desiredHeroes.reset();
        setState(() {
          final RenderBox renderObject = context.findRenderObject();
          final Point animationTopLeft = renderObject.localToGlobal(Point.origin);
          final Point animationBottomRight = renderObject.localToGlobal(renderObject.size.bottomRight(Point.origin));
          final Rect animationArea = new Rect.fromLTRB(animationTopLeft.x, animationTopLeft.y, animationBottomRight.x, animationBottomRight.y);
          Curve curve = Curves.ease;
          if (nextHeroPerformance.status == PerformanceStatus.reverse) {
            nextHeroPerformance = new ReversePerformance(nextHeroPerformance);
            curve = new Interval(nextHeroPerformance.progress, 1.0, curve: curve);
          }
          _activeHeroes.animate(heroesFrom, heroesTo, animationArea, curve);
          _currentHeroPerformance = nextHeroPerformance;
        });
      });
    }

    return new Focus(child: new Stack(visibleRoutes.reversed.toList()));
  }

}

abstract class Route {
  Route() {
    _subtreeKey = new GlobalKey(label: debugLabel);
  }

  /// If hasContent is true, then the route represents some on-screen state.
  ///
  /// If hasContent is false, then no performance will be created, and the values of
  /// ephemeral, modal, and opaque are ignored. This is useful if the route
  /// represents some state handled by another widget. See
  /// NavigatorState.pushState().
  ///
  /// Set hasContent to false if you have nothing useful to return from build().
  ///
  /// modal must be false if hasContent is false, since otherwise any
  /// interaction with the system at all would imply that the current route is
  /// popped, which would be pointless.
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
  /// hasContent must be true if modal is true.
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

  PerformanceView get performance => null;
  bool get isActuallyOpaque => (performance == null || performance.isCompleted) && opaque;

  NavigatorState get navigator => _navigator;
  NavigatorState _navigator;

  void setState(void fn()) {
    assert(navigator != null);
    navigator.setState(fn);
  }

  void didPush(NavigatorState navigator) {
    assert(_navigator == null);
    _navigator = navigator;
    assert(_navigator != null);
    performance?.addStatusListener(_handlePerformanceStatusChanged);
  }

  void didPop([dynamic result]) {
    assert(navigator != null);
    if (performance == null)
      navigator._removeRoute(this);
  }

  void _handlePerformanceStatusChanged(PerformanceStatus status) {
    if (status == PerformanceStatus.completed) {
      navigator._didCompleteRoute(this);
    } else if (status == PerformanceStatus.dismissed) {
      navigator._didDismissRoute(this);
      navigator._removeRoute(this);
      _navigator = null;
    }
  }

  /// Called by the navigator.build() function if hasContent is true, to get the
  /// subtree for this route.
  ///
  /// If buildTargetHeroes is true, then getHeroesToAnimate() will be called
  /// after this build, before the next build, and this build should render the
  /// route off-screen, at the end of its animation. Next frame, the argument
  /// will be false, and the tree should be built at the first frame of the
  /// transition animation, whatever that is.
  Widget _internalBuild(Route nextRoute, { bool buildTargetHeroes: false }) {
    assert(navigator != null);
    return keySubtree(build(new RouteArguments(
      navigator,
      previousPerformance: performance,
      nextPerformance: nextRoute?.performance
    )));
  }

  bool get canHaveHeroes => hasContent && modal && opaque;
  Set<Key> get mostValuableKeys => null;

  /// Return a party of heroes (one per tag) to animate. This is called by the
  /// navigator when hasContent is true just after this route, the previous
  /// route, or the next route, has been pushed or popped, to figure out which
  /// heroes it should be trying to animate.
  Map<Object, HeroHandle> getHeroesToAnimate([Set<Key> mostValuableKeys]) => const <Object, HeroHandle>{};
  bool _hasActiveHeroes = false;

  /// Returns the BuildContext for the root of the subtree built for this route,
  /// assuming that internalBuild used keySubtree to build that subtree.
  /// This is only valid after a build phase.
  BuildContext get context => _subtreeKey.currentContext;

  GlobalKey _subtreeKey;

  /// Wraps the given subtree in a route-specific GlobalKey.
  Widget keySubtree(Widget child) {
    return new KeyedSubtree(
      key: _subtreeKey,
      child: child
    );
  }

  /// Called by internalBuild. This is the method to override if you want to
  /// change what subtree is built for this route.
  Widget build(RouteArguments args);

  String get debugLabel => '$runtimeType';

  String toString() => '$runtimeType(performance: $performance; key: $_subtreeKey)';
}


abstract class PerformanceRoute extends Route {
  PerformanceRoute() {
    _performance = createPerformance();
  }

  PerformanceView get performance => _performance?.view;
  Performance _performance;

  Performance createPerformance() {
    Duration duration = transitionDuration;
    assert(duration != null && duration >= Duration.ZERO);
    return new Performance(duration: duration, debugLabel: debugLabel);
  }

  Duration get transitionDuration;

  Widget _internalBuild(Route nextRoute, { bool buildTargetHeroes: false }) {
    assert(hasContent);
    assert(transitionDuration > Duration.ZERO);
    if (buildTargetHeroes && performance.progress != 1.0) {
      Performance fakePerformance = createPerformance();
      assert(fakePerformance != null);
      fakePerformance.progress = 1.0;
      return new OffStage(
        child: keySubtree(
          build(new RouteArguments(navigator, previousPerformance: fakePerformance))
        )
      );
    }
    return super._internalBuild(nextRoute, buildTargetHeroes: buildTargetHeroes);
  }

  void didPush(NavigatorState navigator) {
    super.didPush(navigator);
    _performance?.forward();
  }

  void didPop([dynamic result]) {
    _performance?.reverse();
    super.didPop(result);
  }
}

const Duration _kTransitionDuration = const Duration(milliseconds: 150);
const Point _kTransitionStartPoint = const Point(0.0, 75.0);

/// A route that represents a page in an application.
///
/// PageRoutes try to animate between themselves in a fashion that is aware of
/// any Heroes.
class PageRoute extends PerformanceRoute {
  PageRoute(this._builder, {
    this.name: '<anonymous>',
    Set<Key> mostValuableKeys
  }) : _mostValuableKeys = mostValuableKeys {
    assert(_builder != null);
  }

  final RouteBuilder _builder;
  final String name;
  final Set<Key> _mostValuableKeys;

  Set<Key> get mostValuableKeys => _mostValuableKeys;

  bool get opaque => true;
  Duration get transitionDuration => _kTransitionDuration;

  Map<Object, HeroHandle> getHeroesToAnimate([Set<Key> mostValuableKeys]) {
    return Hero.of(context, mostValuableKeys);
  }

  Widget build(RouteArguments args) {
    // TODO(jackson): Hit testing should ignore transform
    // TODO(jackson): Block input unless content is interactive
    // TODO(ianh): Support having different transitions, e.g. when heroes are around.
    return new SlideTransition(
      performance: args.previousPerformance,
      position: new AnimatedValue<Point>(_kTransitionStartPoint, end: Point.origin, curve: Curves.easeOut),
      child: new FadeTransition(
        performance: args.previousPerformance,
        opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: Curves.easeOut),
        child: invokeBuilder(args)
      )
    );
  }

  Widget invokeBuilder(RouteArguments args) {
    Widget result = _builder(args);
    assert(() {
      if (result == null)
        debugPrint('The builder for route \'$name\' returned null. RouteBuilders must never return null.');
      assert(result != null && 'A RouteBuilder returned null. See the previous log message for details.' is String);
      return true;
    });
    return result;
  }

  String get debugLabel => '${super.debugLabel}($name)';
}

class StateRoute extends Route {
  StateRoute({ this.route, this.owner, this.onPop });

  Route route;
  State owner;
  StateRouteCallback onPop;

  bool get hasContent => false;
  bool get modal => false;
  bool get opaque => false;

  void didPop([dynamic result]) {
    assert(result == null);
    if (onPop != null)
      onPop(this);
    super.didPop(result);
  }

  Widget build(RouteArguments args) => null;
}
