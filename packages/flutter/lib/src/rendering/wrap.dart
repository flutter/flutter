// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'box.dart';
import 'object.dart';

/// How [Wrap] should align objects.
///
/// Used both to align children within a run in the main axis as well as to
/// align the runs themselves in the cross axis.
enum WrapAlignment {
  /// Place the objects as close to the start of the axis as possible.
  start,

  /// Place the objects as close to the end of the axis as possible.
  end,

  /// Place the objects as close to the middle of the axis as possible.
  center,

  /// Place the free space evenly between the objects.
  spaceBetween,

  /// Place the free space evenly between the objects as well as half of that
  /// space before and after the first and last objects.
  spaceAround,

  /// Place the free space evenly between the objects as well as before and
  /// after the first and last objects.
  spaceEvenly,
}

/// Who [Wrap] should align children within a run in the cross axis.
enum WrapCrossAlignment {
  /// Place the children as close to the start of the run in the cross axis as
  /// possible.
  start,

  /// Place the children as close to the end of the run in the cross axis as
  /// possible.
  end,

  /// Place the children as close to the middle of the run in the cross axis as
  /// possible.
  center,

  // TODO(ianh): baseline.
}

class _RunMetrics {
  _RunMetrics(this.mainAxisExtent, this.crossAxisExtent, this.childCount);

  final double mainAxisExtent;
  final double crossAxisExtent;
  final int childCount;
}

/// Parent data for use with [RenderWrap].
class WrapParentData extends ContainerBoxParentData<RenderBox> {
  int _runIndex = 0;
}

