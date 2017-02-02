// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/rendering.dart' show RenderList, ViewportDimensions;

import 'basic.dart';
import 'framework.dart';
import 'scroll_behavior.dart';
import 'scroll_configuration.dart';
import 'scrollable.dart';
import 'virtual_viewport.dart';

/// Controls how a pageable list should behave during a fling.
enum PageableListFlingBehavior {
  /// A fling gesture can scroll the list by more than one page.
  canFlingAcrossMultiplePages,

  /// A fling gesture can scroll the list by at most one page.
  stopAtNextPage
}

/// A base class for widgets that display one page at a time.
///
/// [Pageable] widgets are similar to [Scrollable] except that they display a
/// single child at a time. When being scrolled, they can display adjacent
/// pages, but when the user stops scrolling, they settle their scroll offset to
/// a value that shows a single page.
///
/// [Pageable] uses different units for its scroll offset than [Scrollable]. One
/// unit of scroll offset corresponds to one child widget, which means a scroll
/// offset of 2.75 indicates that the viewport is three quarters of the way
/// between the child with index 2 and the child with index 3.
///
/// Widgets that subclass [Pageable] typically use state objects that subclass
/// [PageableState].
///
/// See also:
///
///  * [PageableList], which pages through an iterable list of children.
///  * [PageableLazyList], which pages through a lazily constructed list of
///    children.
abstract class Pageable extends Scrollable {
  /// Initializes fields for subclasses.
  ///
  /// The [scrollDirection], [scrollAnchor], and [itemsSnapAlignment] arguments
  /// must not be null.
  Pageable({
    Key key,
    double initialScrollOffset,
    Axis scrollDirection: Axis.vertical,
    ViewportAnchor scrollAnchor: ViewportAnchor.start,
    ScrollListener onScrollStart,
    ScrollListener onScroll,
    ScrollListener onScrollEnd,
    SnapOffsetCallback snapOffsetCallback,
    this.itemsWrap: false,
    this.itemsSnapAlignment: PageableListFlingBehavior.stopAtNextPage,
    this.onPageChanged,
    this.duration: const Duration(milliseconds: 200),
    this.curve: Curves.ease
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    scrollDirection: scrollDirection,
    scrollAnchor: scrollAnchor,
    onScrollStart: onScrollStart,
    onScroll: onScroll,
    onScrollEnd: onScrollEnd,
    snapOffsetCallback: snapOffsetCallback
  ) {
    assert(itemsSnapAlignment != null);
  }

  /// Whether the first item should be revealed after scrolling past the last item.
  final bool itemsWrap;

  /// Controls whether a fling always reveals the adjacent item or whether flings can traverse many items.
  final PageableListFlingBehavior itemsSnapAlignment;

  /// Called when the currently visible page changes.
  final ValueChanged<int> onPageChanged;

  /// The duration used when animating to a given page.
  final Duration duration;

  /// The animation curve to use when animating to a given page.
  final Curve curve;

  /// The number of items, one per page, to display.
  int get itemCount;
}

/// A widget that pages through an iterable list of children.
///
/// A [PageableList] displays a single child at a time. When being scrolled, it
/// can display adjacent pages, but when the user stops scrolling, it settles
/// its scroll offset to a value that shows a single page.
///
/// See also:
///
///  * [PageableLazyList], which pages through a lazily constructed list of
///    children.
class PageableList extends Pageable {
  /// Creates a widget that pages through an iterable list of children.
  ///
  /// The [scrollDirection], [scrollAnchor], and [itemsSnapAlignment] arguments
  /// must not be null.
  PageableList({
    Key key,
    double initialScrollOffset,
    Axis scrollDirection: Axis.vertical,
    ViewportAnchor scrollAnchor: ViewportAnchor.start,
    ScrollListener onScrollStart,
    ScrollListener onScroll,
    ScrollListener onScrollEnd,
    SnapOffsetCallback snapOffsetCallback,
    bool itemsWrap: false,
    PageableListFlingBehavior itemsSnapAlignment: PageableListFlingBehavior.stopAtNextPage,
    ValueChanged<int> onPageChanged,
    Duration duration: const Duration(milliseconds: 200),
    Curve curve: Curves.ease,
    this.children: const <Widget>[],
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    scrollDirection: scrollDirection,
    scrollAnchor: scrollAnchor,
    onScrollStart: onScrollStart,
    onScroll: onScroll,
    onScrollEnd: onScrollEnd,
    snapOffsetCallback: snapOffsetCallback,
    itemsWrap: itemsWrap,
    itemsSnapAlignment: itemsSnapAlignment,
    onPageChanged: onPageChanged,
    duration: duration,
    curve: curve
  );

  /// The list of pages themselves.
  final Iterable<Widget> children;

  @override
  int get itemCount => children?.length ?? 0;

  @override
  PageableListState<PageableList> createState() => new PageableListState<PageableList>();
}

/// A widget that pages through a lazily constructed list of children.
///
/// A [PageableList] displays a single child at a time. When being scrolled, it
/// can display adjacent pages, but when the user stops scrolling, it settles
/// its scroll offset to a value that shows a single page.
///
/// See also:
///
///  * [PageableList], which pages through an iterable list of children.
class PageableLazyList extends Pageable {
  /// Creates a widget that pages through a lazily constructed list of children.
  ///
  /// The [scrollDirection], [scrollAnchor], and [itemsSnapAlignment] arguments
  /// must not be null.
  PageableLazyList({
    Key key,
    double initialScrollOffset,
    Axis scrollDirection: Axis.vertical,
    ViewportAnchor scrollAnchor: ViewportAnchor.start,
    ScrollListener onScrollStart,
    ScrollListener onScroll,
    ScrollListener onScrollEnd,
    SnapOffsetCallback snapOffsetCallback,
    PageableListFlingBehavior itemsSnapAlignment: PageableListFlingBehavior.stopAtNextPage,
    ValueChanged<int> onPageChanged,
    Duration duration: const Duration(milliseconds: 200),
    Curve curve: Curves.ease,
    this.itemCount: 0,
    this.itemBuilder
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    scrollDirection: scrollDirection,
    scrollAnchor: scrollAnchor,
    onScrollStart: onScrollStart,
    onScroll: onScroll,
    onScrollEnd: onScrollEnd,
    snapOffsetCallback: snapOffsetCallback,
    itemsWrap: false,
    itemsSnapAlignment: itemsSnapAlignment,
    onPageChanged: onPageChanged,
    duration: duration,
    curve: curve
  );

  /// The total number of list items.
  @override
  final int itemCount;

  /// A function that returns the pages themselves.
  final ItemListBuilder itemBuilder;

  @override
  _PageableLazyListState createState() => new _PageableLazyListState();
}

/// State for widgets that subclass [Pageable].
///
/// Specializes [ScrollableState] to support page-based scrolling.
///
/// Subclasses typically override [buildContent] to build viewports.
abstract class PageableState<T extends Pageable> extends ScrollableState<T> {
  int get _itemCount => config.itemCount;
  int _previousItemCount;

