// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:meta/meta.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'pages.dart';
import 'transitions.dart';

// Heroes are the parts of an application's screen-to-screen transitions where a
// widget from one screen shifts to a position on the other. For example,
// album art from a list of albums growing to become the centerpiece of the
// album's details view. In this context, a screen is a navigator ModalRoute.

// To get this effect, all you have to do is wrap each hero on each route with a
// Hero widget, and give each hero a tag. The tag must either be unique within the
// current route's widget subtree. When the app transitions from one route to
// another, each hero is animated to its new location. If a hero is only
// present on one of the routes and not the other, then it will be made to
// appear or disappear as needed.

// TODO(ianh): Make the appear/disappear animations pretty. Right now they're
// pretty crude (just rotate and shrink the constraints). They should probably
// involve actually scaling and fading, at a minimum.

// Heroes and the Navigator's Stack must be axis-aligned for all this to work.
// The top left and bottom right coordinates of each animated Hero will be
// converted to global coordinates and then from there converted to the
// Navigator Stack's coordinate space, and the entire Hero subtree will, for the
// duration of the animation, be lifted out of its original place, and
// positioned on that stack. If the Hero isn't axis aligned, this is going to
// fail in a rather ugly fashion. Don't rotate your heroes!

// To make the animations look good, it's critical that the widget tree for the
// hero in both locations be essentially identical. The widget of the target is
// used to do the transition: when going from route A to route B, route B's
// hero's widget is placed over route A's hero's widget, and route A's hero is
// hidden. Then the widget is animated to route B's hero's position, and then
// the widget is inserted into route B. When going back from B to A, route A's
// hero's widget is placed over where route B's hero's widget was, and then the
// animation goes the other way.

// TODO(ianh): If the widgets use Inherited properties, they are taken from the
// Navigator's position in the widget hierarchy, not the source or target. We
// should interpolate the inherited properties from their value at the source to
// their value at the target. See: https://github.com/flutter/flutter/issues/213

class _HeroManifest {
  const _HeroManifest({
    this.key,
    this.config,
    this.sourceStates,
    this.currentRect,
    this.currentTurns
  });
  final GlobalKey key;
  final Widget config;
  final Set<HeroState> sourceStates;
  final Rect currentRect;
  final double currentTurns;
}

abstract class HeroHandle {
  bool get alwaysAnimate;
  _HeroManifest _takeChild(Animation<double> currentAnimation);
}

class Hero extends StatefulWidget {
  Hero({
    Key key,
    this.tag,
    this.child,
    this.turns: 1,
    this.alwaysAnimate: false
  }) : super(key: key) {
    assert(tag != null);
  }

  final Object tag;

  /// The widget below this widget in the tree.
  final Widget child;

  final int turns;

  /// If true, the hero will always animate, even if it has no matching hero to
  /// animate to or from.
  final bool alwaysAnimate;

  /// Return a hero tag to HeroState map of all of the heroes within the given subtree.
  static Map<Object, HeroHandle> of(BuildContext context) {
    final Map<Object, HeroHandle> result = <Object, HeroHandle>{};
    void visitor(Element element) {
      if (element.widget is Hero) {
        StatefulElement hero = element;
        Hero heroWidget = element.widget;
        Object tag = heroWidget.tag;
        assert(tag != null);
        assert(() {
          if (result.containsKey(tag)) {
            new FlutterError(
              'There are multiple heroes that share the same tag within a subtree.\n'
              'Within each subtree for which heroes are to be animated (typically a PageRoute subtree), '
              'each Hero must have a unique non-null tag.\n'
              'In this case, multiple heroes had the tag "$tag".'
            );
          }
          return true;
        });
        HeroState heroState = hero.state;
        result[tag] = heroState;
      }
      element.visitChildren(visitor);
    }
    context.visitChildElements(visitor);
    return result;
  }

  @override
  HeroState createState() => new HeroState();
}

class HeroState extends State<Hero> implements HeroHandle {

  GlobalKey _key = new GlobalKey();
  Size _placeholderSize;
  VoidCallback _disposeCallback;

  @override
  bool get alwaysAnimate => config.alwaysAnimate;

