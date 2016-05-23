// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:collection/collection.dart' show lowerBound;
import 'package:flutter/rendering.dart';

import 'clamp_overscrolls.dart';
import 'framework.dart';
import 'scroll_configuration.dart';
import 'scrollable.dart';
import 'virtual_viewport.dart';

/// A vertically scrollable grid.
///
/// Requires that delegate places its children in row-major order.
class ScrollableGrid extends StatelessWidget {
  ScrollableGrid({
    Key key,
    this.initialScrollOffset,
    this.onScrollStart,
    this.onScroll,
    this.onScrollEnd,
    this.snapOffsetCallback,
    this.scrollableKey,
    this.delegate,
    this.children
  }) : super(key: key);

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

  final GridDelegate delegate;
  final Iterable<Widget> children;

  void _handleExtentsChanged(ScrollableState state, double contentExtent, double containerExtent) {
    state.setState(() {
      state.didUpdateScrollBehavior(state.scrollBehavior.updateExtents(
        contentExtent: contentExtent,
        containerExtent: containerExtent,
        scrollOffset: state.scrollOffset
      ));
    });
  }

  Widget _buildViewport(BuildContext context, ScrollableState state, double scrollOffset) {
    return new GridViewport(
      startOffset: scrollOffset,
      delegate: delegate,
      onExtentsChanged: (double contentExtent, double containerExtent) {
        _handleExtentsChanged(state, contentExtent, containerExtent);
      },
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
      // TODO(abarth): Support horizontal offsets. For horizontally scrolling
      // grids. For horizontally scrolling grids, we'll probably need to use a
      // delegate that places children in column-major order.
      scrollDirection: Axis.vertical,
      onScrollStart: onScrollStart,
      onScroll: onScroll,
      onScrollEnd: onScrollEnd,
      snapOffsetCallback: snapOffsetCallback,
      builder: _buildContent
    );
    return ScrollConfiguration.wrap(context, result);
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
