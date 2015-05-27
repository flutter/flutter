// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/scroll_behavior.dart';
import '../debug/tracing.dart';
import '../fn2.dart';
import 'dart:math' as math;
import 'dart:async';
import 'scrollable.dart';

abstract class FixedHeightScrollable extends Scrollable {
  static final Style _style = new Style('''
    overflow: hidden;
    position: relative;
    will-change: transform;'''
  );

  static final Style _scrollAreaStyle = new Style('''
    position:relative;
    will-change: transform;'''
  );

  FixedHeightScrollable({
    Object key
  }) : super(key: key);

  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  OverscrollBehavior get scrollBehavior => super.scrollBehavior as OverscrollBehavior;

  double _height = 0.0;
  double _itemHeight;

  int _itemCount = 0;
  int get itemCount => _itemCount;
  void set itemCount (int value) {
    if (_itemCount != value) {
      _itemCount = value;
      if (_itemHeight != null)
        scrollBehavior.contentsHeight = _itemHeight * _itemCount;
    }
  }

  void _measureHeights() {
    trace('FixedHeightScrollable::_measureHeights', () {
      if (_itemHeight != null)
        return;
      var root = getRoot();
      if (root == null)
        return;
      var item = root.firstChild.firstChild;
      if (item == null)
        return;
      setState(() {
        _height = root.height;
        assert(_height > 0);
        _itemHeight = item.height;
        assert(_itemHeight > 0);
        scrollBehavior.containerHeight = _height;
        scrollBehavior.contentsHeight = _itemHeight * _itemCount;
      });
    });
  }

  UINode buildContent() {
    var itemNumber = 0;
    var drawCount = 1;
    var transformStyle = '';

    if (_itemHeight == null)
      new Future.microtask(_measureHeights);

    if (_height > 0.0 && _itemHeight != null) {
      if (scrollOffset < 0.0) {
        double visibleHeight = _height + scrollOffset;
        drawCount = (visibleHeight / _itemHeight).round() + 1;
        transformStyle =
          'transform: translateY(${(-scrollOffset).toStringAsFixed(2)}px)';
      } else {
        drawCount = (_height / _itemHeight).ceil() + 1;
        double alignmentDelta = -scrollOffset % _itemHeight;
        if (alignmentDelta != 0.0)
          alignmentDelta -= _itemHeight;

        double drawStart = scrollOffset + alignmentDelta;
        itemNumber = math.max(0, (drawStart / _itemHeight).floor());

        transformStyle =
            'transform: translateY(${(alignmentDelta).toStringAsFixed(2)}px)';
      }
    }

    return new Container(
      style: _style,
      children: [
        new Container(
          style: _scrollAreaStyle,
          inlineStyle: transformStyle,
          children: buildItems(itemNumber, drawCount)
        )
      ]
    );
  }

  List<UINode> buildItems(int start, int count);  
}
