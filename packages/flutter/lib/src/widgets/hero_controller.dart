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
import 'page.dart';

class HeroPageRoute extends PageRoute {
  HeroPageRoute({
    WidgetBuilder builder,
    NamedRouteSettings settings: const NamedRouteSettings(),
    this.heroController
  }) : super(builder: builder, settings: settings);

  final HeroController heroController;

  void didMakeCurrent() {
    heroController?.didMakeCurrent(this);
  }
}

class HeroController {
  HeroController() {
    _party = new HeroParty(onQuestFinished: _handleQuestFinished);
  }

  HeroParty _party;
  HeroPageRoute _from;
  HeroPageRoute _to;

  final List<OverlayEntry> _overlayEntries = new List<OverlayEntry>();

  void didMakeCurrent(PageRoute current) {
    assert(current != null);
    assert(current.performance != null);
    if (_from == null) {
      _from = current;
      return;
    }
    _to = current;
    if (_from != _to) {
      current.offstage = current.performance.status != PerformanceStatus.completed;
      scheduler.requestPostFrameCallback(_updateQuest);
    }
  }

  void _handleQuestFinished() {
    _removeHeroesFromOverlay();
    _from = _to;
    _to = null;
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
      OverlayEntry entry = new OverlayEntry(child: hero);
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
        Hero.of(_from.pageKey.currentContext, mostValuableKeys) : _party.getHeroesToAnimate();

    BuildContext context = _to.pageKey.currentContext;
    Map<Object, HeroHandle> heroesTo = Hero.of(context, mostValuableKeys);
    _to.offstage = false;

    PerformanceView performance = _to.performance;
    Curve curve = Curves.ease;
    if (performance.status == PerformanceStatus.reverse) {
      performance = new ReversePerformance(performance);
      curve = new Interval(performance.progress, 1.0, curve: curve);
    }

    NavigatorState navigator = Navigator.of(context);
    _party.animate(heroesFrom, heroesTo, _getAnimationArea(navigator.context), curve);
    _removeHeroesFromOverlay();
    Iterable<Widget> heroes = _party.getWidgets(navigator.context, performance);
    _addHeroesToOverlay(heroes, navigator.overlay);
  }
}
