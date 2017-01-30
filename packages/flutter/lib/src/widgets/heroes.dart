// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'pages.dart';
import 'transitions.dart';

// TODO(ianh): Make the appear/disappear animations pretty. Right now they're
// pretty crude (just rotate and shrink the constraints). They should probably
// involve actually scaling and fading, at a minimum.

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
  final Set<_HeroState> sourceStates;
  final Rect currentRect;
  final double currentTurns;
}

abstract class _HeroHandle {
  bool get alwaysAnimate;
  _HeroManifest _takeChild(Animation<double> currentAnimation);
}

/// A widget that marks its child as being a candidate for hero animations.
///
/// During a page transition (see [Navigator]), if a particular feature (e.g. a
/// picture or heading) appears on both pages, it can be helpful for orienting
/// the user if the feature appears to physically move from one page to the
/// other. Such an animation is called a *hero animation*.
///
/// To label a widget as such a feature, wrap it in a [Hero] widget. When a
/// navigation happens, the [Hero] widgets on each page are collected up. For
/// each pair of [Hero] widgets that have the same tag, a hero animation is
/// triggered.
///
/// Hero animations are managed by a [HeroController].
///
/// If a [Hero] is already in flight when another navigation occurs, then it
/// will continue to the next page.
///
/// A particular page must not have more than one [Hero] for each [tag].
///
/// ## Discussion
///
/// Heroes are the parts of an application's screen-to-screen transitions where
/// a widget from one screen shifts to a position on the other. For example,
/// album art from a list of albums growing to become the centerpiece of the
/// album's details view. In this context, a screen is a [ModalRoute] in a
/// [Navigator].
///
/// To get this effect, all you have to do is wrap each hero on each route with
/// a [Hero] widget, and give each hero a [tag]. The tag must be unique within
/// the current route's widget subtree, and must match the tag of a [Hero] in
/// the target route. When the app transitions from one route to another, each
/// hero is animated to its new location.
///
/// Heroes and the [Navigator]'s [Overlay]'s [Stack] must be axis-aligned for
/// all this to work. The top left and bottom right coordinates of each animated
/// [Hero] will be converted to global coordinates and then from there converted
/// to that [Stack]'s coordinate space, and the entire Hero subtree will, for
/// the duration of the animation, be lifted out of its original place, and
/// positioned on that stack. If the [Hero] isn't axis aligned, this is going to
/// fail in a rather ugly fashion. Don't rotate your heroes!
///
/// To make the animations look good, it's critical that the widget tree for the
/// hero in both locations be essentially identical. The widget of the *target*
/// is used to do the transition: when going from route A to route B, route B's
/// hero's widget is placed over route A's hero's widget, and route A's hero is
/// hidden. Then the widget is animated to route B's hero's position, and then
/// the widget is inserted into route B. When going back from B to A, route A's
/// hero's widget is placed over where route B's hero's widget was, and then the
/// animation goes the other way.
class Hero extends StatefulWidget {
  /// Create a hero.
  ///
  /// The [tag] and [child] are required.
  Hero({
    Key key,
    @required this.tag,
    this.turns: 1,
    this.alwaysAnimate: false,
    @required this.child,
  }) : super(key: key) {
    assert(tag != null);
    assert(turns != null);
    assert(alwaysAnimate != null);
    assert(child != null);
  }

  /// The identifier for this particular hero. If the tag of this hero matches
  /// the tag of a hero on the other page during a page transition, then a hero
  /// animation will be triggered.
  final Object tag;

  /// The relative number of full rotations that the hero is conceptually at.
  ///
  /// If a hero is animated from a [Hero] with [turns] set to 1 to a [Hero] with
  /// [turns] set to 2, then it will turn by one full rotation during its
  /// animation. Normally, all heroes have a [turns] value of 1.
  final int turns;

  /// If true, the hero will always animate, even if it has no matching hero to
  /// animate to or from. If it has no target, it will imply a target at the
  /// same position with zero width and height and with [turns] set to zero.
  /// This will typically cause it to shrink and spin.
  final bool alwaysAnimate;

  /// The widget below this widget in the tree.
  ///
  /// This subtree should match the appearance of the subtrees of any other
  /// heroes in the application with the same [tag].
  final Widget child;

  /// Return a hero tag to _HeroState map of all of the heroes within the given subtree.
  static Map<Object, _HeroHandle> _of(BuildContext context) {
    final Map<Object, _HeroHandle> result = <Object, _HeroHandle>{};
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
        _HeroState heroState = hero.state;
        result[tag] = heroState;
      }
      element.visitChildren(visitor);
    }
    context.visitChildElements(visitor);
    return result;
  }

  @override
  _HeroState createState() => new _HeroState();
}

