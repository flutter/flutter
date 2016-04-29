// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'framework.dart';
import 'scroll_behavior.dart';
import 'scrollable.dart';
import 'virtual_viewport.dart';

import 'package:flutter/rendering.dart';

/// If true, the ClampOverscroll's [Scrollable] descendant will clamp its
/// viewport's scrollOffsets to the [ScrollBehavior]'s min and max values.
/// In this case the Scrollable's scrollOffset will still over and undershoot
/// the ScrollBehavior's limits, but the viewport itself will not.
class ClampOverscrolls extends InheritedWidget {
  ClampOverscrolls({
    Key key,
    this.value,
    Widget child
  }) : super(key: key, child: child) {
    assert(value != null);
    assert(child != null);
  }

  /// True if the [Scrollable] descendant should clamp its viewport's scrollOffset
  /// values when they are less than the [ScrollBehavior]'s minimum or greater than
  /// its maximum.
  final bool value;

  static bool of(BuildContext context) {
    final ClampOverscrolls result = context.inheritFromWidgetOfExactType(ClampOverscrolls);
    return result?.value ?? false;
  }

  @override
  bool updateShouldNotify(ClampOverscrolls old) => value != old.value;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('value: $value');
  }
}

class ScrollableList extends Scrollable {
  ScrollableList({
    Key key,
    double initialScrollOffset,
    Axis scrollDirection: Axis.vertical,
    ViewportAnchor scrollAnchor: ViewportAnchor.start,
    ScrollListener onScrollStart,
    ScrollListener onScroll,
    ScrollListener onScrollEnd,
    SnapOffsetCallback snapOffsetCallback,
    this.itemExtent,
    this.itemsWrap: false,
    this.padding,
    this.children
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
    assert(itemExtent != null);
  }

  final double itemExtent;
  final bool itemsWrap;

  /// The amount of space by which to inset the children inside the viewport.
  final EdgeInsets padding;

  final Iterable<Widget> children;

  @override
  ScrollableState createState() => new _ScrollableListState();
}

class _ScrollableListState extends ScrollableState<ScrollableList> {
  @override
  ExtentScrollBehavior createScrollBehavior() => new OverscrollWhenScrollableBehavior();

  @override
  ExtentScrollBehavior get scrollBehavior => super.scrollBehavior;

  void _handleExtentsChanged(double contentExtent, double containerExtent) {
    setState(() {
      didUpdateScrollBehavior(scrollBehavior.updateExtents(
        contentExtent: config.itemsWrap ? double.INFINITY : contentExtent,
        containerExtent: containerExtent,
        scrollOffset: scrollOffset
      ));
    });
  }

  @override
  Widget buildContent(BuildContext context) {
    final bool clampOverscrolls = ClampOverscrolls.of(context);
    final double listScrollOffset = clampOverscrolls
      ? scrollOffset.clamp(scrollBehavior.minScrollOffset, scrollBehavior.maxScrollOffset)
      : scrollOffset;
    Widget viewport = new ListViewport(
      onExtentsChanged: _handleExtentsChanged,
      scrollOffset: listScrollOffset,
      mainAxis: config.scrollDirection,
      anchor: config.scrollAnchor,
      itemExtent: config.itemExtent,
      itemsWrap: config.itemsWrap,
      padding: config.padding,
      children: config.children
    );
    if (clampOverscrolls)
      viewport = new ClampOverscrolls(value: false, child: viewport);
    return viewport;
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
    this.padding,
    this.overlayPainter
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
  final RenderObjectPainter overlayPainter;

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
      ..padding = widget.padding
      ..overlayPainter = widget.overlayPainter;
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
    RenderObjectPainter overlayPainter,
    this.children
  }) : super(
    onExtentsChanged,
    scrollOffset,
    mainAxis,
    anchor,
    itemExtent,
    itemsWrap,
    padding,
    overlayPainter
  );

  @override
  final Iterable<Widget> children;
}

/// An optimized scrollable widget for a large number of children that are all
/// the same size (extent) in the scrollDirection. For example for
/// ScrollDirection.vertical itemExtent is the height of each item. Use this
/// widget when you have a large number of children or when you are concerned
/// about offscreen widgets consuming resources.
class ScrollableLazyList extends Scrollable {
  ScrollableLazyList({
    Key key,
    double initialScrollOffset,
    Axis scrollDirection: Axis.vertical,
    ViewportAnchor scrollAnchor: ViewportAnchor.start,
    ScrollListener onScroll,
    SnapOffsetCallback snapOffsetCallback,
    this.itemExtent,
    this.itemCount,
    this.itemBuilder,
    this.padding
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    scrollDirection: scrollDirection,
    scrollAnchor: scrollAnchor,
    onScroll: onScroll,
    snapOffsetCallback: snapOffsetCallback
  ) {
    assert(itemExtent != null);
    assert(itemBuilder != null);
    assert(itemCount != null || scrollAnchor == ViewportAnchor.start);
  }

  final double itemExtent;
  final int itemCount;
  final ItemListBuilder itemBuilder;

  /// The amount of space by which to inset the children inside the viewport.
  final EdgeInsets padding;

  @override
  ScrollableState createState() => new _ScrollableLazyListState();
}

class _ScrollableLazyListState extends ScrollableState<ScrollableLazyList> {
  @override
  ExtentScrollBehavior createScrollBehavior() => new OverscrollBehavior();

  @override
  ExtentScrollBehavior get scrollBehavior => super.scrollBehavior;

  void _handleExtentsChanged(double contentExtent, double containerExtent) {
    setState(() {
      didUpdateScrollBehavior(scrollBehavior.updateExtents(
        contentExtent: contentExtent,
        containerExtent: containerExtent,
        scrollOffset: scrollOffset
      ));
    });
  }

  @override
  Widget buildContent(BuildContext context) {
    return new LazyListViewport(
      onExtentsChanged: _handleExtentsChanged,
      scrollOffset: scrollOffset,
      mainAxis: config.scrollDirection,
      anchor: config.scrollAnchor,
      itemExtent: config.itemExtent,
      itemCount: config.itemCount,
      itemBuilder: config.itemBuilder,
      padding: config.padding
    );
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
    RenderObjectPainter overlayPainter,
    this.itemCount,
    this.itemBuilder
  }) : super(
    onExtentsChanged,
    scrollOffset,
    mainAxis,
    anchor,
    itemExtent,
    false, // Don't support wrapping yet.
    padding,
    overlayPainter
  );

  @override
  final int itemCount;

  @override
  final ItemListBuilder itemBuilder;
}
