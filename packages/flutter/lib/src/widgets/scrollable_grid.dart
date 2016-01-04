// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'basic.dart';
import 'framework.dart';
import 'scrollable.dart';

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

/// A vertically scrollable grid.
///
/// Requires that delegate places its children in row-major order.
class ScrollableGrid extends Scrollable {
  ScrollableGrid({
    Key key,
    double initialScrollOffset,
    ScrollListener onScroll,
    SnapOffsetCallback snapOffsetCallback,
    double snapAlignmentOffset: 0.0,
    this.delegate,
    this.children
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    // TODO(abarth): Support horizontal offsets. For horizontally scrolling
    // grids. For horizontally scrolling grids, we'll probably need to use a
    // delegate that places children in column-major order.
    scrollDirection: ScrollDirection.vertical,
    onScroll: onScroll,
    snapOffsetCallback: snapOffsetCallback,
    snapAlignmentOffset: snapAlignmentOffset
  );

  final GridDelegate delegate;
  final List<Widget> children;

  ScrollableState createState() => new _ScrollableGrid();
}

class _ScrollableGrid extends ScrollableState<ScrollableGrid> {
  ScrollBehavior createScrollBehavior() => new OverscrollWhenScrollableBehavior();
  ExtentScrollBehavior get scrollBehavior => super.scrollBehavior;

  void _handleExtentsChanged(double contentExtent, double containerExtent) {
    setState(() {
      scrollTo(scrollBehavior.updateExtents(
        contentExtent: contentExtent,
        containerExtent: containerExtent,
        scrollOffset: scrollOffset
      ));
    });
  }

  Widget buildContent(BuildContext context) {
    return new GridViewport(
      startOffset: scrollOffset,
      delegate: config.delegate,
      onExtentsChanged: _handleExtentsChanged,
      children: config.children
    );
  }
}

typedef void ExtentsChangedCallback(double contentExtent, double containerExtent);

class GridViewport extends RenderObjectWidget {
  GridViewport({
    Key key,
    this.startOffset,
    this.delegate,
    this.onExtentsChanged,
    this.children
  });

  final double startOffset;
  final GridDelegate delegate;
  final ExtentsChangedCallback onExtentsChanged;
  final List<Widget> children;

  RenderGrid createRenderObject() => new RenderGrid(delegate: delegate);

  _GridViewportElement createElement() => new _GridViewportElement(this);
}

// TODO(abarth): This function should go somewhere more general.
int _lowerBound(List sortedList, var value, { int begin: 0 }) {
  int current = begin;
  int count = sortedList.length - current;
  while (count > 0) {
    int step = count >> 1;
    int test = current + step;
    if (sortedList[test] < value) {
      current = test + 1;
      count -= step + 1;
    } else {
      count = step;
    }
  }
  return current;
}

class _GridViewportElement extends RenderObjectElement<GridViewport> {
  _GridViewportElement(GridViewport widget) : super(widget);

  double _contentExtent;
  double _containerExtent;

  int _materializedChildBase;
  int _materializedChildCount;

  List<Element> _materializedChildren = const <Element>[];

  GridSpecification _specification;
  double _repaintOffsetBase;
  double _repaintOffsetLimit;

  RenderGrid get renderObject => super.renderObject;

  void visitChildren(ElementVisitor visitor) {
    if (_materializedChildren == null)
      return;
    for (Element child in _materializedChildren)
      visitor(child);
  }

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    renderObject.callback = layout;
    _updateRenderObject();
  }

  void unmount() {
    renderObject.callback = null;
    super.unmount();
  }

  void update(GridViewport newWidget) {
    super.update(newWidget);
    _updateRenderObject();
    if (!renderObject.needsLayout)
      _materializeChildren();
  }

  void _updatePaintOffset() {
    renderObject.paintOffset = new Offset(0.0, -(widget.startOffset - _repaintOffsetBase));
  }

  void _updateRenderObject() {
    renderObject.delegate = widget.delegate;
    renderObject.virtualChildCount = widget.children.length;

    if (_specification != null) {
      _updatePaintOffset();

      // If we don't already need layout, we need to request a layout if the
      // viewport has shifted to expose a new row.
      if (!renderObject.needsLayout) {
        if (_repaintOffsetBase != null && widget.startOffset < _repaintOffsetBase)
          renderObject.markNeedsLayout();
        else if (_repaintOffsetLimit != null && widget.startOffset + _containerExtent > _repaintOffsetLimit)
          renderObject.markNeedsLayout();
      }
    }
  }

  void _materializeChildren() {
    assert(_materializedChildBase != null);
    assert(_materializedChildCount != null);
    List<Widget> newWidgets = new List<Widget>(_materializedChildCount);
    for (int i = 0; i < _materializedChildCount; ++i) {
      int childIndex = _materializedChildBase + i;
      Widget child = widget.children[childIndex];
      Key key = new ValueKey(child.key ?? childIndex);
      newWidgets[i] = new RepaintBoundary(key: key, child: child);
    }
    _materializedChildren = updateChildren(_materializedChildren, newWidgets);
  }

  void layout(BoxConstraints constraints) {
    _specification = renderObject.specification;
    double contentExtent = _specification.gridSize.height;
    double containerExtent = renderObject.size.height;

    int materializedRowBase = math.max(0, _lowerBound(_specification.rowOffsets, widget.startOffset) - 1);
    int materializedRowLimit = math.min(_specification.rowCount, _lowerBound(_specification.rowOffsets, widget.startOffset + containerExtent));

    _materializedChildBase = materializedRowBase * _specification.columnCount;
    _materializedChildCount = math.min(widget.children.length, materializedRowLimit * _specification.columnCount) - _materializedChildBase;
    _repaintOffsetBase = _specification.rowOffsets[materializedRowBase];
    _repaintOffsetLimit = _specification.rowOffsets[materializedRowLimit];
    _updatePaintOffset();

    BuildableElement.lockState(_materializeChildren);

    if (contentExtent != _contentExtent || containerExtent != _containerExtent) {
      _contentExtent = contentExtent;
      _containerExtent = containerExtent;
      widget.onExtentsChanged(_contentExtent, _containerExtent);
    }
  }

  void insertChildRenderObject(RenderObject child, Element slot) {
    RenderObject nextSibling = slot?.renderObject;
    renderObject.add(child, before: nextSibling);
  }

  void moveChildRenderObject(RenderObject child, Element slot) {
    assert(child.parent == renderObject);
    RenderObject nextSibling = slot?.renderObject;
    renderObject.move(child, before: nextSibling);
  }

  void removeChildRenderObject(RenderObject child) {
    assert(child.parent == renderObject);
    renderObject.remove(child);
  }
}
