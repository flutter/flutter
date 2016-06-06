// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'clamp_overscrolls.dart';
import 'framework.dart';
import 'scroll_configuration.dart';
import 'scrollable.dart';
import 'virtual_viewport.dart';

import 'package:flutter/rendering.dart';

class ScrollableList extends StatelessWidget {
  ScrollableList({
    Key key,
    this.initialScrollOffset,
    this.scrollDirection: Axis.vertical,
    this.scrollAnchor: ViewportAnchor.start,
    this.onScrollStart,
    this.onScroll,
    this.onScrollEnd,
    this.snapOffsetCallback,
    this.scrollableKey,
    this.itemExtent,
    this.itemsWrap: false,
    this.padding,
    this.children
  }) : super(key: key) {
    assert(itemExtent != null);
  }

  // Warning: keep the dartdoc comments that follow in sync with the copies in
  // Scrollable, LazyBlock, ScrollableLazyList, ScrollableViewport, and
  // ScrollableGrid. And see: https://github.com/dart-lang/dartdoc/issues/1161.

  /// The scroll offset this widget should use when first created.
  final double initialScrollOffset;

  /// The axis along which this widget should scroll.
  final Axis scrollDirection;

  /// Whether to place first child at the start of the container or
  /// the last child at the end of the container, when the scrollable
  /// has not been scrolled and has no initial scroll offset.
  ///
  /// For example, if the [scrollDirection] is [Axis.vertical] and
  /// there are enough items to overflow the container, then
  /// [ViewportAnchor.start] means that the top of the first item
  /// should be aligned with the top of the scrollable with the last
  /// item below the bottom, and [ViewportAnchor.end] means the bottom
  /// of the last item should be aligned with the bottom of the
  /// scrollable, with the first item above the top.
  ///
  /// This also affects whether, when an item is added or removed, the
  /// displacement will be towards the first item or the last item.
  /// Continuing the earlier example, if a new item is inserted in the
  /// middle of the list, in the [ViewportAnchor.start] case the items
  /// after it (with greater indices, down to the item with the
  /// highest index) will be pushed down, while in the
  /// [ViewportAnchor.end] case the items before it (with lower
  /// indices, up to the item with the index 0) will be pushed up.
  final ViewportAnchor scrollAnchor;

  /// Called whenever this widget starts to scroll.
  final ScrollListener onScrollStart;

  /// Called whenever this widget's scroll offset changes.
  final ScrollListener onScroll;

  /// Called whenever this widget stops scrolling.
  final ScrollListener onScrollEnd;

  /// Called to determine the offset to which scrolling should snap,
  /// when handling a fling.
  ///
  /// This callback, if set, will be called with the offset that the
  /// Scrollable would have scrolled to in the absence of this
  /// callback, and a Size describing the size of the Scrollable
  /// itself.
  ///
  /// The callback's return value is used as the new scroll offset to
  /// aim for.
  ///
  /// If the callback simply returns its first argument (the offset),
  /// then it is as if the callback was null.
  final SnapOffsetCallback snapOffsetCallback;

  /// The key for the Scrollable created by this widget.
  final Key scrollableKey;

  /// The height of each item if [scrollDirection] is Axis.vertical, otherwise the width of each item.
  final double itemExtent;

  final bool itemsWrap;

  /// The amount of space by which to inset the children inside the viewport.
  final EdgeInsets padding;

  /// The axis along which this widget should scroll.
  final Iterable<Widget> children;

  Widget _buildViewport(BuildContext context, ScrollableState state, double scrollOffset) {
    return new ListViewport(
      onExtentsChanged: (double contentExtent, double containerExtent) {
        state.handleExtentsChanged(itemsWrap ? double.INFINITY : contentExtent, containerExtent);
      },
      scrollOffset: scrollOffset,
      mainAxis: scrollDirection,
      anchor: scrollAnchor,
      itemExtent: itemExtent,
      itemsWrap: itemsWrap,
      padding: padding,
      children: children
    );
  }

  Widget _buildContent(BuildContext context, ScrollableState state) {
    return ClampOverscrolls.buildViewport(context, state, _buildViewport);
  }

  @override
  Widget build(BuildContext context) {
    final Widget result = new Scrollable(
      key: scrollableKey,
      initialScrollOffset: initialScrollOffset,
      scrollDirection: scrollDirection,
      scrollAnchor: scrollAnchor,
      onScrollStart: onScrollStart,
      onScroll: onScroll,
      onScrollEnd: onScrollEnd,
      snapOffsetCallback: snapOffsetCallback,
      builder: _buildContent
    );
    return ScrollConfiguration.wrap(context, result);
  }
}

class _VirtualListViewport extends VirtualViewport {
  _VirtualListViewport(
    this.onExtentsChanged,
    this.scrollOffset,
    this.mainAxis,
    this.anchor,
    this.itemExtent,
    this.itemsWrap,
    this.padding
  ) {
    assert(mainAxis != null);
    assert(itemExtent != null);
  }

