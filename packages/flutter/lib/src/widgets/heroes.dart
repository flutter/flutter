// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'framework.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'pages.dart';
import 'transitions.dart';

// Heroes are the parts of an application's screen-to-screen transitions where a
// component from one screen shifts to a position on the other. For example,
// album art from a list of albums growing to become the centerpiece of the
// album's details view. In this context, a screen is a navigator ModalRoute.

// To get this effect, all you have to do is wrap each hero on each route with a
// Hero widget, and give each hero a tag. Tag must either be unique within the
// current route's widget subtree, or all the Heroes with that tag on a
// particular route must have a key. When the app transitions from one route to
// another, each tag present is animated. When there's exactly one hero with
// that tag, that hero will be animated for that tag. When there are multiple
// heroes in a route with the same tag, then whichever hero has a key that
// matches one of the keys in the "most important key" list given to the
// navigator when the route was pushed will be animated. If a hero is only
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

final Object centerOfAttentionHeroTag = new Object();

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
  final RelativeRect currentRect;
  final double currentTurns;
}

abstract class HeroHandle {
  bool get alwaysAnimate;
  _HeroManifest _takeChild(Rect animationArea);
}

class Hero extends StatefulComponent {
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
  final Widget child;
  final int turns;

  /// If true, the hero will always animate, even if it has no matching hero to
  /// animate to or from. (This only applies if the hero is relevant; if there
  /// are multiple heroes with the same tag, only the one whose key matches the
  /// "most valuable keys" will be used.)
  final bool alwaysAnimate;

  static Map<Object, HeroHandle> of(BuildContext context, Set<Key> mostValuableKeys) {
    mostValuableKeys ??= new Set<Key>();
    assert(!mostValuableKeys.contains(null));
    // first we collect ALL the heroes, sorted by their tags
    Map<Object, Map<Key, HeroState>> heroes = <Object, Map<Key, HeroState>>{};
    void visitor(Element element) {
      if (element.widget is Hero) {
        StatefulComponentElement<Hero, HeroState> hero = element;
        Object tag = hero.widget.tag;
        assert(tag != null);
        Key key = hero.widget.key;
        final Map<Key, HeroState> tagHeroes = heroes.putIfAbsent(tag, () => <Key, HeroState>{});
        assert(() {
          if (tagHeroes.containsKey(key)) {
            debugPrint('Tag: $tag   Key: $key');
            assert(() {
              'There are multiple heroes that share the same key within the same subtree.               '
              'Within each subtree for which heroes are to be animated (typically a PageRoute subtree), '
              'either each Hero must have a unique tag, or, all the heroes with a particular tag must   '
              'have different keys. The relevant tag and key were dumped above.                         ';
              return false;
            });
          }
          return true;
        });
        tagHeroes[key] = hero.state;
      }
      element.visitChildren(visitor);
    }
    context.visitChildElements(visitor);
    // next, for each tag, we're going to decide on the one hero we care about for that tag
    Map<Object, HeroHandle> result = <Object, HeroHandle>{};
    for (Object tag in heroes.keys) {
      assert(tag != null);
      if (heroes[tag].length == 1) {
        result[tag] = heroes[tag].values.first;
      } else {
        assert(heroes[tag].length > 1);
        assert(!heroes[tag].containsKey(null));
        assert(heroes[tag].keys.where((Key key) => mostValuableKeys.contains(key)).length <= 1);
        Key mostValuableKey = mostValuableKeys.firstWhere((Key key) => heroes[tag].containsKey(key), orElse: () => null);
        if (mostValuableKey != null)
          result[tag] = heroes[tag][mostValuableKey];
      }
    }
    assert(!result.containsKey(null));
    return result;
  }

  HeroState createState() => new HeroState();
}

enum _HeroMode { constructing, initialized, measured, taken }

class HeroState extends State<Hero> implements HeroHandle {

  void initState() {
    assert(_mode == _HeroMode.constructing);
    super.initState();
    _key = new GlobalKey();
    _mode = _HeroMode.initialized;
  }

  GlobalKey _key;

  _HeroMode _mode = _HeroMode.constructing;
  Size _size;

  bool get alwaysAnimate => config.alwaysAnimate;

  _HeroManifest _takeChild(Rect animationArea) {
    assert(_mode == _HeroMode.measured || _mode == _HeroMode.taken);
    final RenderBox renderObject = context.findRenderObject();
    final Point heroTopLeft = renderObject.localToGlobal(Point.origin);
    final Point heroBottomRight = renderObject.localToGlobal(renderObject.size.bottomRight(Point.origin));
    final Rect heroArea = new Rect.fromLTRB(heroTopLeft.x, heroTopLeft.y, heroBottomRight.x, heroBottomRight.y);
    final RelativeRect startRect = new RelativeRect.fromRect(heroArea, animationArea);
    _HeroManifest result = new _HeroManifest(
      key: _key,
      config: config,
      sourceStates: new Set<HeroState>.from(<HeroState>[this]),
      currentRect: startRect,
      currentTurns: config.turns.toDouble()
    );
    setState(() {
      _key = null;
      _mode = _HeroMode.taken;
    });
    return result;
  }