  /// Convert from the item based scroll units to logical pixels.
  double get pixelsPerScrollUnit {
    final RenderBox box = context.findRenderObject();
    if (box == null || !box.hasSize)
      return 0.0;
    switch (config.scrollDirection) {
      case Axis.horizontal:
        return box.size.width;
      case Axis.vertical:
        return box.size.height;
    }
    assert(config.scrollDirection != null);
    return null;
  }

  @override
  double pixelOffsetToScrollOffset(double pixelOffset) {
    final double unit = pixelsPerScrollUnit;
    return super.pixelOffsetToScrollOffset(unit == 0.0 ? 0.0 : pixelOffset / unit);
  }

  @override
  double scrollOffsetToPixelOffset(double scrollOffset) {
    return super.scrollOffsetToPixelOffset(scrollOffset * pixelsPerScrollUnit);
  }

  int _scrollOffsetToPageIndex(double scrollOffset) {
    int itemCount = _itemCount;
    if (itemCount == 0)
      return 0;
    int scrollIndex = scrollOffset.floor();
    switch (config.scrollAnchor) {
      case ViewportAnchor.start:
        return scrollIndex % itemCount;
      case ViewportAnchor.end:
        return (_itemCount - scrollIndex - 1) % itemCount;
    }
    assert(config.scrollAnchor != null);
    return null;
  }

  @override
  void didUpdateConfig(Pageable oldConfig) {
    super.didUpdateConfig(oldConfig);

    bool scrollBehaviorUpdateNeeded = config.scrollDirection != oldConfig.scrollDirection;

    if (config.itemsWrap != oldConfig.itemsWrap)
      scrollBehaviorUpdateNeeded = true;

    if (_itemCount != _previousItemCount) {
      _previousItemCount = _itemCount;
      scrollBehaviorUpdateNeeded = true;
    }

    if (scrollBehaviorUpdateNeeded)
      _updateScrollBehavior();
  }

