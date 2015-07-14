// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:sky/animation/scroll_behavior.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/scrollable.dart';

abstract class FixedHeightScrollable extends Scrollable {

  FixedHeightScrollable({ String key, this.itemHeight, this.padding })
      : super(key: key) {
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

    int itemShowIndex = 0;
    int itemShowCount = 0;
    double offsetY = 0.0;
    if (_height != null && _height > 0.0) {
      if (scrollOffset < 0.0) {
        double visibleHeight = _height + scrollOffset;
        itemShowCount = (visibleHeight / itemHeight).round() + 1;
        offsetY = scrollOffset;
      } else {
        itemShowCount = (_height / itemHeight).ceil();
        double alignmentDelta = -scrollOffset % itemHeight;
        double drawStart;
        if (alignmentDelta != 0.0) {
          alignmentDelta -= itemHeight;
          itemShowCount += 1;
          drawStart = scrollOffset + alignmentDelta;
          offsetY = -alignmentDelta;
        } else {
          drawStart = scrollOffset;
        }
        itemShowIndex = math.max(0, (drawStart / itemHeight).floor());
      }
    }

    List<Widget> items = buildItems(itemShowIndex, itemShowCount);
    assert(items.every((item) => item.key != null));

    // TODO(ianh): Refactor this so that it does the building in the
    // same frame as the size observing, similar to BlockViewport, but
    // keeping the fixed-height optimisations.
    return new SizeObserver(
      callback: _handleSizeChanged,
      child: new Viewport(
        offset: offsetY,
        child: new Container(
          padding: padding,
          child: new Block(items)
        )
      )
    );
  }

  List<Widget> buildItems(int start, int count);

}