  void _setChild(GlobalKey value) {
    assert(_mode == _HeroMode.taken);
    assert(_key == null);
    assert(_size != null);
    if (mounted)
      setState(() { _key = value; });
    _size = null;
    _mode = _HeroMode.initialized;
  }

  void _resetChild() {
    assert(_mode == _HeroMode.taken);
    assert(_key == null);
    assert(_size != null);
    if (mounted)
      setState(() { _key = new GlobalKey(); });
    _size = null;
    _mode = _HeroMode.initialized;
  }

  Widget build(BuildContext context) {
    switch (_mode) {
      case _HeroMode.constructing:
        assert(false);
        return null;
      case _HeroMode.initialized:
      case _HeroMode.measured:
        return new SizeObserver(
          onSizeChanged: (Size size) {
            assert(_mode == _HeroMode.initialized || _mode == _HeroMode.measured);
            _size = size;
            _mode = _HeroMode.measured;
          },
          child: new KeyedSubtree(
            key: _key,
            child: config.child
          )
        );
      case _HeroMode.taken:
        return new SizedBox(width: _size.width, height: _size.height);
    }
  }

}


class _HeroQuestState implements HeroHandle {
  _HeroQuestState({
    this.tag,
    this.key,
    this.child,
    this.sourceStates,
    this.targetRect,
    this.targetTurns,
    this.targetState,
    this.currentRect,
    this.currentTurns
  }) {
    assert(tag != null);
  }

  final Object tag;
  final GlobalKey key;
  final Widget child;
  final Set<HeroState> sourceStates;
  final RelativeRect targetRect;
  final int targetTurns;
  final HeroState targetState;
  final AnimatedRelativeRectValue currentRect;
  final AnimatedValue<double> currentTurns;

  bool get alwaysAnimate => true;

  bool get taken => _taken;
  bool _taken = false;
  _HeroManifest _takeChild(Rect animationArea) {
    assert(!taken);
    _taken = true;
    Set<HeroState> states = sourceStates;
    if (targetState != null)
      states = states.union(new Set<HeroState>.from(<HeroState>[targetState]));
    return new _HeroManifest(
      key: key,
      config: child,
      sourceStates: states,
      currentRect: currentRect.value,
      currentTurns: currentTurns.value
    );
  }

  Widget build(BuildContext context, PerformanceView performance) {
    return new PositionedTransition(
      rect: currentRect,
      performance: performance,
      child: new RotationTransition(
        turns: currentTurns,
        performance: performance,
        child: new KeyedSubtree(
          key: key,
          child: child
        )
      )
    );
  }
}

class _HeroMatch {
  const _HeroMatch(this.from, this.to, this.tag);
  final HeroHandle from;
  final HeroHandle to;
  final Object tag;
}

class HeroParty {
  HeroParty({ this.onQuestFinished });

  final VoidCallback onQuestFinished;

  List<_HeroQuestState> _heroes = <_HeroQuestState>[];
  bool get isEmpty => _heroes.isEmpty;

  Map<Object, HeroHandle> getHeroesToAnimate() {
    Map<Object, HeroHandle> result = new Map<Object, HeroHandle>();
    for (_HeroQuestState hero in _heroes)
      result[hero.tag] = hero;
    assert(!result.containsKey(null));
    return result;
  }

  AnimatedRelativeRectValue createAnimatedRelativeRect(RelativeRect begin, RelativeRect end, Curve curve) {
    return new AnimatedRelativeRectValue(begin, end: end, curve: curve);
  }

  AnimatedValue<double> createAnimatedTurns(double begin, double end, Curve curve) {
    assert(end.floor() == end);
    return new AnimatedValue<double>(begin, end: end, curve: curve);
  }

  void animate(Map<Object, HeroHandle> heroesFrom, Map<Object, HeroHandle> heroesTo, Rect animationArea, Curve curve) {
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
      _HeroManifest from = heroPair.from?._takeChild(animationArea);
      assert(heroPair.to == null || heroPair.to is HeroState);
      _HeroManifest to = heroPair.to?._takeChild(animationArea);
      assert(from != null || to != null);
      assert(to == null || to.sourceStates.length == 1);
      assert(to == null || to.currentTurns.floor() == to.currentTurns);
      HeroState targetState = to != null ? to.sourceStates.elementAt(0) : null;
      Set<HeroState> sourceStates = from != null ? from.sourceStates : new Set<HeroState>();
      sourceStates.remove(targetState);
      RelativeRect sourceRect = from != null ? from.currentRect :
        new RelativeRect.fromRect(to.currentRect.toRect(animationArea).center & Size.zero, animationArea);
      RelativeRect targetRect = to != null ? to.currentRect :
        new RelativeRect.fromRect(from.currentRect.toRect(animationArea).center & Size.zero, animationArea);
      double sourceTurns = from != null ? from.currentTurns : 0.0;
      double targetTurns = to != null ? to.currentTurns : 0.0;
      _newHeroes.add(new _HeroQuestState(
        tag: heroPair.tag,
        key: from != null ? from.key : to.key,
        child: to != null ? to.config : from.config,
        sourceStates: sourceStates,
        targetRect: targetRect,
        targetTurns: targetTurns.floor(),
        targetState: targetState,
        currentRect: createAnimatedRelativeRect(sourceRect, targetRect, curve),
        currentTurns: createAnimatedTurns(sourceTurns, targetTurns, curve)
      ));
    }