  final ExtentsChangedCallback onExtentsChanged;
  final double scrollOffset;
  final Axis mainAxis;
  final ViewportAnchor anchor;
  final double itemExtent;
  final bool itemsWrap;
  final EdgeInsets padding;

  double get _leadingPadding {
    switch (mainAxis) {
      case Axis.vertical:
        switch (anchor) {
          case ViewportAnchor.start:
            return padding.top;
          case ViewportAnchor.end:
            return padding.bottom;
        }
        break;
      case Axis.horizontal:
        switch (anchor) {
          case ViewportAnchor.start:
            return padding.left;
          case ViewportAnchor.end:
            return padding.right;
        }
        break;
    }
  }

  @override
  double get startOffset {
    if (padding == null)
      return scrollOffset;
    return scrollOffset - _leadingPadding;
  }

  @override
  RenderList createRenderObject(BuildContext context) => new RenderList(itemExtent: itemExtent);

  @override
  _VirtualListViewportElement createElement() => new _VirtualListViewportElement(this);
}

class _VirtualListViewportElement extends VirtualViewportElement {
  _VirtualListViewportElement(VirtualViewport widget) : super(widget);

  @override
  _VirtualListViewport get widget => super.widget;

  @override
  RenderList get renderObject => super.renderObject;

  @override
  int get materializedChildBase => _materializedChildBase;
  int _materializedChildBase;

  @override
  int get materializedChildCount => _materializedChildCount;
  int _materializedChildCount;

  @override
  double get startOffsetBase => _startOffsetBase;
  double _startOffsetBase;

  @override
  double get startOffsetLimit =>_startOffsetLimit;
  double _startOffsetLimit;

  @override
  void updateRenderObject(_VirtualListViewport oldWidget) {
    renderObject
      ..mainAxis = widget.mainAxis
      ..anchor = widget.anchor
      ..itemExtent = widget.itemExtent
      ..padding = widget.padding;
    super.updateRenderObject(oldWidget);
  }

  double _lastReportedContentExtent;
  double _lastReportedContainerExtent;

  @override
  void layout(BoxConstraints constraints) {
    final int length = renderObject.virtualChildCount;
    final double itemExtent = widget.itemExtent;
    final EdgeInsets padding = widget.padding ?? EdgeInsets.zero;
    final Size containerSize = renderObject.size;

    double containerExtent;
    double contentExtent;

    switch (widget.mainAxis) {
      case Axis.vertical:
        containerExtent = containerSize.height;
        contentExtent = length == null ? double.INFINITY : widget.itemExtent * length + padding.vertical;
        break;
      case Axis.horizontal:
        containerExtent = renderObject.size.width;
        contentExtent = length == null ? double.INFINITY : widget.itemExtent * length + padding.horizontal;
        break;
    }

    if (length == 0) {
      _materializedChildBase = 0;
      _materializedChildCount = 0;
      _startOffsetBase = 0.0;
      _startOffsetLimit = double.INFINITY;
    } else {
      final double startOffset = widget.startOffset;
      int startItem = math.max(0, startOffset ~/ itemExtent);
      int limitItem = math.max(0, ((startOffset + containerExtent) / itemExtent).ceil());

      if (!widget.itemsWrap && length != null) {
        startItem = math.min(length, startItem);
        limitItem = math.min(length, limitItem);
      }

      _materializedChildBase = startItem;
      _materializedChildCount = limitItem - startItem;
      _startOffsetBase = startItem * itemExtent;
      _startOffsetLimit = limitItem * itemExtent - containerExtent;

      if (widget.anchor == ViewportAnchor.end)
        _materializedChildBase = (length - _materializedChildBase - _materializedChildCount) % length;
    }

    Size materializedContentSize;
    switch (widget.mainAxis) {
      case Axis.vertical:
        materializedContentSize = new Size(containerSize.width, _materializedChildCount * itemExtent);
        break;
      case Axis.horizontal:
        materializedContentSize = new Size(_materializedChildCount * itemExtent, containerSize.height);
        break;
    }
    renderObject.dimensions = new ViewportDimensions(containerSize: containerSize, contentSize: materializedContentSize);

    super.layout(constraints);

    if (contentExtent != _lastReportedContentExtent || containerExtent != _lastReportedContainerExtent) {
      _lastReportedContentExtent = contentExtent;
      _lastReportedContainerExtent = containerExtent;
      widget.onExtentsChanged(_lastReportedContentExtent, _lastReportedContainerExtent);
    }
  }
}

class ListViewport extends _VirtualListViewport with VirtualViewportFromIterable {
  ListViewport({
    ExtentsChangedCallback onExtentsChanged,
    double scrollOffset: 0.0,
    Axis mainAxis: Axis.vertical,
    ViewportAnchor anchor: ViewportAnchor.start,
    double itemExtent,
    bool itemsWrap: false,
    EdgeInsets padding,
    this.children
  }) : super(
    onExtentsChanged,
    scrollOffset,
    mainAxis,
    anchor,
    itemExtent,
    itemsWrap,
    padding
  );

  @override
  final Iterable<Widget> children;
}

