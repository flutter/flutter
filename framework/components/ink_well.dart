// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import 'dart:collection';
import 'dart:sky' as sky;
import 'ink_splash.dart';

class InkWell extends Component {
  LinkedHashSet<SplashController> _splashes;

  Style style;
  String inlineStyle;
  List<Node> children;

  InkWell({ Object key, this.style, this.inlineStyle, this.children })
      : super(key: key) {
    onDidUnmount(() {
      _cancelSplashes(null);
    });
  }

  Node build() {
    List<Node> childrenIncludingSplashes = [];

    if (_splashes != null) {
      childrenIncludingSplashes.addAll(
          _splashes.map((s) => new InkSplash(s.onStyleChanged)));
    }

    if (children != null)
      childrenIncludingSplashes.addAll(children);

    return new EventTarget(
      new Container(
          style: style,
          inlineStyle: inlineStyle,
          children: childrenIncludingSplashes),
      onGestureTapDown: _startSplash,
      onGestureTap: _confirmSplash
    );
  }

  sky.ClientRect _getBoundingRect() => (getRoot() as sky.Element).getBoundingClientRect();

  void _startSplash(sky.GestureEvent event) {
    setState(() {
      if (_splashes == null)
        _splashes = new LinkedHashSet<SplashController>();
      var splash;
      splash = new SplashController(_getBoundingRect(), event.x, event.y,
                                    pointer: event.primaryPointer,
                                    onDone: () { _splashDone(splash); });
      _splashes.add(splash);
    });
  }

  void _confirmSplash(sky.GestureEvent event) {
    if (_splashes == null)
      return;
    _splashes.where((splash) => splash.pointer == event.primaryPointer)
             .forEach((splash) { splash.confirm(); });
  }

  void _cancelSplashes(sky.Event event) {
    if (_splashes == null)
      return;
    setState(() {
      var splashes = _splashes;
      _splashes = null;
      splashes.forEach((s) { s.cancel(); });
    });
  }

  void _splashDone(SplashController splash) {
    if (_splashes == null)
      return;
    setState(() {
      _splashes.remove(splash);
      if (_splashes.length == 0)
        _splashes = null;
    });
  }
}
