// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'framework.dart';
import 'scroll_behavior.dart';
import 'scrollable.dart';
import 'virtual_viewport.dart';

import 'package:flutter/rendering.dart';

class ScrollableList extends Scrollable {
  ScrollableList({
    Key key,
    double initialScrollOffset,
    Axis scrollDirection: Axis.vertical,
    ScrollListener onScroll,
    SnapOffsetCallback snapOffsetCallback,
    double snapAlignmentOffset: 0.0,
    this.itemExtent,
    this.itemsWrap: false,
    this.padding,
    this.scrollableListPainter,
    this.children
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    scrollDirection: scrollDirection,
    onScroll: onScroll,
    snapOffsetCallback: snapOffsetCallback,
    snapAlignmentOffset: snapAlignmentOffset
  ) {
    assert(itemExtent != null);
  }

  final double itemExtent;
  final bool itemsWrap;
  final EdgeDims padding;
  final ScrollableListPainter scrollableListPainter;
  final Iterable<Widget> children;

  ScrollableState createState() => new _ScrollableListState();
}

class _ScrollableListState extends ScrollableState<ScrollableList> {
  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  ExtentScrollBehavior get scrollBehavior => super.scrollBehavior;

  void _handleExtentsChanged(double contentExtent, double containerExtent) {
    config.scrollableListPainter?.contentExtent = contentExtent;
    setState(() {
      scrollTo(scrollBehavior.updateExtents(
        contentExtent: config.itemsWrap ? double.INFINITY : contentExtent,
        containerExtent: containerExtent,
        scrollOffset: scrollOffset
      ));
    });
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
    return new ListViewport(
      onExtentsChanged: _handleExtentsChanged,
      startOffset: scrollOffset,
      scrollDirection: config.scrollDirection,
      itemExtent: config.itemExtent,
      itemsWrap: config.itemsWrap,
      padding: config.padding,
      overlayPainter: config.scrollableListPainter,
      children: config.children
    );
  }
}

class _VirtualListViewport extends VirtualViewport {
  _VirtualListViewport(
    this.onExtentsChanged,
    this.startOffset,
    this.scrollDirection,
    this.itemExtent,
    this.itemsWrap,
    this.padding,
    this.overlayPainter
  ) {
    assert(scrollDirection != null);
    assert(itemExtent != null);
  }

  final ExtentsChangedCallback onExtentsChanged;
  final double startOffset;
  final Axis scrollDirection;
  final double itemExtent;
  final bool itemsWrap;
  final EdgeDims padding;
  final Painter overlayPainter;

  RenderList createRenderObject() => new RenderList(itemExtent: itemExtent);

  _VirtualListViewportElement createElement() => new _VirtualListViewportElement(this);
}

class _VirtualListViewportElement extends VirtualViewportElement<_VirtualListViewport> {
  _VirtualListViewportElement(VirtualViewport widget) : super(widget);

  RenderList get renderObject => super.renderObject;

  int get materializedChildBase => _materializedChildBase;
  int _materializedChildBase;

  int get materializedChildCount => _materializedChildCount;
  int _materializedChildCount;

  double get startOffsetBase => _startOffsetBase;
  double _startOffsetBase;

  double get startOffsetLimit =>_startOffsetLimit;
  double _startOffsetLimit;

  void updateRenderObject(_VirtualListViewport oldWidget) {
    renderObject
      ..scrollDirection = widget.scrollDirection
      ..itemExtent = widget.itemExtent
      ..padding = widget.padding
      ..overlayPainter = widget.overlayPainter;
    super.updateRenderObject(oldWidget);
  }

  double _contentExtent;
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
    final int length = renderObject.virtualChildCount;
    final double itemExtent = widget.itemExtent;
    final EdgeDims padding = widget.padding ?? EdgeDims.zero;

    double contentExtent = length == null ? double.INFINITY : widget.itemExtent * length + padding.top + padding.bottom;
    double containerExtent = _getContainerExtentFromRenderObject();

    _materializedChildBase = math.max(0, (widget.startOffset - padding.top) ~/ itemExtent);
    int materializedChildLimit = math.max(0, ((widget.startOffset + containerExtent) / itemExtent).ceil());

