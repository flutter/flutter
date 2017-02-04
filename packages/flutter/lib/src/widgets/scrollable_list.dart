// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
// DELETE THIS FILE WHEN REMOVING LEGACY SCROLLING CODE
////////////////////////////////////////////////////////////////////////////////

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'scroll_configuration.dart';
import 'scrollable.dart';
import 'virtual_viewport.dart';

/// A scrollable list of children that have equal size.
///
/// [ScrollableList] differs from [ScrollableLazyList] in that [ScrollableList]
/// uses an [Iterable] list of children. That makes [ScrollableList] suitable
/// for a large (but not extremely large or infinite) list of children.
///
/// [ScrollableList] differs from [Block] and [LazyBlock] in that
/// [ScrollableList] requires each of its children to be the same size. That
/// makes [ScrollableList] more efficient but less flexible than [Block] and
/// [LazyBlock].
///
/// Prefer [ScrollableViewport] when there is only one child.
///
/// See also:
///
///  * [Block], which allows its children to have arbitrary sizes.
///  * [ScrollableLazyList], a more efficient version of [ScrollableList].
///  * [LazyBlock], a more efficient version of [Block].
///  * [ScrollableViewport], which only has one child.
class ScrollableList extends StatelessWidget {
  /// Creats a scrollable list of children that have equal size.
  ///
  /// The [scrollDirection], [scrollAnchor], and [itemExtent] arguments must not
  /// be null.
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
    @required this.itemExtent,
    this.itemsWrap: false,
    this.padding,
    this.children: const <Widget>[],
  }) : super(key: key) {
    assert(scrollDirection != null);
    assert(scrollAnchor != null);
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

  /// Whether the first item should be revealed after scrolling past the last item.
  final bool itemsWrap;

  /// The amount of space by which to inset the children inside the viewport.
  final EdgeInsets padding;

  /// The children, some of which might be materialized.
  final Iterable<Widget> children;

  Widget _buildViewport(BuildContext context, ScrollableState state) {
    return new ListViewport(
      onExtentsChanged: (double contentExtent, double containerExtent) {
        state.handleExtentsChanged(itemsWrap ? double.INFINITY : contentExtent, containerExtent);
      },
      scrollOffset: state.scrollOffset,
      mainAxis: scrollDirection,
      anchor: scrollAnchor,
      itemExtent: itemExtent,
      itemsWrap: itemsWrap,
      padding: padding,
      children: children
    );
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
      builder: _buildViewport
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
    assert(anchor != null);
    assert(itemExtent != null);
  }

  /// Called when the interior or exterior dimensions of the viewport change.
  final ExtentsChangedCallback onExtentsChanged;

  /// The [startOffset] without taking the [padding] into account.
  final double scrollOffset;

  /// The direction in which the children are permitted to be larger than the viewport.
  ///
  /// The children are given layout constraints that are fully unconstrained
  /// along the main axis (e.g., children can be as tall as they want if the
  /// main axis is vertical).
  final Axis mainAxis;

  /// Whether to place first child at the start of the container or the last
  /// child at the end of the container, when the viewport has not been offset.
  ///
  /// For example, if the [mainAxis] is [Axis.vertical] and
  /// there are enough items to overflow the container, then
  /// [ViewportAnchor.start] means that the top of the first item
  /// should be aligned with the top of the viewport with the last
  /// item below the bottom, and [ViewportAnchor.end] means the bottom
  /// of the last item should be aligned with the bottom of the
  /// viewport, with the first item above the top.
  ///
  /// This also affects whether, when an item is added or removed, the
  /// displacement will be towards the first item or the last item.
  /// Continuing the earlier example, if a new item is inserted in the
  /// middle of the list, in the [ViewportAnchor.start] case the items
  /// after it (with greater indices, down to the item with the
  /// highest index) will be pushed down, while in the
  /// [ViewportAnchor.end] case the items before it (with lower
  /// indices, up to the item with the index 0) will be pushed up.
  final ViewportAnchor anchor;

  /// The height of each item if [scrollDirection] is Axis.vertical, otherwise the width of each item.
  final double itemExtent;

  /// Whether the first item should be revealed after scrolling past the last item.
  final bool itemsWrap;

  /// The amount of space by which to inset the children inside the viewport.
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
    assert(mainAxis != null);
    return null;
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

/// A virtual viewport onto a list of equally sized children.
///
/// [ListViewport] differs from [LazyListViewport] in that [ListViewport]
/// uses an [Iterable] list of children. That makes [ListViewport] suitable
/// for a large (but not extremely large or infinite) list of children.
///
/// [ListViewport] differs from [LazyBlockViewport] in that [ListViewport]
/// requires each of its children to be the same size. That makes [ListViewport]
/// more efficient but less flexible than [LazyBlockViewport].
///
/// Prefer [Viewport] when there is only one child.
///
/// Used by [ScrollableList].
///
/// See also:
///
///  * [LazyListViewport].
///  * [LazyBlockViewport].
///  * [GridViewport].
class ListViewport extends _VirtualListViewport with VirtualViewportFromIterable {
  /// Creates a virtual viewport onto a list of equally sized children.
  ///
  /// The [mainAxis], [anchor], and [itemExtent] arguments must not be null.
  ListViewport({
    ExtentsChangedCallback onExtentsChanged,
    double scrollOffset: 0.0,
    Axis mainAxis: Axis.vertical,
    ViewportAnchor anchor: ViewportAnchor.start,
    @required double itemExtent,
    bool itemsWrap: false,
    EdgeInsets padding,
    this.children: const <Widget>[],
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

/// An infinite scrollable list of children that have equal size.
///
/// [ScrollableLazyList] differs from [ScrollableList] in that
/// [ScrollableLazyList] uses an [ItemListBuilder] to lazily create children.
/// That makes [ScrollableLazyList] suitable for an extremely large or infinite
/// list of children but also makes it more verbose than [ScrollableList].
///
/// [ScrollableLazyList] differs from [LazyBlock] in that [ScrollableLazyList]
/// requires each of its children to be the same size. That makes
/// [ScrollableLazyList] more efficient but less flexible than [LazyBlock].
///
/// See also:
///
///  * [ScrollableList].
///  * [LazyBlock].
class ScrollableLazyList extends StatelessWidget {
  /// Creates an infinite scrollable list of children that have equal size.
  ///
  /// The [scrollDirection], [scrollAnchor], [itemExtent], and [itemBuilder]
  /// arguments must not be null. The [itemCount] argument must not be null
  /// unless the [scrollAnchor] argument is [ViewportAnchor.start].
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
    @required this.itemExtent,
    this.itemCount,
    @required this.itemBuilder,
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

  /// Returns a widget representing the item with the given index.
  ///
  /// This function might be called with index parameters in any order. This
  /// function should return null for indices that exceed the number of children
  /// (i.e., [itemCount] if non-null). If this function must not return a null
  /// value for an index if it previously returned a non-null value for that
  /// index or a larger index.
  ///
  /// This function might be called during the build or layout phases of the
  /// pipeline.
  ///
  /// The returned widget might or might not be cached by [ScrollableLazyList].
  final ItemListBuilder itemBuilder;

  /// The amount of space by which to inset the children inside the viewport.
  final EdgeInsets padding;

  Widget _buildViewport(BuildContext context, ScrollableState state) {
    return new LazyListViewport(
      onExtentsChanged: state.handleExtentsChanged,
      scrollOffset: state.scrollOffset,
      mainAxis: scrollDirection,
      anchor: scrollAnchor,
      itemExtent: itemExtent,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      padding: padding
    );
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
      builder: _buildViewport
    );
    return ScrollConfiguration.wrap(context, result);
  }
}

/// A virtual viewport onto an extremely large or infinite list of equally sized children.
///
/// [LazyListViewport] differs from [ListViewport] in that [LazyListViewport]
/// uses an [ItemListBuilder] to lazily create children. That makes
/// [LazyListViewport] suitable for an extremely large or infinite list of
/// children but also makes it more verbose than [ListViewport].
///
/// [LazyListViewport] differs from [LazyBlockViewport] in that
/// [LazyListViewport] requires each of its children to be the same size. That
/// makes [LazyListViewport] more efficient but less flexible than
/// [LazyBlockViewport].
///
/// Used by [ScrollableLazyList].
///
/// See also:
///
///  * [ListViewport].
///  * [LazyBlockViewport].
class LazyListViewport extends _VirtualListViewport with VirtualViewportFromBuilder {
  /// Creates a virtual viewport onto an extremely large or infinite list of equally sized children.
  ///
  /// The [mainAxis], [anchor], [itemExtent], and [itemBuilder] arguments must
  /// not be null.
  LazyListViewport({
    ExtentsChangedCallback onExtentsChanged,
    double scrollOffset: 0.0,
    Axis mainAxis: Axis.vertical,
    ViewportAnchor anchor: ViewportAnchor.start,
    @required double itemExtent,
    EdgeInsets padding,
    this.itemCount,
    @required this.itemBuilder
  }) : super(
    onExtentsChanged,
    scrollOffset,
    mainAxis,
    anchor,
    itemExtent,
    false, // Don't support wrapping yet.
    padding
  ) {
    assert(itemBuilder != null);
  }

  @override
  final int itemCount;

  @override
  final ItemListBuilder itemBuilder;
}