  void _updateScrollBehavior() {
    didUpdateScrollBehavior(scrollBehavior.updateExtents(
      contentExtent: _itemCount.toDouble(),
      containerExtent: 1.0,
      scrollOffset: scrollOffset
    ));
  }

  UnboundedBehavior _unboundedBehavior;
  OverscrollBehavior _overscrollBehavior;

  @override
  ExtentScrollBehavior get scrollBehavior {
    if (config.itemsWrap) {
      _unboundedBehavior ??= new UnboundedBehavior(platform: platform);
      return _unboundedBehavior;
    }
    _overscrollBehavior ??= new OverscrollBehavior(platform: platform);
    return _overscrollBehavior;
  }

  /// Returns the style of scrolling to use.
  ///
  /// By default, defers to the nearest [ScrollConfiguration].
  TargetPlatform get platform => ScrollConfiguration.of(context)?.platform;

  @override
  ExtentScrollBehavior createScrollBehavior() => scrollBehavior;

  @override
  bool get shouldSnapScrollOffset => config.itemsSnapAlignment == PageableListFlingBehavior.canFlingAcrossMultiplePages;

  @override
  double snapScrollOffset(double newScrollOffset) {
    final double previousItemOffset = newScrollOffset.floorToDouble();
    final double nextItemOffset = newScrollOffset.ceilToDouble();
    return (newScrollOffset - previousItemOffset < 0.5 ? previousItemOffset : nextItemOffset)
      .clamp(scrollBehavior.minScrollOffset, scrollBehavior.maxScrollOffset);
  }

  Future<Null> _flingToAdjacentItem(double scrollVelocity) {
    final double newScrollOffset = snapScrollOffset(scrollOffset + scrollVelocity.sign)
      .clamp(snapScrollOffset(scrollOffset - 0.50001), snapScrollOffset(scrollOffset + 0.5));
    return scrollTo(newScrollOffset, duration: config.duration, curve: config.curve)
      .then<Null>(_notifyPageChanged);
  }

  @override
  Future<Null> fling(double scrollVelocity) {
    switch(config.itemsSnapAlignment) {
      case PageableListFlingBehavior.canFlingAcrossMultiplePages:
        return (super.fling(scrollVelocity)).then<Null>(_notifyPageChanged);
      case PageableListFlingBehavior.stopAtNextPage:
        return _flingToAdjacentItem(scrollVelocity);
    }
    assert(config.itemsSnapAlignment != null);
    return null;
  }

  @override
  Future<Null> settleScrollOffset() {
    return scrollTo(snapScrollOffset(scrollOffset), duration: config.duration, curve: config.curve)
      .then<Null>(_notifyPageChanged);
  }

  void _notifyPageChanged(Null value) {
    if (config.onPageChanged != null)
      config.onPageChanged(_scrollOffsetToPageIndex(scrollOffset));
  }
}

/// State for a [PageableList] widget.
///
/// Widgets that subclass [PageableList] can subclass this class to have
/// sensible default behaviors for pageable lists.
class PageableListState<T extends PageableList> extends PageableState<T> {
  @override
  Widget buildContent(BuildContext context) {
    return new PageViewport(
      itemsWrap: config.itemsWrap,
      mainAxis: config.scrollDirection,
      anchor: config.scrollAnchor,
      startOffset: scrollOffset,
      children: config.children
    );
  }
}

class _PageableLazyListState extends PageableState<PageableLazyList> {
  @override
  Widget buildContent(BuildContext context) {
    return new LazyPageViewport(
      mainAxis: config.scrollDirection,
      anchor: config.scrollAnchor,
      startOffset: scrollOffset,
      itemCount: config.itemCount,
      itemBuilder: config.itemBuilder
    );
  }
}

class _VirtualPageViewport extends VirtualViewport {
  _VirtualPageViewport(
    this.startOffset,
    this.mainAxis,
    this.anchor,
    this.itemsWrap
  ) {
    assert(mainAxis != null);
    assert(anchor != null);
  }

  @override
  final double startOffset;

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

  /// Whether the first item should be revealed after scrolling past the last item.
  final bool itemsWrap;

  @override
  RenderList createRenderObject(BuildContext context) => new RenderList();

  @override
  _VirtualPageViewportElement createElement() => new _VirtualPageViewportElement(this);
}

class _VirtualPageViewportElement extends VirtualViewportElement {
  _VirtualPageViewportElement(_VirtualPageViewport widget) : super(widget);