    if (!widget.itemsWrap && length != null) {
      _materializedChildBase = math.min(length, _materializedChildBase);
      materializedChildLimit = math.min(length, materializedChildLimit);
    } else if (length == 0) {
      materializedChildLimit = _materializedChildBase;
    }

    _materializedChildCount = materializedChildLimit - _materializedChildBase;
    _startOffsetBase = _materializedChildBase * itemExtent;
    _startOffsetLimit = materializedChildLimit * itemExtent - containerExtent;

    super.layout(constraints);

    if (contentExtent != _contentExtent || containerExtent != _containerExtent) {
      _contentExtent = contentExtent;
      _containerExtent = containerExtent;
      widget.onExtentsChanged(_contentExtent, _containerExtent);
    }
  }
}

class ListViewport extends _VirtualListViewport with VirtualViewportIterableMixin {
  ListViewport({
    ExtentsChangedCallback onExtentsChanged,
    double startOffset: 0.0,
    Axis scrollDirection: Axis.vertical,
    double itemExtent,
    bool itemsWrap: false,
    EdgeDims padding,
    Painter overlayPainter,
    this.children
  }) : super(
    onExtentsChanged,
    startOffset,
    scrollDirection,
    itemExtent,
    itemsWrap,
    padding,
    overlayPainter
  );

  final Iterable<Widget> children;
}

/// An optimized scrollable widget for a large number of children that are all
/// the same size (extent) in the scrollDirection. For example for
/// ScrollDirection.vertical itemExtent is the height of each item. Use this
/// widget when you have a large number of children or when you are concerned
// about offscreen widgets consuming resources.
class ScrollableLazyList extends Scrollable {
  ScrollableLazyList({
    Key key,
    double initialScrollOffset,
    Axis scrollDirection: Axis.vertical,
    ScrollListener onScroll,
    SnapOffsetCallback snapOffsetCallback,
    double snapAlignmentOffset: 0.0,
    this.itemExtent,
    this.itemCount,
    this.itemBuilder,
    this.padding,
    this.scrollableListPainter
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    scrollDirection: scrollDirection,
    onScroll: onScroll,
    snapOffsetCallback: snapOffsetCallback,
    snapAlignmentOffset: snapAlignmentOffset
  ) {
    assert(itemExtent != null);
    assert(itemBuilder != null);
  }

  final double itemExtent;
  final int itemCount;
  final ItemListBuilder itemBuilder;
  final EdgeDims padding;
  final ScrollableListPainter scrollableListPainter;

  ScrollableState createState() => new _ScrollableLazyListState();
}

class _ScrollableLazyListState extends ScrollableState<ScrollableLazyList> {
  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  ExtentScrollBehavior get scrollBehavior => super.scrollBehavior;

  void _handleExtentsChanged(double contentExtent, double containerExtent) {
    config.scrollableListPainter?.contentExtent = contentExtent;
    setState(() {
      scrollTo(scrollBehavior.updateExtents(
        contentExtent: contentExtent,
        containerExtent: containerExtent,
        scrollOffset: scrollOffset
      ));
    });
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
    return new LazyListViewport(
      onExtentsChanged: _handleExtentsChanged,
      startOffset: scrollOffset,
      scrollDirection: config.scrollDirection,
      itemExtent: config.itemExtent,
      itemCount: config.itemCount,
      itemBuilder: config.itemBuilder,
      padding: config.padding,
      overlayPainter: config.scrollableListPainter
    );
  }
}

class LazyListViewport extends _VirtualListViewport with VirtualViewportLazyMixin {
  LazyListViewport({
    ExtentsChangedCallback onExtentsChanged,
    double startOffset: 0.0,
    Axis scrollDirection: Axis.vertical,
    double itemExtent,
    EdgeDims padding,
    Painter overlayPainter,
    this.itemCount,
    this.itemBuilder
  }) : super(
    onExtentsChanged,
    startOffset,
    scrollDirection,
    itemExtent,
    false, // Don't support wrapping yet.
    padding,
    overlayPainter
  );

  final int itemCount;
  final ItemListBuilder itemBuilder;
}
