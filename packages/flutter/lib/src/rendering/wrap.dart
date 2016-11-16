// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'box.dart';
import 'object.dart';

enum WrapAlignment {
  start,
  center,
  end,
  // TODO(ianh): justify
}

class WrapParentData extends ContainerBoxParentDataMixin<RenderBox> { }

class RenderWrap extends RenderBox with ContainerRenderObjectMixin<RenderBox, WrapParentData>,
                                        RenderBoxContainerDefaultsMixin<RenderBox, WrapParentData> {
  RenderWrap({
    List<RenderBox> children,
    Axis direction: Axis.horizontal,
    WrapAlignment mainAxisAlignment: WrapAlignment.center,
    WrapAlignment crossAxisAlignment: WrapAlignment.center,
    double spacing,
  }) : _direction = direction,
       _mainAxisAlignment = mainAxisAlignment,
       _crossAxisAlignment = crossAxisAlignment,
       _spacing = spacing {
    assert(direction != null);
    assert(mainAxisAlignment != null);
    assert(crossAxisAlignment != null);
    assert(spacing != null);
    addAll(children);
  }

  /// The direction to use as the main axis.
  // TODO(ianh): we should also support growing down vs growing up and growing left vs growing right
  Axis get direction => _direction;
  Axis _direction;
  set direction (Axis value) {
    assert(value != null);
    if (_direction != value) {
      _direction = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the main axis.
  WrapAlignment get mainAxisAlignment => _mainAxisAlignment;
  WrapAlignment _mainAxisAlignment;
  set mainAxisAlignment (WrapAlignment value) {
    assert(value != null);
    if (_mainAxisAlignment != value) {
      _mainAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the cross axis.
  WrapAlignment get crossAxisAlignment => _crossAxisAlignment;
  WrapAlignment _crossAxisAlignment;
  set crossAxisAlignment (WrapAlignment value) {
    assert(value != null);
    if (_crossAxisAlignment != value) {
      _crossAxisAlignment = value;
      markNeedsLayout();
    }
  }

  double get spacing => _spacing;
  double _spacing;
  set spacing (double value) {
    assert(value != null);
    if (_spacing != value) {
      _spacing = value;
      markNeedsLayout();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! WrapParentData)
      child.parentData = new WrapParentData();
  }

  // Do not change the child list while using one of these...
  Iterable<RenderBox> get _childIterator sync* {
    RenderBox child = firstChild;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
  }

  double _computeIntrinsicHeightForWidth(double maxWidth) {
    assert(_direction == Axis.horizontal);
    double result = 0.0;
    double rowHeight = 0.0;
    double rowWidth = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      double width = child.getMaxIntrinsicWidth(double.INFINITY);
      double height = child.getMaxIntrinsicHeight(width);
      rowWidth += width;
      if (rowWidth > maxWidth) {
        if (result > 0.0)
          result += spacing;
        result += rowHeight;
        rowHeight = height;
        rowWidth = width;
      } else {
        rowHeight = math.max(rowHeight, height);
      }
      child = childAfter(child);
    }
    if (result > 0.0)
      result += spacing;
    result += rowHeight;
    return result;
  }

  double _computeIntrinsicWidthForHeight(double maxHeight) {
    assert(_direction == Axis.vertical);
    double result = 0.0;
    double columnWidth = 0.0;
    double columnHeight = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      double height = child.getMaxIntrinsicHeight(double.INFINITY);
      double width = child.getMaxIntrinsicWidth(height);
      columnHeight += height;
      if (columnHeight > maxHeight) {
        if (result > 0.0)
          result += spacing;
        result += columnWidth;
        columnWidth = width;
        columnHeight = height;
      } else {
        columnWidth = math.max(columnWidth, width);
      }
      child = childAfter(child);
    }
    if (result > 0.0)
      result += spacing;
    result += columnWidth;
    return result;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    switch (_direction) {
      case Axis.horizontal:
        return _childIterator
                 .map/*<double>*/((RenderBox child) => child.getMinIntrinsicWidth(double.INFINITY))
                 .reduce((double value, double element) => math.max(value, element));
      case Axis.vertical:
        return _computeIntrinsicWidthForHeight(height);
    }
    return null;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    switch (_direction) {
      case Axis.horizontal:
        return _childIterator
                 .map/*<double>*/((RenderBox child) => child.getMaxIntrinsicWidth(double.INFINITY))
                 .reduce((double value, double element) => value + element);
      case Axis.vertical:
        return _computeIntrinsicWidthForHeight(height);
    }
    return null;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    switch (_direction) {
      case Axis.horizontal:
        return _computeIntrinsicHeightForWidth(width);
      case Axis.vertical:
        return _childIterator
                 .map/*<double>*/((RenderBox child) => child.getMinIntrinsicHeight(double.INFINITY))
                 .reduce((double value, double element) => math.max(value, element));
    }
    return null;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    switch (_direction) {
      case Axis.horizontal:
        return _computeIntrinsicHeightForWidth(width);
      case Axis.vertical:
        return _childIterator
                 .map/*<double>*/((RenderBox child) => child.getMaxIntrinsicHeight(double.INFINITY))
                 .reduce((double value, double element) => value + element);
    }
    return null;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  double _getCrossSize(RenderBox child) {
    switch (_direction) {
      case Axis.horizontal:
        return child.size.height;
      case Axis.vertical:
        return child.size.width;
    }
    return null;
  }

  double _getMainSize(RenderBox child) {
    switch (_direction) {
      case Axis.horizontal:
        return child.size.width;
      case Axis.vertical:
        return child.size.height;
    }
    return null;
  }

  @override
  void performLayout() {
    BoxConstraints childConstraints;
    double maxExtent;
    // TODO(ianh): Make the asserts below explain that there's no paint putting a Wrap in an unconstrained main axis (since then it's just a poor man's Flex).
    switch (_direction) {
      case Axis.horizontal:
        assert(constraints.maxWidth.isFinite);
        childConstraints = new BoxConstraints(maxWidth: constraints.maxWidth);
        maxExtent = constraints.maxWidth;
        break;
      case Axis.vertical:
        assert(constraints.maxHeight.isFinite);
        childConstraints = new BoxConstraints(maxHeight: constraints.maxHeight);
        maxExtent = constraints.maxHeight;
        break;
    }
    assert(childConstraints != null);
    assert(maxExtent != null);
    RenderBox child = firstChild;
    List<RenderBox> row = <RenderBox>[];
    double extent = 0.0;
    double maxCrossExtent = 0.0;
    Size maxSize = Size.zero;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      double childExtent = _getMainSize(child);
      if (extent + childExtent > maxExtent) {
        assert(row.isNotEmpty);
        maxSize = _fillRow(row, extent, maxExtent, maxCrossExtent, maxSize);
        row.clear();
        extent = childExtent;
        maxCrossExtent = _getCrossSize(child);
      } else {
        extent += childExtent;
        maxCrossExtent = math.max(maxCrossExtent, _getCrossSize(child));
      }
      row.add(child);
      child = childAfter(child);      
    }
    if (row.isNotEmpty)
      maxSize = _fillRow(row, extent, maxExtent, maxCrossExtent, maxSize);
    size = constraints.constrain(maxSize);
  }

  Size _fillRow(List<RenderBox> row, double extent, double maxExtent, double maxCrossExtent, Size maxSize) {
    double crossPosition;
    if (maxSize != Size.zero) {
      switch (_direction) {
        case Axis.horizontal:
          crossPosition = maxSize.height + spacing;
          break;
        case Axis.vertical:
          crossPosition = maxSize.width + spacing;
          break;
      }
    } else {
      crossPosition = 0.0;
    }
    double mainOffset;
    switch (mainAxisAlignment) {
      case WrapAlignment.start:
        mainOffset = 0.0;
        break;
      case WrapAlignment.center:
        mainOffset = (maxExtent - extent) / 2.0;
        break;
      case WrapAlignment.end:
        mainOffset = (maxExtent - extent);
        break;
    }
    assert(mainOffset != null);
    for (RenderBox child in row) {
      double crossOffset;
      switch (crossAxisAlignment) {
        case WrapAlignment.start:
          crossOffset = 0.0;
          break;
        case WrapAlignment.center:
          crossOffset = (maxCrossExtent - _getCrossSize(child)) / 2.0;
          break;
        case WrapAlignment.end:
          crossOffset = (maxCrossExtent - _getCrossSize(child));
          break;
      }
      WrapParentData childParentData = child.parentData;
      switch (_direction) {
        case Axis.horizontal:
          childParentData.offset = new Offset(mainOffset, crossPosition + crossOffset);
          break;
        case Axis.vertical:
          childParentData.offset = new Offset(crossPosition + crossOffset, mainOffset);
          break;
      }
      mainOffset += _getMainSize(child);
    }
    switch (_direction) {
      case Axis.horizontal:
        return new Size(
          maxExtent,
          crossPosition + maxCrossExtent,
        );
        break;
      case Axis.vertical:
        return new Size(
          crossPosition + maxCrossExtent,
          maxExtent,
        );
        break;
    }
    return null;
  }

  @override
  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('direction: $_direction');
    description.add('mainAxisAlignment: $_mainAxisAlignment');
    description.add('crossAxisAlignment: $_crossAxisAlignment');
  }
}
