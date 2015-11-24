// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'heroes.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'routes.dart';

class HeroController extends NavigatorObserver {
  HeroController() {
    _party = new HeroParty(onQuestFinished: _handleQuestFinished);
  }

  HeroParty _party;
  PerformanceView _performance;
  ModalRoute _from;
  ModalRoute _to;

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
      scheduler.requestPostFrameCallback(_updateQuest);
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

  void _addHeroesToOverlay(Iterable<Widget> heroes, OverlayState overlay) {
    for (Widget hero in heroes) {
      OverlayEntry entry = new OverlayEntry(builder: (_) => hero);
      overlay.insert(entry);
      _overlayEntries.add(entry);
    }
  }

  Set<Key> _getMostValuableKeys() {
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
    Iterable<Widget> heroes = _party.getWidgets(navigator.context, performance);
    _addHeroesToOverlay(heroes, navigator.overlay);
  }
}