class _HeroState extends State<Hero> implements _HeroHandle {
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
    assert(!renderObject.debugNeedsLayout);
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
      sourceStates: new HashSet<_HeroState>.from(<_HeroState>[this]),
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
    assert(value != null);
    assert(mounted);
    setState(() {
      _key = value;
      _placeholderSize = null;
    });
  }

  void _resetChild() {
    if (mounted)
      _setChild(new GlobalKey());
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


class _HeroQuestState implements _HeroHandle {
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
    for (_HeroState state in sourceStates)
      state._disposeCallback = () => sourceStates.remove(state);
    if (targetState != null)
      targetState._disposeCallback = _handleTargetStateDispose;
  }

  final Object tag;
  final GlobalKey key;
  final Widget child;
  final Set<_HeroState> sourceStates;
  final Rect animationArea;
  Rect targetRect;
  int targetTurns;
  _HeroState targetState;
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
    Set<_HeroState> states = sourceStates;
    if (targetState != null)
      states = states.union(new HashSet<_HeroState>.from(<_HeroState>[targetState]));
    for (_HeroState state in states)
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
    for (_HeroState state in sourceStates)
      state._disposeCallback = null;
    if (targetState != null)
      targetState._disposeCallback = null;
  }
}

class _HeroMatch {
  const _HeroMatch(this.from, this.to, this.tag);
  final _HeroHandle from;
  final _HeroHandle to;
  final Object tag;
}

/// Signature for a function that takes two [Rect] instances and returns a
/// [RectTween] that transitions between them.
///
/// This is typically used with a [HeroController] to provide an animation for
/// [Hero] positions that looks nicer than a linear movement. For example, see
/// [MaterialRectArcTween].
typedef RectTween CreateRectTween(Rect begin, Rect end);

class _HeroParty {
  _HeroParty({ this.onQuestFinished, this.createRectTween });

  final VoidCallback onQuestFinished;
  final CreateRectTween createRectTween;

  List<_HeroQuestState> _heroes = <_HeroQuestState>[];
  bool get isEmpty => _heroes.isEmpty;

  Map<Object, _HeroHandle> getHeroesToAnimate() {
    Map<Object, _HeroHandle> result = new Map<Object, _HeroHandle>();
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

  void animate(Map<Object, _HeroHandle> heroesFrom, Map<Object, _HeroHandle> heroesTo, Rect animationArea) {
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
      assert(heroPair.to == null || heroPair.to is _HeroState);
      _HeroManifest to = heroPair.to?._takeChild(_currentAnimation);
      assert(from != null || to != null);
      assert(to == null || to.sourceStates.length == 1);
      assert(to == null || to.currentTurns.floor() == to.currentTurns);
      _HeroState targetState = to != null ? to.sourceStates.elementAt(0) : null;
      Set<_HeroState> sourceStates = from?.sourceStates ?? new HashSet<_HeroState>();
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
    assert(animation != null || _heroes.isEmpty);
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
        for (_HeroState source in hero.sourceStates)
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

/// A [Navigator] observer that manages [Hero] transitions.
///
/// An instance of [HeroController] should be used as the [Navigator.observer].
/// This is done automatically by [MaterialApp].
class HeroController extends NavigatorObserver {
  /// Creates a hero controller with the given [RectTween] constructor if any.
  ///
  /// The [createRectTween] argument is optional. By default, a linear
  /// [RectTween] is used.
  HeroController({ CreateRectTween createRectTween }) {
    _party = new _HeroParty(
      onQuestFinished: _handleQuestFinished,
      createRectTween: createRectTween
    );
  }

  // The current party, if they're on a quest.
  _HeroParty _party;

  // The settings used to prepare the next quest.
  // These members are only non-null between the didPush/didPop call and the
  // corresponding _updateQuest call.
  PageRoute<dynamic> _from;
  PageRoute<dynamic> _to;
  Animation<double> _animation;

  final List<OverlayEntry> _overlayEntries = new List<OverlayEntry>();

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    assert(navigator != null);
    assert(route != null);
    if (_questsEnabled && route is PageRoute<dynamic>) {
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
    if (_questsEnabled && route is PageRoute<dynamic>) {
      assert(route.animation != null);
      if (route.animation.status != AnimationStatus.dismissed && previousRoute is PageRoute<dynamic>) {
        _from = route;
        _to = previousRoute;
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
    assert(_questsEnabled);
    if (_from != null && _to != null && _from != _to) {
      assert(_animation != null);
      _to.offstage = _to.animation.status != AnimationStatus.completed;
      _questsEnabled = false;
      WidgetsBinding.instance.addPostFrameCallback(_updateQuest);
    } else {
      // this isn't a valid quest
      _clearPendingHeroQuest();
    }
  }

  void _handleQuestFinished() {
    _removeHeroesFromOverlay();
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
    assert(!_questsEnabled);
    if (navigator == null) {
      // The navigator was removed before this end-of-frame callback was called.
      _clearPendingHeroQuest();
      return;
    }
    assert(_from.subtreeContext != null);
    assert(_to.subtreeContext != null);
    Map<Object, _HeroHandle> heroesFrom = _party.isEmpty ?
        Hero._of(_from.subtreeContext) : _party.getHeroesToAnimate();

    Map<Object, _HeroHandle> heroesTo = Hero._of(_to.subtreeContext);
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

    _clearPendingHeroQuest();
  }

  void _clearPendingHeroQuest() {
    _from = null;
    _to = null;
    _animation = null;
    _questsEnabled = true;
  }
}