/// An optimized scrollable widget for a large number of children that are all
/// the same size (extent) in the scrollDirection. For example for
/// ScrollDirection.vertical itemExtent is the height of each item. Use this
/// widget when you have a large number of children or when you are concerned
/// about offscreen widgets consuming resources.
class ScrollableLazyList extends StatelessWidget {
  ScrollableLazyList({
    Key key,
    this.initialScrollOffset,
    this.scrollDirection: Axis.vertical,
    this.scrollAnchor: ViewportAnchor.start,
    this.onScrollStart,
    this.onScroll,
    this.onScrollEnd,
    this.snapOffsetCallback,
    this.scrollableKey,
    this.itemExtent,
    this.itemCount,
    this.itemBuilder,
    this.padding
  }) : super(key: key) {
    assert(itemExtent != null);
    assert(itemBuilder != null);
    assert(itemCount != null || scrollAnchor == ViewportAnchor.start);
  }

  // Warning: keep the dartdoc comments that follow in sync with the copies in
  // Scrollable, LazyBlock, ScrollableViewport, ScrollableList, and
  // ScrollableGrid. And see: https://github.com/dart-lang/dartdoc/issues/1161.

  /// The scroll offset this widget should use when first created.
  final double initialScrollOffset;

  /// The axis along which this widget should scroll.
  final Axis scrollDirection;

  /// Whether to place first child at the start of the container or
  /// the last child at the end of the container, when the scrollable
  /// has not been scrolled and has no initial scroll offset.
  ///
  /// For example, if the [scrollDirection] is [Axis.vertical] and
  /// there are enough items to overflow the container, then
  /// [ViewportAnchor.start] means that the top of the first item
  /// should be aligned with the top of the scrollable with the last
  /// item below the bottom, and [ViewportAnchor.end] means the bottom
  /// of the last item should be aligned with the bottom of the
  /// scrollable, with the first item above the top.
  ///
  /// This also affects whether, when an item is added or removed, the
  /// displacement will be towards the first item or the last item.
  /// Continuing the earlier example, if a new item is inserted in the
  /// middle of the list, in the [ViewportAnchor.start] case the items
  /// after it (with greater indices, down to the item with the
  /// highest index) will be pushed down, while in the
  /// [ViewportAnchor.end] case the items before it (with lower
  /// indices, up to the item with the index 0) will be pushed up.
  final ViewportAnchor scrollAnchor;

  /// Called whenever this widget starts to scroll.
  final ScrollListener onScrollStart;

  /// Called whenever this widget's scroll offset changes.
  final ScrollListener onScroll;

  /// Called whenever this widget stops scrolling.
  final ScrollListener onScrollEnd;

  /// when handling a fling.
  ///
  /// This callback, if set, will be called with the offset that the
  /// Scrollable would have scrolled to in the absence of this
  /// callback, and a Size describing the size of the Scrollable
  /// itself.
  ///
  /// The callback's return value is used as the new scroll offset to
  /// aim for.
  ///
  /// If the callback simply returns its first argument (the offset),
  /// then it is as if the callback was null.
  final SnapOffsetCallback snapOffsetCallback;

  /// The key for the Scrollable created by this widget.
  final Key scrollableKey;

  /// The height of each item if [scrollDirection] is Axis.vertical, otherwise the width of each item.
  final double itemExtent;

  /// The total number of list items.
  final int itemCount;

  final ItemListBuilder itemBuilder;

  /// The insets for the entire list.
  final EdgeInsets padding;

  Widget _buildViewport(BuildContext context, ScrollableState state, double scrollOffset) {
    return new LazyListViewport(
      onExtentsChanged: state.handleExtentsChanged,
      scrollOffset: scrollOffset,
      mainAxis: scrollDirection,
      anchor: scrollAnchor,
      itemExtent: itemExtent,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      padding: padding
    );
  }

  Widget _buildContent(BuildContext context, ScrollableState state) {
    return ClampOverscrolls.buildViewport(context, state, _buildViewport);
  }

  @override
  Widget build(BuildContext context) {
    final Widget result = new Scrollable(
      key: scrollableKey,
      initialScrollOffset: initialScrollOffset,
      scrollDirection: scrollDirection,
      scrollAnchor: scrollAnchor,
      onScrollStart: onScrollStart,
      onScroll: onScroll,
      onScrollEnd: onScrollEnd,
      snapOffsetCallback: snapOffsetCallback,
      builder: _buildContent
    );
    return ScrollConfiguration.wrap(context, result);
  }
}

class LazyListViewport extends _VirtualListViewport with VirtualViewportFromBuilder {
  LazyListViewport({
    ExtentsChangedCallback onExtentsChanged,
    double scrollOffset: 0.0,
    Axis mainAxis: Axis.vertical,
    ViewportAnchor anchor: ViewportAnchor.start,
    double itemExtent,
    EdgeInsets padding,
    this.itemCount,
    this.itemBuilder
  }) : super(
    onExtentsChanged,
    scrollOffset,
    mainAxis,
    anchor,
    itemExtent,
    false, // Don't support wrapping yet.
    padding
  );

  @override
  final int itemCount;

  @override
  final ItemListBuilder itemBuilder;
}
