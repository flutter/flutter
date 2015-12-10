// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'homogeneous_viewport.dart';
import 'scrollable.dart';

/// Controls what alignment items use when settling.
enum ItemsSnapAlignment {
  item,
  adjacentItem
}

typedef void PageChangedCallback(int newPage);

class PageableList<T> extends Scrollable {
  PageableList({
    Key key,
    initialScrollOffset,
    ScrollDirection scrollDirection: ScrollDirection.vertical,
    ScrollListener onScrollStart,
    ScrollListener onScroll,
    ScrollListener onScrollEnd,
    SnapOffsetCallback snapOffsetCallback,
    double snapAlignmentOffset: 0.0,
    this.items,
    this.itemBuilder,
    this.itemsWrap: false,
    this.itemsSnapAlignment: ItemsSnapAlignment.adjacentItem,
    this.onPageChanged,
    this.scrollableListPainter,
    this.duration: const Duration(milliseconds: 200),
    this.curve: Curves.ease
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    scrollDirection: scrollDirection,
    onScrollStart: onScrollStart,
    onScroll: onScroll,
    onScrollEnd: onScrollEnd,
    snapOffsetCallback: snapOffsetCallback,
    snapAlignmentOffset: snapAlignmentOffset
  );

  final List<T> items;
  final ItemBuilder<T> itemBuilder;
  final ItemsSnapAlignment itemsSnapAlignment;
  final bool itemsWrap;
  final PageChangedCallback onPageChanged;
  final ScrollableListPainter scrollableListPainter;
  final Duration duration;
  final Curve curve;

  PageableListState<T, PageableList<T>> createState() => new PageableListState<T, PageableList<T>>();
}

class PageableListState<T, Config extends PageableList<T>> extends ScrollableState<Config> {

  int get itemCount => config.items?.length ?? 0;
  int _previousItemCount;

  double pixelToScrollOffset(double value) {
    final RenderBox box = context.findRenderObject();
    if (box == null || !box.hasSize)
      return 0.0;
    final double pixelScrollExtent = config.scrollDirection == ScrollDirection.vertical ? box.size.height : box.size.width;
    return pixelScrollExtent == 0.0 ? 0.0 : value / pixelScrollExtent;
  }

  void didUpdateConfig(Config oldConfig) {
    super.didUpdateConfig(oldConfig);

    bool scrollBehaviorUpdateNeeded = config.scrollDirection != oldConfig.scrollDirection;

    if (config.itemsWrap != oldConfig.itemsWrap)
      scrollBehaviorUpdateNeeded = true;

    if (itemCount != _previousItemCount) {
      _previousItemCount = itemCount;
      scrollBehaviorUpdateNeeded = true;
    }

    if (scrollBehaviorUpdateNeeded)
      _updateScrollBehavior();
  }

  void _updateScrollBehavior() {
    // if you don't call this from build(), you must call it from setState().
    if (config.scrollableListPainter != null)
      config.scrollableListPainter.contentExtent = itemCount.toDouble();
    scrollTo(scrollBehavior.updateExtents(
      contentExtent: itemCount.toDouble(),
      containerExtent: 1.0,
      scrollOffset: scrollOffset
    ));
  }

  void dispatchOnScrollStart() {
    super.dispatchOnScrollStart();
    config.scrollableListPainter?.scrollStarted();
  }

  void dispatchOnScroll() {
    super.dispatchOnScroll();
    if (config.scrollableListPainter != null)
      config.scrollableListPainter.scrollOffset = scrollOffset;
  }

  void dispatchOnScrollEnd() {
    super.dispatchOnScrollEnd();
    config.scrollableListPainter?.scrollEnded();
  }

  Widget buildContent(BuildContext context) {
    if (itemCount != _previousItemCount) {
      _previousItemCount = itemCount;
      _updateScrollBehavior();
    }
    return new HomogeneousPageViewport(
      builder: buildItems,
      itemsWrap: config.itemsWrap,
      itemCount: itemCount,
      direction: config.scrollDirection,
      startOffset: scrollOffset,
      overlayPainter: config.scrollableListPainter
    );
  }

  UnboundedBehavior _unboundedBehavior;
  OverscrollBehavior _overscrollBehavior;

  ExtentScrollBehavior get scrollBehavior {
    if (config.itemsWrap) {
      _unboundedBehavior ??= new UnboundedBehavior();
      return _unboundedBehavior;
    }
    _overscrollBehavior ??= new OverscrollBehavior();
    return _overscrollBehavior;
  }

  ScrollBehavior createScrollBehavior() => scrollBehavior;

  bool get snapScrollOffsetChanges => config.itemsSnapAlignment == ItemsSnapAlignment.item;

  double snapScrollOffset(double newScrollOffset) {
    final double previousItemOffset = newScrollOffset.floorToDouble();
    final double nextItemOffset = newScrollOffset.ceilToDouble();
    return (newScrollOffset - previousItemOffset < 0.5 ? previousItemOffset : nextItemOffset)
      .clamp(scrollBehavior.minScrollOffset, scrollBehavior.maxScrollOffset);
  }

  Future _flingToAdjacentItem(Offset velocity) {
    final double scrollVelocity = scrollDirectionVelocity(velocity);
    final double newScrollOffset = snapScrollOffset(scrollOffset + scrollVelocity.sign)
      .clamp(snapScrollOffset(scrollOffset - 0.5), snapScrollOffset(scrollOffset + 0.5));
    return scrollTo(newScrollOffset, duration: config.duration, curve: config.curve)
      .then(_notifyPageChanged);
  }

  Future fling(Offset velocity) {
    switch(config.itemsSnapAlignment) {
      case ItemsSnapAlignment.adjacentItem:
        return _flingToAdjacentItem(velocity);
      default:
        return super.fling(velocity).then(_notifyPageChanged);
    }
  }

  Future settleScrollOffset() {
    return scrollTo(snapScrollOffset(scrollOffset), duration: config.duration, curve: config.curve)
      .then(_notifyPageChanged);
  }

  List<Widget> buildItems(BuildContext context, int start, int count) {
    final List<Widget> result = new List<Widget>();
    final int begin = config.itemsWrap ? start : math.max(0, start);
    final int end = config.itemsWrap ? begin + count : math.min(begin + count, itemCount);
    for (int i = begin; i < end; ++i)
      result.add(config.itemBuilder(context, config.items[i % itemCount], i));
    assert(result.every((Widget item) => item.key != null));
    return result;
  }

  void _notifyPageChanged(_) {
    if (config.onPageChanged != null)
      config.onPageChanged(itemCount == 0 ? 0 : scrollOffset.floor() % itemCount);
  }
}
