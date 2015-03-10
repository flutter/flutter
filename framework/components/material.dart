// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import 'dart:sky' as sky;
import 'dart:collection';
import 'ink_splash.dart';

abstract class Material extends Component {
  static const _splashesKey = const Object();

  static final Style _style = new Style('''
    transform: translateX(0);
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0'''
  );

  LinkedHashSet<SplashAnimation> _splashes;

  Material({ Object key }) : super(key: key) {
    events.listen('gesturescrollstart', _cancelSplashes);
    events.listen('wheel', _cancelSplashes);
    events.listen('pointerdown', _startSplash);
  }

  Node build() {
    List<Node> children = [];

    if (_splashes != null) {
      children.addAll(_splashes.map((s) => new InkSplash(s.onStyleChanged)));
    }

    return new Container(
      style: _style,
      children: children,
      key: _splashesKey
    );
  }

  sky.ClientRect _getBoundingRect() => (getRoot() as sky.Element).getBoundingClientRect();

  void _startSplash(sky.PointerEvent event) {
    setState(() {
      if (_splashes == null) {
        _splashes = new LinkedHashSet<SplashAnimation>();
      }

      var splash;
      splash = new SplashAnimation(_getBoundingRect(), event.x, event.y,
                                   onDone: () { _splashDone(splash); });

      _splashes.add(splash);
    });
  }

  void _cancelSplashes(sky.Event event) {
    if (_splashes == null) {
      return;
    }

    setState(() {
      var splashes = _splashes;
      _splashes = null;
      splashes.forEach((s) { s.cancel(); });
    });
  }

  void didUnmount() {
    _cancelSplashes(null);
  }

  void _splashDone(SplashAnimation splash) {
    if (_splashes == null) {
      return;
    }

    setState(() {
      _splashes.remove(splash);
      if (_splashes.length == 0) {
        _splashes = null;
      }
    });
  }
}