  @override
  _VirtualPageViewport get widget => super.widget;

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
  double scrollOffsetToPixelOffset(double scrollOffset) {
    if (_containerExtent == null)
      return 0.0;
    return super.scrollOffsetToPixelOffset(scrollOffset) * _containerExtent;
  }

  @override
  void updateRenderObject(_VirtualPageViewport oldWidget) {
    renderObject
      ..mainAxis = widget.mainAxis;
    super.updateRenderObject(oldWidget);
  }

  double _containerExtent;

  void _updateViewportDimensions() {
    final Size containerSize = renderObject.size;

    Size materializedContentSize;
    switch (widget.mainAxis) {
      case Axis.vertical:
        materializedContentSize = new Size(containerSize.width, _materializedChildCount * containerSize.height);
        break;
      case Axis.horizontal:
        materializedContentSize = new Size(_materializedChildCount * containerSize.width, containerSize.height);
        break;
    }
    renderObject.dimensions = new ViewportDimensions(containerSize: containerSize, contentSize: materializedContentSize);
  }

  @override
  void layout(BoxConstraints constraints) {
    final int length = renderObject.virtualChildCount;

    switch (widget.mainAxis) {
      case Axis.vertical:
        _containerExtent = renderObject.size.height;
        break;
      case Axis.horizontal:
        _containerExtent =  renderObject.size.width;
        break;
    }

    if (length == 0) {
      _materializedChildBase = 0;
      _materializedChildCount = 0;
      _startOffsetBase = 0.0;
      _startOffsetLimit = double.INFINITY;
    } else {
      int startItem = widget.startOffset.floor();
      int limitItem = (widget.startOffset + 1.0).ceil();

      if (!widget.itemsWrap) {
        startItem = startItem.clamp(0, length);
        limitItem = limitItem.clamp(0, length);
      }

      _materializedChildBase = startItem;
      _materializedChildCount = limitItem - startItem;
      _startOffsetBase = startItem.toDouble();
      _startOffsetLimit = (limitItem - 1).toDouble();
      if (widget.anchor == ViewportAnchor.end)
        _materializedChildBase = (length - _materializedChildBase - _materializedChildCount) % length;
    }

    _updateViewportDimensions();
    super.layout(constraints);
  }
}

/// A virtual viewport that displays a single child at a time.
///
/// Useful for [Pageable] widgets.
///
/// One unit of start offset corresponds to one child widget, which means a
/// start offset of 2.75 indicates that the viewport is three quarters of the
/// way between the child with index 2 and the child with index 3.
///
/// [PageViewport] differs from [LazyPageViewport] in that [PageViewport] uses
/// an [Iterable] list of children. That makes [PageViewport] suitable for a
/// large (but not extremely large or infinite) list of children.
class PageViewport extends _VirtualPageViewport with VirtualViewportFromIterable {
  /// Creates a virtual viewport that displays a single child at a time.
  ///
  /// The [mainAxis] and [anchor] arguments must not be null.
  PageViewport({
    double startOffset: 0.0,
    Axis mainAxis: Axis.vertical,
    ViewportAnchor anchor: ViewportAnchor.start,
    bool itemsWrap: false,
    this.children: const <Widget>[],
  }) : super(
    startOffset,
    mainAxis,
    anchor,
    itemsWrap
  );

  @override
  final Iterable<Widget> children;
}

/// A virtual viewport that displays a single child at a time.
///
/// Useful for [Pageable] widgets.
///
/// One unit of start offset corresponds to one child widget, which means a
/// start offset of 2.75 indicates that the viewport is three quarters of the
/// way between the child with index 2 and the child with index 3.
///
/// [LazyPageViewport] differs from [PageViewport] in that [LazyPageViewport]
/// uses an [ItemListBuilder] to lazily create children. That makes
/// [LazyPageViewport] suitable for an extremely large or infinite list of
/// children but also makes it more verbose than [PageViewport].
class LazyPageViewport extends _VirtualPageViewport with VirtualViewportFromBuilder {
  /// Creates a virtual viewport that displays a single child at a time.
  ///
  /// The [mainAxis] and [anchor] arguments must not be null.
  LazyPageViewport({
    double startOffset: 0.0,
    Axis mainAxis: Axis.vertical,
    ViewportAnchor anchor: ViewportAnchor.start,
    this.itemCount,
    this.itemBuilder
  }) : super(
    startOffset,
    mainAxis,
    anchor,
    false // Don't support wrapping yet.
  );

  @override
  final int itemCount;

  @override
  final ItemListBuilder itemBuilder;
}
