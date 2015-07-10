// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:vector_math/vector_math.dart';

import '../animation/scroll_behavior.dart';
import 'basic.dart';
import 'scrollable.dart';

abstract class FixedHeightScrollable extends Scrollable {

  FixedHeightScrollable({ String key, this.itemHeight, Color backgroundColor, this.padding })
      : super(key: key, backgroundColor: backgroundColor) {
    assert(itemHeight != null);
  }

  EdgeDims padding;
  double itemHeight;

  /// Subclasses must implement `get itemCount` to tell FixedHeightScrollable
  /// how many items there are in the list.
  int get itemCount;
  int _previousItemCount;

  void syncFields(FixedHeightScrollable source) {
    padding = source.padding;
    itemHeight = source.itemHeight;
    super.syncFields(source);
  }

  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  OverscrollBehavior get scrollBehavior => super.scrollBehavior;

  double _height;
  void _handleSizeChanged(Size newSize) {
    setState(() {
      _height = newSize.height;
      scrollBehavior.containerSize = _height;
    });
  }

  void _updateContentsHeight() {
    double contentsHeight = itemHeight * itemCount;
    if (padding != null)
      contentsHeight += padding.top + padding.bottom;
    scrollBehavior.contentsSize = contentsHeight;
  }

  void _updateScrollOffset() {
    if (scrollOffset > scrollBehavior.maxScrollOffset)
      settleScrollOffset();
  }

  Widget buildContent() {
    if (itemCount != _previousItemCount) {
      _previousItemCount = itemCount;
      _updateContentsHeight();
      _updateScrollOffset();
    }

    var itemShowIndex = 0;
    var itemShowCount = 0;
    Matrix4 transform = new Matrix4.identity();

    if (_height != null && _height > 0.0) {
      if (scrollOffset < 0.0) {
        double visibleHeight = _height + scrollOffset;
        itemShowCount = (visibleHeight / itemHeight).round() + 1;
        transform.translate(0.0, -scrollOffset);
      } else {
        itemShowCount = (_height / itemHeight).ceil() + 1;
        double alignmentDelta = -scrollOffset % itemHeight;
        if (alignmentDelta != 0.0)
          alignmentDelta -= itemHeight;

        double drawStart = scrollOffset + alignmentDelta;
        itemShowIndex = math.max(0, (drawStart / itemHeight).floor());

        transform.translate(0.0, alignmentDelta);
      }
    }

    List<Widget> items = buildItems(itemShowIndex, itemShowCount);
    assert(items.every((item) => item.key != null));

    return new SizeObserver(
      callback: _handleSizeChanged,
      child: new ClipRect(
        child: new Transform(
          transform: transform,
          child: new Container(
            padding: padding,
            child: new Block(items)
          )
        )
      )
    );
  }

  List<Widget> buildItems(int start, int count);

}
