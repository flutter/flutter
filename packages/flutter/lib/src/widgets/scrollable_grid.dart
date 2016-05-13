// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:collection/collection.dart' show lowerBound;
import 'package:flutter/rendering.dart';

import 'clamp_overscrolls.dart';
import 'framework.dart';
import 'scroll_behavior.dart';
import 'scrollable.dart';
import 'virtual_viewport.dart';

/// A vertically scrollable grid.
///
/// Requires that delegate places its children in row-major order.
class ScrollableGrid extends Scrollable {
  ScrollableGrid({
    Key key,
    double initialScrollOffset,
    ScrollListener onScrollStart,
    ScrollListener onScroll,
    ScrollListener onScrollEnd,
    SnapOffsetCallback snapOffsetCallback,
    this.delegate,
    this.children
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    // TODO(abarth): Support horizontal offsets. For horizontally scrolling
    // grids. For horizontally scrolling grids, we'll probably need to use a
    // delegate that places children in column-major order.
    scrollDirection: Axis.vertical,
    onScrollStart: onScrollStart,
    onScroll: onScroll,
    onScrollEnd: onScrollEnd,
    snapOffsetCallback: snapOffsetCallback
  );

  final GridDelegate delegate;
  final Iterable<Widget> children;

  @override
  ScrollableState createState() => new _ScrollableGridState();
}

class _ScrollableGridState extends ScrollableState<ScrollableGrid> {
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
    final bool clampOverscrolls = ClampOverscrolls.of(context);
    final double clampedScrollOffset = clampOverscrolls
      ? scrollOffset.clamp(scrollBehavior.minScrollOffset, scrollBehavior.maxScrollOffset)
      : scrollOffset;
    return new GridViewport(
      startOffset: clampedScrollOffset,
      delegate: config.delegate,
      onExtentsChanged: _handleExtentsChanged,
      children: config.children
    );
  }
}

class GridViewport extends VirtualViewportFromIterable {
  GridViewport({
    this.startOffset,
    this.delegate,
    this.onExtentsChanged,
    this.children
  });

  @override
  final double startOffset;
  final GridDelegate delegate;
  final ExtentsChangedCallback onExtentsChanged;

  @override
  final Iterable<Widget> children;

  // TODO(abarth): Support horizontal grids.
  Axis get mainAxis => Axis.vertical;

  @override
  RenderGrid createRenderObject(BuildContext context) => new RenderGrid(delegate: delegate);

  @override
  _GridViewportElement createElement() => new _GridViewportElement(this);
}

class _GridViewportElement extends VirtualViewportElement {
  _GridViewportElement(GridViewport widget) : super(widget);

  @override
  GridViewport get widget => super.widget;

  @override
  RenderGrid get renderObject => super.renderObject;

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
  void updateRenderObject(GridViewport oldWidget) {
    renderObject.delegate = widget.delegate;
    super.updateRenderObject(oldWidget);
  }

  double _lastReportedContentExtent;
  double _lastReportedContainerExtent;
  GridSpecification _specification;

  @override
  void layout(BoxConstraints constraints) {
    _specification = renderObject.specification;
    double contentExtent = _specification.gridSize.height;
    double containerExtent = renderObject.size.height;

    int materializedRowBase = math.max(0, lowerBound(_specification.rowOffsets, widget.startOffset) - 1);
    int materializedRowLimit = math.min(_specification.rowCount, lowerBound(_specification.rowOffsets, widget.startOffset + containerExtent));

    _materializedChildBase = (materializedRowBase * _specification.columnCount).clamp(0, renderObject.virtualChildCount);
    _materializedChildCount = (materializedRowLimit * _specification.columnCount).clamp(0, renderObject.virtualChildCount) - _materializedChildBase;
    _startOffsetBase = _specification.rowOffsets[materializedRowBase];
    _startOffsetLimit = _specification.rowOffsets[materializedRowLimit] - containerExtent;

    super.layout(constraints);

    if (contentExtent != _lastReportedContentExtent || containerExtent != _lastReportedContainerExtent) {
      _lastReportedContentExtent = contentExtent;
      _lastReportedContainerExtent = containerExtent;
      widget.onExtentsChanged(_lastReportedContentExtent, _lastReportedContainerExtent);
    }
  }
}