  @override
  _HeroManifest _takeChild(Animation<double> currentAnimation) {
    assert(mounted);
    final RenderBox renderObject = context.findRenderObject();
    assert(renderObject != null);
    assert(!renderObject.needsLayout);
    assert(renderObject.hasSize);
    if (_placeholderSize == null) {
      // We are a "from" hero, about to depart on a quest.
      // Remember our size so that we can leave a placeholder.
      _placeholderSize = renderObject.size;
    }
    final Point heroTopLeft = renderObject.localToGlobal(Point.origin);
    final Point heroBottomRight = renderObject.localToGlobal(renderObject.size.bottomRight(Point.origin));
    final Rect heroArea = new Rect.fromLTRB(heroTopLeft.x, heroTopLeft.y, heroBottomRight.x, heroBottomRight.y);
    _HeroManifest result = new _HeroManifest(
      key: _key, // might be null, e.g. if the hero is returning to us
      config: config,
      sourceStates: new HashSet<HeroState>.from(<HeroState>[this]),
      currentRect: heroArea,
      currentTurns: config.turns.toDouble()
    );
    if (_key != null)
      setState(() { _key = null; });
    return result;
  }

  void _setChild(GlobalKey value) {
    assert(_key == null);
    assert(_placeholderSize != null);
    assert(mounted);
    setState(() {
      _key = value;
      _placeholderSize = null;
    });
  }

  void _resetChild() {
    if (mounted)
      _setChild(null);
  }

  @override
  void dispose() {
    if (_disposeCallback != null)
      _disposeCallback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_placeholderSize != null) {
      assert(_key == null);
      return new SizedBox(width: _placeholderSize.width, height: _placeholderSize.height);
    }
    return new KeyedSubtree(
      key: _key,
      child: config.child
    );
  }

}


class _HeroQuestState implements HeroHandle {
  _HeroQuestState({
    this.tag,
    this.key,
    this.child,
    this.sourceStates,
    this.animationArea,
    this.targetRect,
    this.targetTurns,
    this.targetState,
    this.currentRect,
    this.currentTurns
  }) {
    assert(tag != null);

    for (HeroState state in sourceStates)
      state._disposeCallback = () => sourceStates.remove(state);

    if (targetState != null)
      targetState._disposeCallback = _handleTargetStateDispose;
  }

  final Object tag;
  final GlobalKey key;
  final Widget child;
  final Set<HeroState> sourceStates;
  final Rect animationArea;
  Rect targetRect;
  int targetTurns;
  HeroState targetState;
  final RectTween currentRect;
  final Tween<double> currentTurns;

  OverlayEntry overlayEntry;

  @override
  bool get alwaysAnimate => true;

  bool get taken => _taken;
  bool _taken = false;

  @override
  _HeroManifest _takeChild(Animation<double> currentAnimation) {
    assert(!taken);
    _taken = true;
    Set<HeroState> states = sourceStates;
    if (targetState != null)
      states = states.union(new HashSet<HeroState>.from(<HeroState>[targetState]));

    for (HeroState state in states)
      state._disposeCallback = null;

    return new _HeroManifest(
      key: key,
      config: child,
      sourceStates: states,
      currentRect: currentRect.evaluate(currentAnimation),
      currentTurns: currentTurns.evaluate(currentAnimation)
    );
  }

  void _handleTargetStateDispose() {
    targetState = null;
    targetTurns = 0;
    targetRect = targetRect.center & Size.zero;
    WidgetsBinding.instance.addPostFrameCallback((Duration d) => overlayEntry.markNeedsBuild());
  }

  Widget build(BuildContext context, Animation<double> animation) {
    return new RelativePositionedTransition(
      rect: currentRect.animate(animation),
      size: animationArea.size,
      child: new RotationTransition(
        turns: currentTurns.animate(animation),
        child: new IgnorePointer(
          child: new RepaintBoundary(
            key: key,
            child: child
          )
        )
      )
    );
  }

  @mustCallSuper
  void dispose() {
    overlayEntry = null;

    for (HeroState state in sourceStates)
      state._disposeCallback = null;

    if (targetState != null)
      targetState._disposeCallback = null;
  }
}

class _HeroMatch {
  const _HeroMatch(this.from, this.to, this.tag);
  final HeroHandle from;
  final HeroHandle to;
  final Object tag;
}

typedef RectTween CreateRectTween(Rect begin, Rect end);