/// Displays its children in multiple horizontal or vertical runs.
///
/// A [RenderWrap] lays out each child and attempts to place the child adjacent
/// to the previous child in the main axis, given by [direction], leaving
/// [spacing] space in between. If there is not enough space to fit the child,
/// [RenderWrap] creates a new _run_ adjacent to the existing children in the
/// cross axis.
///
/// After all the children have been allocated to runs, the children within the
/// runs are positioned according to the [alignment] in the main axis and
/// according to the [crossAxisAlignment] in the cross axis.
///
/// The runs themselves are then positioned in the cross axis according to the
/// [runSpacing] and [runAlignment].
class RenderWrap extends RenderBox with ContainerRenderObjectMixin<RenderBox, WrapParentData>,
                                        RenderBoxContainerDefaultsMixin<RenderBox, WrapParentData> {
  /// Creates a wrap render object.
  ///
  /// By default, the wrap layout is horizontal and both the children and the
  /// runs are aligned to the start.
  RenderWrap({
    List<RenderBox> children,
    Axis direction: Axis.horizontal,
    WrapAlignment alignment: WrapAlignment.start,
    double spacing: 0.0,
    WrapAlignment runAlignment: WrapAlignment.start,
    double runSpacing: 0.0,
    WrapCrossAlignment crossAxisAlignment: WrapCrossAlignment.start,
  }) : _direction = direction,
       _alignment = alignment,
       _spacing = spacing,
       _runAlignment = runAlignment,
       _runSpacing = runSpacing,
       _crossAxisAlignment = crossAxisAlignment {
    assert(direction != null);
    assert(alignment != null);
    assert(spacing != null);
    assert(runAlignment != null);
    assert(runSpacing != null);
    assert(crossAxisAlignment != null);
    addAll(children);
  }

  /// The direction to use as the main axis.
  ///
  /// For example, if [direction] is [Axis.horizontal], the default, the
  /// children are placed adjacent to one another in a horizontal run until the
  /// available horizontal space is consumed, at which point a subsequent
  /// children are placed in a new run vertically adjacent to the previous run.
  Axis get direction => _direction;
  Axis _direction;
  set direction (Axis value) {
    assert(value != null);
    if (_direction == value)
      return;
    _direction = value;
    markNeedsLayout();
  }

  /// How the children within a run should be places in the main axis.
  ///
  /// For example, if [alignment] is [WrapAlignment.center], the children in
  /// each run are grouped togeter in the center of their run in the main axis.
  ///
  /// Defaults to [WrapAlignment.start].
  ///
  /// See also:
  ///
  ///  * [runAlignment], which controls how the runs are placed relative to each
  ///    other in the cross axis.
  ///  * [crossAxisAlignment], which controls how the children within each run
  ///    are placed relative to each other in the cross axis.
  WrapAlignment get alignment => _alignment;
  WrapAlignment _alignment;
  set alignment (WrapAlignment value) {
    assert(value != null);
    if (_alignment == value)
      return;
    _alignment = value;
    markNeedsLayout();
  }

  /// How much space to place between children in a run in the main axis.
  ///
  /// For example, if [spacing] is 10.0, the children will be spaced at least
  /// 10.0 logical pixels apart in the main axis.
  ///
  /// If there is additional free space in a run (e.g., because the wrap has a
  /// minimum size that is not filled or because some runs are longer than
  /// others), the additional free space will be allocated according to the
  /// [alignment].
  ///
  /// Defaults to 0.0.
  double get spacing => _spacing;
  double _spacing;
  set spacing (double value) {
    assert(value != null);
    if (_spacing == value)
      return;
    _spacing = value;
    markNeedsLayout();
  }

  /// How the runs themselves should be placed in the cross axis.
  ///
  /// For example, if [runAlignment] is [WrapAlignment.center], the runs are
  /// grouped togeter in the center of the overall [RenderWrap] in the cross
  /// axis.
  ///
  /// Defaults to [WrapAlignment.start].
  ///
  /// See also:
  ///
  ///  * [alignment], which controls how the children within each run are placed
  ///    relative to each other in the main axis.
  ///  * [crossAxisAlignment], which controls how the children within each run
  ///    are placed relative to each other in the cross axis.
  WrapAlignment get runAlignment => _runAlignment;
  WrapAlignment _runAlignment;
  set runAlignment (WrapAlignment value) {
    assert(value != null);
    if (_runAlignment == value)
      return;
    _runAlignment = value;
    markNeedsLayout();
  }

  /// How much space to place between the runs themselves in the cross axis.
  ///
  /// For example, if [runSpacing] is 10.0, the runs will be spaced at least
  /// 10.0 logical pixels apart in the cross axis.
  ///
  /// If there is additional free space in the overall [RenderWrap] (e.g.,
  /// because the wrap has a minimum size that is not filled), the additional
  /// free space will be allocated according to the [runAlignment].
  ///
  /// Defaults to 0.0.
  double get runSpacing => _runSpacing;
  double _runSpacing;
  set runSpacing (double value) {
    assert(value != null);
    if (_runSpacing == value)
      return;
    _runSpacing = value;
    markNeedsLayout();
  }

  /// How the children within a run should be aligned relative to each other in
  /// the cross axis.
  ///
  /// For example, if this is set to [WrapCrossAlignment.end], and the
  /// [direction] is [Axis.horizontal], then the children within each
  /// run will have their bottom edges aligned to the bottom edge of the run.
  ///
  /// Defaults to [WrapCrossAlignment.start].
  ///
  /// See also:
  ///
  ///  * [alignment], which controls how the children within each run are placed
  ///    relative to each other in the main axis.
  ///  * [runAlignment], which controls how the runs are placed relative to each
  ///    other in the cross axis.
  WrapCrossAlignment get crossAxisAlignment => _crossAxisAlignment;
  WrapCrossAlignment _crossAxisAlignment;
  set crossAxisAlignment (WrapCrossAlignment value) {
    assert(value != null);
    if (_crossAxisAlignment == value)
      return;
    _crossAxisAlignment = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! WrapParentData)
      child.parentData = new WrapParentData();
  }

  double _computeIntrinsicHeightForWidth(double width) {
    assert(direction == Axis.horizontal);
    int runCount = 0;
    double height = 0.0;
    double runWidth = 0.0;
    double runHeight = 0.0;
    int childCount = 0;
    RenderBox child = firstChild;
    while (child != null) {
      final double childWidth = child.getMaxIntrinsicWidth(double.INFINITY);
      final double childHeight = child.getMaxIntrinsicHeight(childWidth);
      if (runWidth + childWidth > width) {
        height += runHeight;
        if (runCount > 0)
          height += runSpacing;
        runCount += 1;
        runWidth = 0.0;
        runHeight = 0.0;
        childCount = 0;
      }
      runWidth += childWidth;
      runHeight = math.max(runHeight, childHeight);
      if (childCount > 0)
        runWidth += spacing;
      childCount += 1;
      child = childAfter(child);
    }
    if (childCount > 0)
      height += runHeight + runSpacing;
    return height;
  }

  double _computeIntrinsicWidthForHeight(double height) {
    assert(direction == Axis.vertical);
    int runCount = 0;
    double width = 0.0;
    double runHeight = 0.0;
    double runWidth = 0.0;
    int childCount = 0;
    RenderBox child = firstChild;
    while (child != null) {
      final double childHeight = child.getMaxIntrinsicHeight(double.INFINITY);
      final double childWidth = child.getMaxIntrinsicWidth(childHeight);
      if (runHeight + childHeight > height) {
        width += runWidth;
        if (runCount > 0)
          width += runSpacing;
        runCount += 1;
        runHeight = 0.0;
        runWidth = 0.0;
        childCount = 0;
      }
      runHeight += childHeight;
      runWidth = math.max(runWidth, childWidth);
      if (childCount > 0)
        runHeight += spacing;
      childCount += 1;
      child = childAfter(child);
    }
    if (childCount > 0)
      width += runWidth + runSpacing;
    return width;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    switch (direction) {
      case Axis.horizontal:
        double width = 0.0;
        RenderBox child = firstChild;
        while (child != null) {
          width = math.max(width, child.getMinIntrinsicWidth(double.INFINITY));
          child = childAfter(child);
        }
        return width;
      case Axis.vertical:
        return _computeIntrinsicWidthForHeight(height);
    }
    return null;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    switch (direction) {
      case Axis.horizontal:
        double width = 0.0;
        RenderBox child = firstChild;
        while (child != null) {
          width += child.getMaxIntrinsicWidth(double.INFINITY);
          child = childAfter(child);
        }
        return width;
      case Axis.vertical:
        return _computeIntrinsicWidthForHeight(height);
    }
    return null;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    switch (direction) {
      case Axis.horizontal:
        return _computeIntrinsicHeightForWidth(width);
      case Axis.vertical:
        double height = 0.0;
        RenderBox child = firstChild;
        while (child != null) {
          height = math.max(height, child.getMinIntrinsicHeight(double.INFINITY));
          child = childAfter(child);
        }
        return height;
    }
    return null;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    switch (direction) {
      case Axis.horizontal:
        return _computeIntrinsicHeightForWidth(width);
      case Axis.vertical:
        double height = 0.0;
        RenderBox child = firstChild;
        while (child != null) {
          height += child.getMaxIntrinsicHeight(double.INFINITY);
          child = childAfter(child);
        }
        return height;
    }
    return null;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  double _getMainAxisExtent(RenderBox child) {
    switch (direction) {
      case Axis.horizontal:
        return child.size.width;
      case Axis.vertical:
        return child.size.height;
    }
    return 0.0;
  }

  double _getCrossAxisExtent(RenderBox child) {
    switch (direction) {
      case Axis.horizontal:
        return child.size.height;
      case Axis.vertical:
        return child.size.width;
    }
    return 0.0;
  }

  Offset _getOffset(double mainAxisOffset, double crossAxisOffset) {
    switch (direction) {
      case Axis.horizontal:
        return new Offset(mainAxisOffset, crossAxisOffset);
      case Axis.vertical:
        return new Offset(crossAxisOffset, mainAxisOffset);
    }
    return Offset.zero;
  }

  double _getChildCrossAxisOffset(double runCrossAxisExtent, double childCrossAxisExtent) {
    switch (crossAxisAlignment) {
      case WrapCrossAlignment.start:
        return 0.0;
      case WrapCrossAlignment.center:
        return (runCrossAxisExtent - childCrossAxisExtent) / 2.0;
      case WrapCrossAlignment.end:
        return (runCrossAxisExtent - childCrossAxisExtent);
    }
    return 0.0;
  }

  bool _hasVisualOverflow = false;

  @override
  void performLayout() {
    _hasVisualOverflow = false;
    RenderBox child = firstChild;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    BoxConstraints childConstraints;
    double mainAxisLimit = 0.0;
    switch (direction) {
      case Axis.horizontal:
        childConstraints = new BoxConstraints(maxWidth: constraints.maxWidth);
        mainAxisLimit = constraints.maxWidth;
        break;
      case Axis.vertical:
        childConstraints = new BoxConstraints(maxHeight: constraints.maxHeight);
        mainAxisLimit = constraints.maxHeight;
        break;
    }
    assert(childConstraints != null);
    assert(mainAxisLimit != null);
    final List<_RunMetrics> runMetrics = <_RunMetrics>[];
    double mainAxisExtent = 0.0;
    double crossAxisExtent = 0.0;
    double runMainAxisExtent = 0.0;
    double runCrossAxisExtent = 0.0;
    int childCount = 0;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      final double childMainAxisExtent = _getMainAxisExtent(child);
      final double childCrossAxisExtent = _getCrossAxisExtent(child);
      if (runMainAxisExtent + childMainAxisExtent > mainAxisLimit) {
        assert(childCount > 0);
        mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);
        crossAxisExtent += runCrossAxisExtent;
        if (runMetrics.isNotEmpty)
          crossAxisExtent += runSpacing;
        runMetrics.add(new _RunMetrics(runMainAxisExtent, runCrossAxisExtent, childCount));
        runMainAxisExtent = 0.0;
        runCrossAxisExtent = 0.0;
        childCount = 0;
      }
      runMainAxisExtent += childMainAxisExtent;
      if (childCount > 0)
        runMainAxisExtent += spacing;
      runCrossAxisExtent = math.max(runCrossAxisExtent, childCrossAxisExtent);
      childCount += 1;
      final WrapParentData childParentData = child.parentData;
      childParentData._runIndex = runMetrics.length;
      child = childParentData.nextSibling;
    }
    if (childCount > 0) {
      mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);
      crossAxisExtent += runCrossAxisExtent + runSpacing;
      runMetrics.add(new _RunMetrics(runMainAxisExtent, runCrossAxisExtent, childCount));
    }

    final int runCount = runMetrics.length;
    assert(runCount > 0);

    double containerMainAxisExtent = 0.0;
    double containerCrossAxisExtent = 0.0;

    switch (direction) {
      case Axis.horizontal:
        size = constraints.constrain(new Size(mainAxisExtent, crossAxisExtent));
        containerMainAxisExtent = size.width;
        containerCrossAxisExtent = size.height;
        break;
      case Axis.vertical:
        size = constraints.constrain(new Size(crossAxisExtent, mainAxisExtent));
        containerMainAxisExtent = size.height;
        containerCrossAxisExtent = size.width;
        break;
    }

    _hasVisualOverflow = containerMainAxisExtent < mainAxisExtent || containerCrossAxisExtent < crossAxisExtent;

    final double crossAxisFreeSpace = math.max(0.0, containerCrossAxisExtent - crossAxisExtent);
    double runLeadingSpace = 0.0;
    double runBetweenSpace = 0.0;
    switch (runAlignment) {
      case WrapAlignment.start:
        break;
      case WrapAlignment.end:
        runLeadingSpace = crossAxisFreeSpace;
        break;
      case WrapAlignment.center:
        runLeadingSpace = crossAxisFreeSpace / 2.0;
        break;
      case WrapAlignment.spaceBetween:
        runBetweenSpace = runCount > 1 ? crossAxisFreeSpace / (runCount - 1) : 0.0;
        break;
      case WrapAlignment.spaceAround:
        runBetweenSpace = crossAxisFreeSpace / runCount;
        runLeadingSpace = runBetweenSpace / 2.0;
        break;
      case WrapAlignment.spaceEvenly:
        runBetweenSpace = crossAxisFreeSpace / (runCount + 1);
        runLeadingSpace = runBetweenSpace;
        break;
    }

    double crossAxisOffset = runLeadingSpace;
    child = firstChild;
    for (int i = 0; i < runCount; ++i) {
      final _RunMetrics metrics = runMetrics[i];
      final double runMainAxisExtent = metrics.mainAxisExtent;
      final double runCrossAxisExtent = metrics.crossAxisExtent;
      final int childCount = metrics.childCount;

      final double mainAxisFreeSpace = math.max(0.0, containerMainAxisExtent - runMainAxisExtent);
      double childLeadingSpace = 0.0;
      double childBetweenSpace = 0.0;

      switch (alignment) {
        case WrapAlignment.start:
          break;
        case WrapAlignment.end:
          childLeadingSpace = mainAxisFreeSpace;
          break;
        case WrapAlignment.center:
          childLeadingSpace = mainAxisFreeSpace / 2.0;
          break;
        case WrapAlignment.spaceBetween:
          childBetweenSpace = childCount > 1 ? mainAxisFreeSpace / (childCount - 1) : 0.0;
          break;
        case WrapAlignment.spaceAround:
          childBetweenSpace = mainAxisFreeSpace / childCount;
          childLeadingSpace = childBetweenSpace / 2.0;
          break;
        case WrapAlignment.spaceEvenly:
          childBetweenSpace = mainAxisFreeSpace / (childCount + 1);
          childLeadingSpace = childBetweenSpace;
          break;
      }

      double childMainAxisOffset = childLeadingSpace;
      while (child != null) {
        final WrapParentData childParentData = child.parentData;
        if (childParentData._runIndex != i)
          break;
        final double childMainAxisExtent = _getMainAxisExtent(child);
        final double childCrossAxisExtent = _getCrossAxisExtent(child);
        final double childCrossAxisOffset = _getChildCrossAxisOffset(runCrossAxisExtent, childCrossAxisExtent);
        childParentData.offset = _getOffset(childMainAxisOffset, crossAxisOffset + childCrossAxisOffset);
        childMainAxisOffset += childMainAxisExtent + spacing + childBetweenSpace;
        child = childParentData.nextSibling;
      }

      crossAxisOffset += runCrossAxisExtent + runSpacing + runBetweenSpace;
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // TODO(ianh): move the debug flex overflow paint logic somewhere common so
    // it can be reused here
    if (_hasVisualOverflow)
      context.pushClipRect(needsCompositing, offset, Offset.zero & size, defaultPaint);
    else
      defaultPaint(context, offset);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('direction: $direction');
    description.add('alignment: $alignment');
    description.add('spacing: $spacing');
    description.add('runAlignment: $runAlignment');
    description.add('runSpacing: $runSpacing');
    description.add('crossAxisAlignment: $runSpacing');
  }
}