    assert(!_heroes.any((_HeroQuestState hero) => !hero.taken));
    _heroes = _newHeroes;
  }

  PerformanceView _currentPerformance;

  void _clearCurrentPerformance() {
    _currentPerformance?.removeStatusListener(_handleUpdate);
    _currentPerformance = null;
  }

  void setPerformance(PerformanceView performance) {
    assert(performance != null || _heroes.length == 0);
    if (performance != _currentPerformance) {
      _clearCurrentPerformance();
      _currentPerformance = performance;
      _currentPerformance?.addStatusListener(_handleUpdate);
    }
  }

  void _handleUpdate(PerformanceStatus status) {
    if (status == PerformanceStatus.completed ||
        status == PerformanceStatus.dismissed) {
      for (_HeroQuestState hero in _heroes) {
        if (hero.targetState != null)
          hero.targetState._setChild(hero.key);
        for (HeroState source in hero.sourceStates)
          source._resetChild();
      }
      _heroes.clear();
      _clearCurrentPerformance();
      if (onQuestFinished != null)
        onQuestFinished();
    }
  }

  String toString() => '$_heroes';
}

class HeroController extends NavigatorObserver {
  HeroController() {
    _party = new HeroParty(onQuestFinished: _handleQuestFinished);
  }

  HeroParty _party;
  PerformanceView _performance;
  PageRoute _from;
  PageRoute _to;

  final List<OverlayEntry> _overlayEntries = new List<OverlayEntry>();

  void didPush(Route route, Route previousRoute) {
    assert(navigator != null);
    assert(route != null);
    if (route is PageRoute) {
      assert(route.performance != null);
      if (previousRoute is PageRoute) // could be null
        _from = previousRoute;
      _to = route;
      _performance = route.performance;
      _checkForHeroQuest();
    }
  }

  void didPop(Route route, Route previousRoute) {
    assert(navigator != null);
    assert(route != null);
    if (route is PageRoute) {
      assert(route.performance != null);
      if (previousRoute is PageRoute) {
        _to = previousRoute;
        _from = route;
        _performance = route.performance;
        _checkForHeroQuest();
      }
    }
  }

  void _checkForHeroQuest() {
    if (_from != null && _to != null && _from != _to) {
      _to.offstage = _to.performance.status != PerformanceStatus.completed;
      scheduler.addPostFrameCallback(_updateQuest);
    }
  }

  void _handleQuestFinished() {
    _removeHeroesFromOverlay();
    _from = null;
    _to = null;
    _performance = null;
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

  void _addHeroToOverlay(Widget hero, Object tag, OverlayState overlay) {
    OverlayEntry entry = new OverlayEntry(builder: (_) => hero);
    if (_performance.direction == AnimationDirection.forward)
      _to.insertHeroOverlayEntry(entry, tag, overlay);
    else
      _from.insertHeroOverlayEntry(entry, tag, overlay);
    _overlayEntries.add(entry);
  }

  Set<Key> _getMostValuableKeys() {
    assert(_from != null);
    assert(_to != null);
    Set<Key> result = new Set<Key>();
    if (_from.settings.mostValuableKeys != null)
      result.addAll(_from.settings.mostValuableKeys);
    if (_to.settings.mostValuableKeys != null)
      result.addAll(_to.settings.mostValuableKeys);
    return result;
  }

  void _updateQuest(Duration timeStamp) {
    Set<Key> mostValuableKeys = _getMostValuableKeys();
    Map<Object, HeroHandle> heroesFrom = _party.isEmpty ?
        Hero.of(_from.subtreeContext, mostValuableKeys) : _party.getHeroesToAnimate();

    Map<Object, HeroHandle> heroesTo = Hero.of(_to.subtreeContext, mostValuableKeys);
    _to.offstage = false;

    PerformanceView performance = _performance;
    Curve curve = Curves.ease;
    if (performance.status == PerformanceStatus.reverse) {
      performance = new ReversePerformance(performance);
      curve = new Interval(performance.progress, 1.0, curve: curve);
    }

    _party.animate(heroesFrom, heroesTo, _getAnimationArea(navigator.context), curve);
    _removeHeroesFromOverlay();
    _party.setPerformance(performance);
    for (_HeroQuestState hero in _party._heroes) {
      Widget widget = hero.build(navigator.context, performance);
      _addHeroToOverlay(widget, hero.tag, navigator.overlay);
    }
  }
}