class HeroParty {
  HeroParty({ this.onQuestFinished, this.createRectTween });

  final VoidCallback onQuestFinished;
  final CreateRectTween createRectTween;

  List<_HeroQuestState> _heroes = <_HeroQuestState>[];
  bool get isEmpty => _heroes.isEmpty;

  Map<Object, HeroHandle> getHeroesToAnimate() {
    Map<Object, HeroHandle> result = new Map<Object, HeroHandle>();
    for (_HeroQuestState hero in _heroes)
      result[hero.tag] = hero;
    assert(!result.containsKey(null));
    return result;
  }

  RectTween _doCreateRectTween(Rect begin, Rect end) {
    if (createRectTween != null)
      return createRectTween(begin, end);
    return new RectTween(begin: begin, end: end);
  }

  Tween<double> createTurnsTween(double begin, double end) {
    assert(end.floor() == end);
    return new Tween<double>(begin: begin, end: end);
  }

  void animate(Map<Object, HeroHandle> heroesFrom, Map<Object, HeroHandle> heroesTo, Rect animationArea) {
    assert(!heroesFrom.containsKey(null));
    assert(!heroesTo.containsKey(null));

    // make a list of pairs of heroes, based on the from and to lists
    Map<Object, _HeroMatch> heroes = <Object, _HeroMatch>{};
    for (Object tag in heroesFrom.keys)
      heroes[tag] = new _HeroMatch(heroesFrom[tag], heroesTo[tag], tag);
    for (Object tag in heroesTo.keys) {
      if (!heroes.containsKey(tag))
        heroes[tag] = new _HeroMatch(heroesFrom[tag], heroesTo[tag], tag);
    }

    // create a heroating hero out of each pair
    final List<_HeroQuestState> _newHeroes = <_HeroQuestState>[];
    for (_HeroMatch heroPair in heroes.values) {
      assert(heroPair.from != null || heroPair.to != null);
      if ((heroPair.from == null && !heroPair.to.alwaysAnimate) ||
          (heroPair.to == null && !heroPair.from.alwaysAnimate))
        continue;
      _HeroManifest from = heroPair.from?._takeChild(_currentAnimation);
      assert(heroPair.to == null || heroPair.to is HeroState);
      _HeroManifest to = heroPair.to?._takeChild(_currentAnimation);
      assert(from != null || to != null);
      assert(to == null || to.sourceStates.length == 1);
      assert(to == null || to.currentTurns.floor() == to.currentTurns);
      HeroState targetState = to != null ? to.sourceStates.elementAt(0) : null;
      Set<HeroState> sourceStates = from?.sourceStates ?? new HashSet<HeroState>();
      sourceStates.remove(targetState);
      Rect sourceRect = from?.currentRect ?? to.currentRect.center & Size.zero;
      Rect targetRect = to?.currentRect ?? from.currentRect.center & Size.zero;
      double sourceTurns = from?.currentTurns ?? 0.0;
      double targetTurns = to?.currentTurns ?? 0.0;
      _newHeroes.add(new _HeroQuestState(
        tag: heroPair.tag,
        key: from?.key ?? to.key,
        child: to?.config ?? from.config,
        sourceStates: sourceStates,
        animationArea: animationArea,
        targetRect: targetRect,
        targetTurns: targetTurns.floor(),
        targetState: targetState,
        currentRect: _doCreateRectTween(sourceRect, targetRect),
        currentTurns: createTurnsTween(sourceTurns, targetTurns)
      ));
    }

    assert(!_heroes.any((_HeroQuestState hero) => !hero.taken));
    for (_HeroQuestState hero in _heroes)
      hero.dispose();
    _heroes = _newHeroes;
  }

  Animation<double> _currentAnimation;

  void _clearCurrentAnimation() {
    _currentAnimation?.removeStatusListener(_handleUpdate);
    _currentAnimation = null;
  }

  void setAnimation(Animation<double> animation) {
    assert(animation != null || _heroes.length == 0);
    if (animation != _currentAnimation) {
      _clearCurrentAnimation();
      _currentAnimation = animation;
      _currentAnimation?.addStatusListener(_handleUpdate);
    }
  }

