// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/scroll_behavior.dart';
import '../fn2.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import 'scrollable.dart';

abstract class FixedHeightScrollable extends Scrollable {
  FixedHeightScrollable({ Object key }) : super(key: key);

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
    if (_itemHeight != null)
      return;
    setState(() {
      // TODO(abarth): Actually measure these heights.
      _height = 500.0; // root.height;
      assert(_height > 0);
      _itemHeight = 100.0; // item.height;
      assert(_itemHeight > 0);
      scrollBehavior.containerHeight = _height;
      scrollBehavior.contentsHeight = _itemHeight * _itemCount;
    });
  }

  UINode buildContent() {
    var itemNumber = 0;
    var drawCount = 1;
    var transformStyle = '';

    if (_itemHeight == null)
      new Future.microtask(_measureHeights);

    Matrix4 transform = new Matrix4.identity();

    if (_height > 0.0 && _itemHeight != null) {
      if (scrollOffset < 0.0) {
        double visibleHeight = _height + scrollOffset;
        drawCount = (visibleHeight / _itemHeight).round() + 1;
        transform.translate(0.0, -scrollOffset);
      } else {
        drawCount = (_height / _itemHeight).ceil() + 1;
        double alignmentDelta = -scrollOffset % _itemHeight;
        if (alignmentDelta != 0.0)
          alignmentDelta -= _itemHeight;

        double drawStart = scrollOffset + alignmentDelta;
        itemNumber = math.max(0, (drawStart / _itemHeight).floor());

        transform.translate(0.0, alignmentDelta);
      }
    }

    return new Clip(
      child: new Transform(
        transform: transform,
        child: new BlockContainer(children: buildItems(itemNumber, drawCount))
      )
    );
  }

  List<UINode> buildItems(int start, int count);  
}
