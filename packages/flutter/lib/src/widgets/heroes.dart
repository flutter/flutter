// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

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
  _HeroManifest _takeChild(Rect animationArea, Animation<double> currentAnimation);
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
  /// animate to or from. (This only applies if the hero is relevant; if there
  /// are multiple heroes with the same tag, only the one whose key matches the
  /// "most valuable keys" will be used.)
  final bool alwaysAnimate;

  static Map<Object, HeroHandle> of(BuildContext context, Set<Key> mostValuableKeys) {
    mostValuableKeys ??= new HashSet<Key>();
    assert(!mostValuableKeys.contains(null));
    // first we collect ALL the heroes, sorted by their tags
    Map<Object, Map<Key, HeroState>> heroes = <Object, Map<Key, HeroState>>{};
    void visitor(Element element) {
      if (element.widget is Hero) {
        StatefulElement hero = element;
        Hero heroWidget = element.widget;
        Object tag = heroWidget.tag;
        assert(tag != null);
        Key key = heroWidget.key;
        final Map<Key, HeroState> tagHeroes = heroes.putIfAbsent(tag, () => <Key, HeroState>{});
        assert(() {
          if (tagHeroes.containsKey(key)) {
            new FlutterError(
              'There are multiple heroes that share the same key within the same subtree.\n'
              'Within each subtree for which heroes are to be animated (typically a PageRoute subtree), '
              'either each Hero must have a unique tag, or, all the heroes with a particular tag must '
              'have different keys.\n'
              'In this case, the tag "$tag" had multiple heroes with the key "$key".'
            );
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

  @override
  HeroState createState() => new HeroState();
}

class HeroState extends State<Hero> implements HeroHandle {

  GlobalKey _key = new GlobalKey();
  Size _placeholderSize;

  @override
  bool get alwaysAnimate => config.alwaysAnimate;

  @override
  _HeroManifest _takeChild(Rect animationArea, Animation<double> currentAnimation) {
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
    final RelativeRect startRect = new RelativeRect.fromRect(heroArea, animationArea);
    _HeroManifest result = new _HeroManifest(
      key: _key, // might be null, e.g. if the hero is returning to us
      config: config,
      sourceStates: new HashSet<HeroState>.from(<HeroState>[this]),
      currentRect: startRect,
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
  final RelativeRectTween currentRect;
  final Tween<double> currentTurns;

  @override
  bool get alwaysAnimate => true;

  bool get taken => _taken;
  bool _taken = false;

  @override
  _HeroManifest _takeChild(Rect animationArea, Animation<double> currentAnimation) {
    assert(!taken);
    _taken = true;
    Set<HeroState> states = sourceStates;
    if (targetState != null)
      states = states.union(new HashSet<HeroState>.from(<HeroState>[targetState]));
    return new _HeroManifest(
      key: key,
      config: child,
      sourceStates: states,
      currentRect: currentRect.evaluate(currentAnimation),
      currentTurns: currentTurns.evaluate(currentAnimation)
    );
  }

  Widget build(BuildContext context, Animation<double> animation) {
    return new PositionedTransition(
      rect: currentRect.animate(animation),
      child: new RotationTransition(
        turns: currentTurns.animate(animation),
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

  RelativeRectTween createRectTween(RelativeRect begin, RelativeRect end) {
    return new RelativeRectTween(begin: begin, end: end);
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
      _HeroManifest from = heroPair.from?._takeChild(animationArea, _currentAnimation);
      assert(heroPair.to == null || heroPair.to is HeroState);
      _HeroManifest to = heroPair.to?._takeChild(animationArea, _currentAnimation);
      assert(from != null || to != null);
      assert(to == null || to.sourceStates.length == 1);
      assert(to == null || to.currentTurns.floor() == to.currentTurns);
      HeroState targetState = to != null ? to.sourceStates.elementAt(0) : null;
      Set<HeroState> sourceStates = from != null ? from.sourceStates : new HashSet<HeroState>();
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
        currentRect: createRectTween(sourceRect, targetRect),
        currentTurns: createTurnsTween(sourceTurns, targetTurns)
      ));
    }

    assert(!_heroes.any((_HeroQuestState hero) => !hero.taken));
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
  HeroController() {
    _party = new HeroParty(onQuestFinished: _handleQuestFinished);
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

  void _checkForHeroQuest() {
    if (_from != null && _to != null && _from != _to) {
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

  void _addHeroToOverlay(Widget hero, Object tag, OverlayState overlay) {
    OverlayEntry entry = new OverlayEntry(builder: (_) => hero);
    assert(_animation.status != AnimationStatus.dismissed && _animation.status != AnimationStatus.completed);
    if (_animation.status == AnimationStatus.forward)
      _to.insertHeroOverlayEntry(entry, tag, overlay);
    else
      _from.insertHeroOverlayEntry(entry, tag, overlay);
    _overlayEntries.add(entry);
  }

  Set<Key> _getMostValuableKeys() {
    assert(_from != null);
    assert(_to != null);
    Set<Key> result = new HashSet<Key>();
    if (_from.settings.mostValuableKeys != null)
      result.addAll(_from.settings.mostValuableKeys);
    if (_to.settings.mostValuableKeys != null)
      result.addAll(_to.settings.mostValuableKeys);
    return result;
  }

  void _updateQuest(Duration timeStamp) {
    if (navigator == null) {
      // The navigator has been removed for this end-of-frame callback was called.
      return;
    }
    Set<Key> mostValuableKeys = _getMostValuableKeys();
    Map<Object, HeroHandle> heroesFrom = _party.isEmpty ?
        Hero.of(_from.subtreeContext, mostValuableKeys) : _party.getHeroesToAnimate();

    Map<Object, HeroHandle> heroesTo = Hero.of(_to.subtreeContext, mostValuableKeys);
    _to.offstage = false;

    Animation<double> animation = _animation;
    Curve curve = Curves.ease;
    if (animation.status == AnimationStatus.reverse) {
      animation = new ReverseAnimation(animation);
      curve = new Interval(animation.value, 1.0, curve: curve);
    }

    _party.animate(heroesFrom, heroesTo, _getAnimationArea(navigator.context));
    _removeHeroesFromOverlay();
    _party.setAnimation(new CurvedAnimation(
      parent: animation,
      curve: curve
    ));
    for (_HeroQuestState hero in _party._heroes) {
      Widget widget = hero.build(navigator.context, animation);
      _addHeroToOverlay(widget, hero.tag, navigator.overlay);
    }
  }
}
