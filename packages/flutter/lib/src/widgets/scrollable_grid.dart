// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:collection/collection.dart' show lowerBound;
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'framework.dart';
import 'scroll_configuration.dart';
import 'scrollable.dart';
import 'virtual_viewport.dart';

/// A vertically scrollable grid.
///
/// Requires that [delegate] places its children in row-major order.
///
/// See also:
///
///  * [CustomGrid].
///  * [ScrollableList].
///  * [ScrollableViewport].
class ScrollableGrid extends StatelessWidget {
  /// Creates a vertically scrollable grid.
  ///
  /// The [delegate] argument must not be null.
  ScrollableGrid({
    Key key,
    this.initialScrollOffset,
    this.onScrollStart,
    this.onScroll,
    this.onScrollEnd,
    this.snapOffsetCallback,
    this.scrollableKey,
    @required this.delegate,
    this.children
  }) : super(key: key) {
    assert(delegate != null);
  }

  // Warning: keep the dartdoc comments that follow in sync with the copies in
  // Scrollable, LazyBlock, ScrollableViewport, ScrollableList, and
  // ScrollableLazyList. And see: https://github.com/dart-lang/dartdoc/issues/1161.

  /// The scroll offset this widget should use when first created.
  final double initialScrollOffset;

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

  /// The delegate that controls the layout of the children.
  final GridDelegate delegate;

  /// The children that will be placed in the grid.
  final Iterable<Widget> children;

  Widget _buildViewport(BuildContext context, ScrollableState state) {
    return new GridViewport(
      scrollOffset: state.scrollOffset,
      delegate: delegate,
      onExtentsChanged: state.handleExtentsChanged,
      children: children
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget result = new Scrollable(
      key: scrollableKey,
      initialScrollOffset: initialScrollOffset,
      // TODO(abarth): Support horizontal offsets. For horizontally scrolling
      // grids. For horizontally scrolling grids, we'll probably need to use a
      // delegate that places children in column-major order.
      scrollDirection: Axis.vertical,
      onScrollStart: onScrollStart,
      onScroll: onScroll,
      onScrollEnd: onScrollEnd,
      snapOffsetCallback: snapOffsetCallback,
      builder: _buildViewport,
    );
    return ScrollConfiguration.wrap(context, result);
  }
}

/// A virtual viewport onto a grid of widgets.
///
/// Used by [ScrollableGrid].
///
/// See also:
///
///  * [ListViewport].
///  * [LazyListViewport].
class GridViewport extends VirtualViewportFromIterable {
  /// Creates a virtual viewport onto a grid of widgets.
  ///
  /// The [delegate] argument must not be null.
  GridViewport({
    this.scrollOffset,
    this.delegate,
    this.onExtentsChanged,
    this.children
  }) {
    assert(delegate != null);
  }

  /// The [startOffset] without taking the [delegate]'s padding into account.
  final double scrollOffset;

  @override
  double get startOffset {
    if (delegate == null)
      return scrollOffset;
    return scrollOffset - delegate.padding.top;
  }

  /// The delegate that controls the layout of the children.
  final GridDelegate delegate;

  /// Called when the interior or exterior dimensions of the viewport change.
  final ExtentsChangedCallback onExtentsChanged;

  @override
  final Iterable<Widget> children;

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