  void _handleUpdate(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      for (_HeroQuestState hero in _heroes) {
        if (hero.targetState != null)
          hero.targetState._setChild(hero.key);
        for (HeroState source in hero.sourceStates)
          source._resetChild();
        hero.dispose();
      }
      _heroes.clear();
      _clearCurrentAnimation();
      if (onQuestFinished != null)
        onQuestFinished();
    }
  }

  @override
  String toString() => '$_heroes';
}

class HeroController extends NavigatorObserver {
  HeroController({ CreateRectTween createRectTween }) {
    _party = new HeroParty(
      onQuestFinished: _handleQuestFinished,
      createRectTween: createRectTween
    );
  }

  HeroParty _party;
  Animation<double> _animation;
  PageRoute<dynamic> _from;
  PageRoute<dynamic> _to;

  final List<OverlayEntry> _overlayEntries = new List<OverlayEntry>();

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    assert(navigator != null);
    assert(route != null);
    if (route is PageRoute<dynamic>) {
      assert(route.animation != null);
      if (previousRoute is PageRoute<dynamic>) // could be null
        _from = previousRoute;
      _to = route;
      _animation = route.animation;
      _checkForHeroQuest();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    assert(navigator != null);
    assert(route != null);
    if (route is PageRoute<dynamic>) {
      assert(route.animation != null);
      if (previousRoute is PageRoute<dynamic>) {
        _to = previousRoute;
        _from = route;
        _animation = route.animation;
        _checkForHeroQuest();
      }
    }
  }

  // Disable Hero animations while a user gesture is controlling the navigation.
  bool _questsEnabled = true;

  @override
  void didStartUserGesture() {
    _questsEnabled = false;
  }

  @override
  void didStopUserGesture() {
    _questsEnabled = true;
  }

  void _checkForHeroQuest() {
    if (_from != null && _to != null && _from != _to && _questsEnabled) {
      _to.offstage = _to.animation.status != AnimationStatus.completed;
      WidgetsBinding.instance.addPostFrameCallback(_updateQuest);
    }
  }

  void _handleQuestFinished() {
    _removeHeroesFromOverlay();
    _from = null;
    _to = null;
    _animation = null;
  }

  Rect _getAnimationArea(BuildContext context) {
    RenderBox box = context.findRenderObject();
    Point topLeft = box.localToGlobal(Point.origin);
    Point bottomRight = box.localToGlobal(box.size.bottomRight(Point.origin));
    return new Rect.fromLTRB(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
  }

  void _removeHeroesFromOverlay() {
    for (OverlayEntry entry in _overlayEntries)
      entry.remove();
    _overlayEntries.clear();
  }

  OverlayEntry _addHeroToOverlay(WidgetBuilder hero, Object tag, OverlayState overlay) {
    OverlayEntry entry = new OverlayEntry(builder: hero);
    assert(_animation.status != AnimationStatus.dismissed && _animation.status != AnimationStatus.completed);
    if (_animation.status == AnimationStatus.forward)
      _to.insertHeroOverlayEntry(entry, tag, overlay);
    else
      _from.insertHeroOverlayEntry(entry, tag, overlay);
    _overlayEntries.add(entry);
    return entry;
  }

  void _updateQuest(Duration timeStamp) {
    if (navigator == null) {
      // The navigator was removed before this end-of-frame callback was called.
      return;
    }
    Map<Object, HeroHandle> heroesFrom = _party.isEmpty ?
        Hero.of(_from.subtreeContext) : _party.getHeroesToAnimate();

    Map<Object, HeroHandle> heroesTo = Hero.of(_to.subtreeContext);
    _to.offstage = false;

    Animation<double> animation = _animation; // The route's animation.
    Curve curve = Curves.fastOutSlowIn;
    if (animation.status == AnimationStatus.reverse) {
      animation = new ReverseAnimation(animation);
      curve = new Interval(animation.value, 1.0, curve: curve);
    }
    animation = new CurvedAnimation(parent: animation, curve: curve);

    _party.animate(heroesFrom, heroesTo, _getAnimationArea(navigator.context));
    _removeHeroesFromOverlay();
    _party.setAnimation(animation);

    for (_HeroQuestState hero in _party._heroes) {
      hero.overlayEntry = _addHeroToOverlay(
        (BuildContext context) => hero.build(navigator.context, animation),
        hero.tag,
        navigator.overlay
      );
    }
  }
}
