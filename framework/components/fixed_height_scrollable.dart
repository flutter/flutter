// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/scroll_curve.dart';
import '../fn.dart';
import 'dart:math' as math;
import 'dart:sky' as sky;
import 'scrollable.dart';

abstract class FixedHeightScrollable extends Scrollable {
  // TODO(rafaelw): This component really shouldn't have an opinion
  // about how it is sized. The owning component should decide whether
  // it's explicitly sized or flexible or whatever...
  static final Style _style = new Style('''
    overflow: hidden;
    position: relative;
    flex: 1;
    will-change: transform;'''
  );

  static final Style _scrollAreaStyle = new Style('''
    position:relative;
    will-change: transform;'''
  );

  double _height = 0.0;
  double _itemHeight;

  FixedHeightScrollable({
    Object key,
    ScrollCurve scrollCurve
  }) : super(key: key, scrollCurve: scrollCurve);

  void didMount() {
    super.didMount();
    var root = getRoot();
    var item = root.firstChild.firstChild;
    sky.ClientRect scrollRect = root.getBoundingClientRect();
    sky.ClientRect itemRect = item.getBoundingClientRect();
    assert(scrollRect.height > 0);
    assert(itemRect.height > 0);

    setState(() {
      _height = scrollRect.height;
      _itemHeight = itemRect.height;
    });
  }

  Node build() {
    var itemNumber = 0;
    var drawCount = 1;
    var transformStyle = '';

    if (_height > 0.0) {
      if (scrollOffset < 0.0) {
        double visibleHeight = _height + scrollOffset;
        drawCount = (visibleHeight / _itemHeight).round() + 1;
        transformStyle =
          'transform: translateY(${(-scrollOffset).toStringAsFixed(2)}px)';
      } else {
        drawCount = (_height / _itemHeight).round() + 1;
        double alignmentOffset = math.max(0.0, scrollOffset);
        double alignmentDelta = -scrollOffset % _itemHeight;
        if (alignmentDelta != 0.0)
          alignmentDelta -= _itemHeight;

        double drawStart = scrollOffset + alignmentDelta;
        itemNumber = (drawStart / _itemHeight).floor();

        transformStyle =
            'transform: translateY(${(alignmentDelta).toStringAsFixed(2)}px)';
      }
    }

    return new Container(
      styles: [_style],
      children: [
        new Container(
          styles: [_scrollAreaStyle],
          inlineStyle: transformStyle,
          children: buildItems(itemNumber, drawCount)
        )
      ]
    );
  }
}
