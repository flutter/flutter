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
  FixedHeightScrollable({ this.itemHeight, Object key }) : super(key: key) {
    assert(itemHeight != null);
  }

  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  OverscrollBehavior get scrollBehavior => super.scrollBehavior as OverscrollBehavior;

  double _height;
  final double itemHeight;

  int _itemCount = 0;
  int get itemCount => _itemCount;
  void set itemCount (int value) {
    if (_itemCount != value) {
      _itemCount = value;
      scrollBehavior.contentsHeight = itemHeight * _itemCount;
    }
  }

  void _handleSizeChanged(Size newSize) {
    setState(() {
      _height = newSize.height;
      scrollBehavior.containerHeight = _height;
    });
  }

  UINode buildContent() {
    var itemNumber = 0;
    var itemCount = 0;

    Matrix4 transform = new Matrix4.identity();

    if (_height != null && _height > 0.0) {
      if (scrollOffset < 0.0) {
        double visibleHeight = _height + scrollOffset;
        itemCount = (visibleHeight / itemHeight).round() + 1;
        transform.translate(0.0, -scrollOffset);
      } else {
        itemCount = (_height / itemHeight).ceil() + 1;
        double alignmentDelta = -scrollOffset % itemHeight;
        if (alignmentDelta != 0.0)
          alignmentDelta -= itemHeight;

        double drawStart = scrollOffset + alignmentDelta;
        itemNumber = math.max(0, (drawStart / itemHeight).floor());

        transform.translate(0.0, alignmentDelta);
      }
    }

    return new SizeObserver(
      callback: _handleSizeChanged,
      child: new Clip(
        child: new DecoratedBox(
          decoration: const BoxDecoration(
            backgroundColor: const Color(0xFFFFFFFF)
          ),
          child: new Transform(
            transform: transform,
            child: new BlockContainer(
              children: buildItems(itemNumber, itemCount))
          )
        )
      )
    );
  }

  List<UINode> buildItems(int start, int count);  
}
