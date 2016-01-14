// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'scrollable.dart';
import 'virtual_viewport.dart';

/// Controls what alignment items use when settling.
enum ItemsSnapAlignment {
  item,
  adjacentItem
}

typedef void PageChangedCallback(int newPage);

class PageableList extends Scrollable {
  PageableList({
    Key key,
    initialScrollOffset,
    Axis scrollDirection: Axis.vertical,
    ScrollListener onScrollStart,
    ScrollListener onScroll,
    ScrollListener onScrollEnd,
    SnapOffsetCallback snapOffsetCallback,
    double snapAlignmentOffset: 0.0,
    this.itemsWrap: false,
    this.itemsSnapAlignment: ItemsSnapAlignment.adjacentItem,
    this.onPageChanged,
    this.scrollableListPainter,
    this.duration: const Duration(milliseconds: 200),
    this.curve: Curves.ease,
    this.children
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

  final bool itemsWrap;
  final ItemsSnapAlignment itemsSnapAlignment;
  final PageChangedCallback onPageChanged;
  final ScrollableListPainter scrollableListPainter;
  final Duration duration;
  final Curve curve;
  final Iterable<Widget> children;

  PageableListState createState() => new PageableListState();
}

class PageableListState<T extends PageableList> extends ScrollableState<T> {
  int get itemCount => config.children?.length ?? 0;
  int _previousItemCount;

  double pixelToScrollOffset(double value) {
    final RenderBox box = context.findRenderObject();
    if (box == null || !box.hasSize)
      return 0.0;
    final double pixelScrollExtent = config.scrollDirection == Axis.vertical ? box.size.height : box.size.width;
    return pixelScrollExtent == 0.0 ? 0.0 : value / pixelScrollExtent;
  }

  void initState() {
    super.initState();
    _updateScrollBehavior();
  }

  void didUpdateConfig(PageableList oldConfig) {
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
    config.scrollableListPainter?.contentExtent = itemCount.toDouble();
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
    config.scrollableListPainter?.scrollOffset = scrollOffset;
  }

  void dispatchOnScrollEnd() {
    super.dispatchOnScrollEnd();
    config.scrollableListPainter?.scrollEnded();
  }

  Widget buildContent(BuildContext context) {
    return new PageViewport(
      itemsWrap: config.itemsWrap,
      scrollDirection: config.scrollDirection,
      startOffset: scrollOffset,
      overlayPainter: config.scrollableListPainter,
      children: config.children
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

  void _notifyPageChanged(_) {
    if (config.onPageChanged != null)
      config.onPageChanged(itemCount == 0 ? 0 : scrollOffset.floor() % itemCount);
  }
}

class PageViewport extends VirtualViewport {
  PageViewport({
    Key key,
    this.startOffset: 0.0,
    this.scrollDirection: Axis.vertical,
    this.itemsWrap: false,
    this.overlayPainter,
    this.children
  }) {
    assert(scrollDirection != null);
  }

  final double startOffset;
  final Axis scrollDirection;
  final bool itemsWrap;
  final Painter overlayPainter;
  final Iterable<Widget> children;

  RenderList createRenderObject() => new RenderList();

  _PageViewportElement createElement() => new _PageViewportElement(this);
}

class _PageViewportElement extends VirtualViewportElement<PageViewport> {
  _PageViewportElement(PageViewport widget) : super(widget);

  RenderList get renderObject => super.renderObject;

  int get materializedChildBase => _materializedChildBase;
  int _materializedChildBase;

  int get materializedChildCount => _materializedChildCount;
  int _materializedChildCount;

  double get startOffsetBase => _repaintOffsetBase;
  double _repaintOffsetBase;

  double get startOffsetLimit =>_repaintOffsetLimit;
  double _repaintOffsetLimit;

  double get paintOffset {
    if (_containerExtent == null)
      return 0.0;
    return -(widget.startOffset - startOffsetBase) * _containerExtent;
  }

  void updateRenderObject(PageViewport oldWidget) {
    renderObject.scrollDirection = widget.scrollDirection;
    renderObject.overlayPainter = widget.overlayPainter;
    super.updateRenderObject(oldWidget);
  }

  double _containerExtent;

  double _getContainerExtentFromRenderObject() {
    switch (widget.scrollDirection) {
      case Axis.vertical:
        return renderObject.size.height;
      case Axis.horizontal:
        return renderObject.size.width;
    }
  }

  void layout(BoxConstraints constraints) {
    int length = renderObject.virtualChildCount;
    _containerExtent = _getContainerExtentFromRenderObject();

    _materializedChildBase = widget.startOffset.floor();
    int materializedChildLimit = (widget.startOffset + 1.0).ceil();

    if (!widget.itemsWrap) {
      _materializedChildBase = _materializedChildBase.clamp(0, length);
      materializedChildLimit = materializedChildLimit.clamp(0, length);
    } else if (length == 0) {
      materializedChildLimit = _materializedChildBase;
    }

    _materializedChildCount = materializedChildLimit - _materializedChildBase;

    _repaintOffsetBase = _materializedChildBase.toDouble();
    _repaintOffsetLimit = (materializedChildLimit - 1).toDouble();

    super.layout(constraints);
  }
}
