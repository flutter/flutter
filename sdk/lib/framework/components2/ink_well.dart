// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import '../rendering/flex.dart';
import 'dart:collection';
import 'dart:sky' as sky;
// import 'ink_splash.dart';
import 'scrollable.dart';

class InkWell extends Component implements ScrollClient {
  // static final Style _containmentStyleHack = new Style('''
  //   align-items: center;
  //   transform: translateX(0);''');

  // LinkedHashSet<SplashController> _splashes;

  List<UINode> children;

  // InkWell({ Object key, this.inlineStyle, this.children })
  //     : super(key: key) {
  //   onDidUnmount(() {
  //     _cancelSplashes(null);
  //   });
  // }

  InkWell({ Object key, this.children }) : super(key: key);

  UINode build() {
    return new FlexContainer(direction: FlexDirection.horizontal, children: children);
    // List<UINode> childrenIncludingSplashes = [];

    // if (_splashes != null) {
    //   childrenIncludingSplashes.addAll(
    //       _splashes.map((s) => new InkSplash(s.onStyleChanged)));
    // }

    // if (children != null)
    //   childrenIncludingSplashes.addAll(children);

    // return new EventListenerNode(
    //   new FlexContainer(
    //     direction: FlexDirection.horizontal,
    //     style: _containmentStyleHack,
    //     inlineStyle: inlineStyle,
    //     children: childrenIncludingSplashes),
    //   onGestureTapDown: _startSplash,
    //   onGestureTap: _confirmSplash
    // );
  }

  // void _startSplash(sky.GestureEvent event) {
  //   setState(() {
  //     if (_splashes == null)
  //       _splashes = new LinkedHashSet<SplashController>();
  //     var splash;
  //     var root = getRoot();
  //     splash = new SplashController(root.rect, event.x, event.y,
  //                                   pointer: event.primaryPointer,
  //                                   onDone: () { _splashDone(splash); });
  //     _splashes.add(splash);
  //     UINode node = parent;
  //     while (node != null) {
  //       if (node is Scrollable)
  //         node.registerScrollClient(this);
  //       node = node.parent;
  //     }
  //   });
  // }

  bool ancestorScrolled(Scrollable ancestor) {
  //   _abortSplashes();
    return false;
  }

  // void handleRemoved() {
  //   UINode node = parent;
  //   while (node != null) {
  //     if (node is Scrollable)
  //       node.unregisterScrollClient(this);
  //     node = node.parent;
  //   }
  //   super.handleRemoved();
  // }

  // void _confirmSplash(sky.GestureEvent event) {
  //   if (_splashes == null)
  //     return;
  //   _splashes.where((splash) => splash.pointer == event.primaryPointer)
  //            .forEach((splash) { splash.confirm(); });
  // }

  // void _abortSplashes() {
  //   if (_splashes == null)
  //     return;
  //   setState(() {
  //     _splashes.forEach((s) { s.abort(); });
  //   });
  // }

  // void _cancelSplashes(sky.Event event) {
  //   if (_splashes == null)
  //     return;
  //   setState(() {
  //     var splashes = _splashes;
  //     _splashes = null;
  //     splashes.forEach((s) { s.cancel(); });
  //   });
  // }

  // void _splashDone(SplashController splash) {
  //   if (_splashes == null)
  //     return;
  //   setState(() {
  //     _splashes.remove(splash);
  //     if (_splashes.length == 0)
  //       _splashes = null;
  //   });
  // }
}
