// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'box.dart';
import 'layer.dart';
import 'layout_helper.dart';
import 'object.dart';

/// How [Wrap] should align objects.
///
/// Used both to align children within a run in the main axis as well as to
/// align the runs themselves in the cross axis.
enum WrapAlignment {
  /// Place the objects as close to the start of the axis as possible.
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the start is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the start is the top or the bottom.
  start,

  /// Place the objects as close to the end of the axis as possible.
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the end is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the end is the top or the bottom.
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
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the start is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the start is the top or the bottom.
  start,

  /// Place the children as close to the end of the run in the cross axis as
  /// possible.
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the end is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the end is the top or the bottom.
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
class RenderWrap extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, WrapParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, WrapParentData> {
  /// Creates a wrap render object.
  ///
  /// By default, the wrap layout is horizontal and both the children and the
  /// runs are aligned to the start.
  RenderWrap({
    List<RenderBox>? children,
    Axis direction = Axis.horizontal,
    WrapAlignment alignment = WrapAlignment.start,
    double spacing = 0.0,
    WrapAlignment runAlignment = WrapAlignment.start,
    double runSpacing = 0.0,
    WrapCrossAlignment crossAxisAlignment = WrapCrossAlignment.start,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    Clip clipBehavior = Clip.none,
  }) : assert(direction != null),
       assert(alignment != null),
       assert(spacing != null),
       assert(runAlignment != null),
       assert(runSpacing != null),
       assert(crossAxisAlignment != null),
       assert(clipBehavior != null),
       _direction = direction,
       _alignment = alignment,
       _spacing = spacing,
       _runAlignment = runAlignment,
       _runSpacing = runSpacing,
       _crossAxisAlignment = crossAxisAlignment,
       _textDirection = textDirection,
       _verticalDirection = verticalDirection,
       _clipBehavior = clipBehavior {
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

  /// How the children within a run should be placed in the main axis.
  ///
  /// For example, if [alignment] is [WrapAlignment.center], the children in
  /// each run are grouped together in the center of their run in the main axis.
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
  /// grouped together in the center of the overall [RenderWrap] in the cross
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

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the order in which
  /// children are positioned (left-to-right or right-to-left), and the meaning
  /// of the [alignment] property's [WrapAlignment.start] and
  /// [WrapAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [alignment] is either [WrapAlignment.start] or [WrapAlignment.end], or
  /// there's more than one child, then the [textDirection] must not be null.
  ///
  /// If the [direction] is [Axis.vertical], this controls the order in
  /// which runs are positioned, the meaning of the [runAlignment] property's
  /// [WrapAlignment.start] and [WrapAlignment.end] values, as well as the
  /// [crossAxisAlignment] property's [WrapCrossAlignment.start] and
  /// [WrapCrossAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the
  /// [runAlignment] is either [WrapAlignment.start] or [WrapAlignment.end], the
  /// [crossAxisAlignment] is either [WrapCrossAlignment.start] or
  /// [WrapCrossAlignment.end], or there's more than one child, then the
  /// [textDirection] must not be null.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  /// Determines the order to lay children out vertically and how to interpret
  /// `start` and `end` in the vertical direction.
  ///
  /// If the [direction] is [Axis.vertical], this controls which order children
  /// are painted in (down or up), the meaning of the [alignment] property's
  /// [WrapAlignment.start] and [WrapAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the [alignment]
  /// is either [WrapAlignment.start] or [WrapAlignment.end], or there's
  /// more than one child, then the [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the order in which
  /// runs are positioned, the meaning of the [runAlignment] property's
  /// [WrapAlignment.start] and [WrapAlignment.end] values, as well as the
  /// [crossAxisAlignment] property's [WrapCrossAlignment.start] and
  /// [WrapCrossAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [runAlignment] is either [WrapAlignment.start] or [WrapAlignment.end], the
  /// [crossAxisAlignment] is either [WrapCrossAlignment.start] or
  /// [WrapCrossAlignment.end], or there's more than one child, then the
  /// [verticalDirection] must not be null.
  VerticalDirection get verticalDirection => _verticalDirection;
  VerticalDirection _verticalDirection;
  set verticalDirection(VerticalDirection value) {
    if (_verticalDirection != value) {
      _verticalDirection = value;
      markNeedsLayout();
    }
  }

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;
  set clipBehavior(Clip value) {
    assert(value != null);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  bool get _debugHasNecessaryDirections {
    assert(direction != null);
    assert(alignment != null);
    assert(runAlignment != null);
    assert(crossAxisAlignment != null);
    if (firstChild != null && lastChild != firstChild) {
      // i.e. there's more than one child
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null, 'Horizontal $runtimeType with multiple children has a null textDirection, so the layout order is undefined.');
          break;
        case Axis.vertical:
          assert(verticalDirection != null, 'Vertical $runtimeType with multiple children has a null verticalDirection, so the layout order is undefined.');
          break;
      }
    }
    if (alignment == WrapAlignment.start || alignment == WrapAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null, 'Horizontal $runtimeType with alignment $alignment has a null textDirection, so the alignment cannot be resolved.');
          break;
        case Axis.vertical:
          assert(verticalDirection != null, 'Vertical $runtimeType with alignment $alignment has a null verticalDirection, so the alignment cannot be resolved.');
          break;
      }
    }
    if (runAlignment == WrapAlignment.start || runAlignment == WrapAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          assert(verticalDirection != null, 'Horizontal $runtimeType with runAlignment $runAlignment has a null verticalDirection, so the alignment cannot be resolved.');
          break;
        case Axis.vertical:
          assert(textDirection != null, 'Vertical $runtimeType with runAlignment $runAlignment has a null textDirection, so the alignment cannot be resolved.');
          break;
      }
    }
    if (crossAxisAlignment == WrapCrossAlignment.start || crossAxisAlignment == WrapCrossAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          assert(verticalDirection != null, 'Horizontal $runtimeType with crossAxisAlignment $crossAxisAlignment has a null verticalDirection, so the alignment cannot be resolved.');
          break;
        case Axis.vertical:
          assert(textDirection != null, 'Vertical $runtimeType with crossAxisAlignment $crossAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
          break;
      }
    }
    return true;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! WrapParentData)
      child.parentData = WrapParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    switch (direction) {
      case Axis.horizontal:
        double width = 0.0;
        RenderBox? child = firstChild;
        while (child != null) {
          width = math.max(width, child.getMinIntrinsicWidth(double.infinity));
          child = childAfter(child);
        }
        return width;
      case Axis.vertical:
        return computeDryLayout(BoxConstraints(maxHeight: height)).width;
    }
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    switch (direction) {
      case Axis.horizontal:
        double width = 0.0;
        RenderBox? child = firstChild;
        while (child != null) {
          width += child.getMaxIntrinsicWidth(double.infinity);
          child = childAfter(child);
        }
        return width;
      case Axis.vertical:
        return computeDryLayout(BoxConstraints(maxHeight: height)).width;
    }
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    switch (direction) {
      case Axis.horizontal:
        return computeDryLayout(BoxConstraints(maxWidth: width)).height;
      case Axis.vertical:
        double height = 0.0;
        RenderBox? child = firstChild;
        while (child != null) {
          height = math.max(height, child.getMinIntrinsicHeight(double.infinity));
          child = childAfter(child);
        }
        return height;
    }
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    switch (direction) {
      case Axis.horizontal:
        return computeDryLayout(BoxConstraints(maxWidth: width)).height;
      case Axis.vertical:
        double height = 0.0;
        RenderBox? child = firstChild;
        while (child != null) {
          height += child.getMaxIntrinsicHeight(double.infinity);
          child = childAfter(child);
        }
        return height;
    }
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  double _getMainAxisExtent(Size childSize) {
    switch (direction) {
      case Axis.horizontal:
        return childSize.width;
      case Axis.vertical:
        return childSize.height;
    }
  }

  double _getCrossAxisExtent(Size childSize) {
    switch (direction) {
      case Axis.horizontal:
        return childSize.height;
      case Axis.vertical:
        return childSize.width;
    }
  }

  Offset _getOffset(double mainAxisOffset, double crossAxisOffset) {
    switch (direction) {
      case Axis.horizontal:
        return Offset(mainAxisOffset, crossAxisOffset);
      case Axis.vertical:
        return Offset(crossAxisOffset, mainAxisOffset);
    }
  }

  double _getChildCrossAxisOffset(bool flipCrossAxis, double runCrossAxisExtent, double childCrossAxisExtent) {
    final double freeSpace = runCrossAxisExtent - childCrossAxisExtent;
    switch (crossAxisAlignment) {
      case WrapCrossAlignment.start:
        return flipCrossAxis ? freeSpace : 0.0;
      case WrapCrossAlignment.end:
        return flipCrossAxis ? 0.0 : freeSpace;
      case WrapCrossAlignment.center:
        return freeSpace / 2.0;
    }
  }

  bool _hasVisualOverflow = false;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _computeDryLayout(constraints);
  }

  Size _computeDryLayout(BoxConstraints constraints, [ChildLayouter layoutChild = ChildLayoutHelper.dryLayoutChild]) {
    final BoxConstraints childConstraints;
    double mainAxisLimit = 0.0;
    switch (direction) {
      case Axis.horizontal:
        childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
        mainAxisLimit = constraints.maxWidth;
        break;
      case Axis.vertical:
        childConstraints = BoxConstraints(maxHeight: constraints.maxHeight);
        mainAxisLimit = constraints.maxHeight;
        break;
    }

    double mainAxisExtent = 0.0;
    double crossAxisExtent = 0.0;
    double runMainAxisExtent = 0.0;
    double runCrossAxisExtent = 0.0;
    int childCount = 0;
    RenderBox? child = firstChild;
    while (child != null) {
      final Size childSize = layoutChild(child, childConstraints);
      final double childMainAxisExtent = _getMainAxisExtent(childSize);
      final double childCrossAxisExtent = _getCrossAxisExtent(childSize);
      // There must be at least one child before we move on to the next run.
      if (childCount > 0 && runMainAxisExtent + childMainAxisExtent + spacing > mainAxisLimit) {
        mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);
        crossAxisExtent += runCrossAxisExtent + runSpacing;
        runMainAxisExtent = 0.0;
        runCrossAxisExtent = 0.0;
        childCount = 0;
      }
      runMainAxisExtent += childMainAxisExtent;
      runCrossAxisExtent = math.max(runCrossAxisExtent, childCrossAxisExtent);
      if (childCount > 0)
        runMainAxisExtent += spacing;
      childCount += 1;
      child = childAfter(child);
    }
    crossAxisExtent += runCrossAxisExtent;
    mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);

    switch (direction) {
      case Axis.horizontal:
        return constraints.constrain(Size(mainAxisExtent, crossAxisExtent));
      case Axis.vertical:
        return constraints.constrain(Size(crossAxisExtent, mainAxisExtent));
    }
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    assert(_debugHasNecessaryDirections);
    _hasVisualOverflow = false;
    RenderBox? child = firstChild;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final BoxConstraints childConstraints;
    double mainAxisLimit = 0.0;
    bool flipMainAxis = false;
    bool flipCrossAxis = false;
    switch (direction) {
      case Axis.horizontal:
        childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
        mainAxisLimit = constraints.maxWidth;
        if (textDirection == TextDirection.rtl)
          flipMainAxis = true;
        if (verticalDirection == VerticalDirection.up)
          flipCrossAxis = true;
        break;
      case Axis.vertical:
        childConstraints = BoxConstraints(maxHeight: constraints.maxHeight);
        mainAxisLimit = constraints.maxHeight;
        if (verticalDirection == VerticalDirection.up)
          flipMainAxis = true;
        if (textDirection == TextDirection.rtl)
          flipCrossAxis = true;
        break;
    }
    assert(childConstraints != null);
    assert(mainAxisLimit != null);
    final double spacing = this.spacing;
    final double runSpacing = this.runSpacing;
    final List<_RunMetrics> runMetrics = <_RunMetrics>[];
    double mainAxisExtent = 0.0;
    double crossAxisExtent = 0.0;
    double runMainAxisExtent = 0.0;
    double runCrossAxisExtent = 0.0;
    int childCount = 0;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      final double childMainAxisExtent = _getMainAxisExtent(child.size);
      final double childCrossAxisExtent = _getCrossAxisExtent(child.size);
      if (childCount > 0 && runMainAxisExtent + spacing + childMainAxisExtent > mainAxisLimit) {
        mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);
        crossAxisExtent += runCrossAxisExtent;
        if (runMetrics.isNotEmpty)
          crossAxisExtent += runSpacing;
        runMetrics.add(_RunMetrics(runMainAxisExtent, runCrossAxisExtent, childCount));
        runMainAxisExtent = 0.0;
        runCrossAxisExtent = 0.0;
        childCount = 0;
      }
      runMainAxisExtent += childMainAxisExtent;
      if (childCount > 0)
        runMainAxisExtent += spacing;
      runCrossAxisExtent = math.max(runCrossAxisExtent, childCrossAxisExtent);
      childCount += 1;
      final WrapParentData childParentData = child.parentData! as WrapParentData;
      childParentData._runIndex = runMetrics.length;
      child = childParentData.nextSibling;
    }
    if (childCount > 0) {
      mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);
      crossAxisExtent += runCrossAxisExtent;
      if (runMetrics.isNotEmpty)
        crossAxisExtent += runSpacing;
      runMetrics.add(_RunMetrics(runMainAxisExtent, runCrossAxisExtent, childCount));
    }

    final int runCount = runMetrics.length;
    assert(runCount > 0);

    double containerMainAxisExtent = 0.0;
    double containerCrossAxisExtent = 0.0;

    switch (direction) {
      case Axis.horizontal:
        size = constraints.constrain(Size(mainAxisExtent, crossAxisExtent));
        containerMainAxisExtent = size.width;
        containerCrossAxisExtent = size.height;
        break;
      case Axis.vertical:
        size = constraints.constrain(Size(crossAxisExtent, mainAxisExtent));
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

    runBetweenSpace += runSpacing;
    double crossAxisOffset = flipCrossAxis ? containerCrossAxisExtent - runLeadingSpace : runLeadingSpace;

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

      childBetweenSpace += spacing;
      double childMainPosition = flipMainAxis ? containerMainAxisExtent - childLeadingSpace : childLeadingSpace;

      if (flipCrossAxis)
        crossAxisOffset -= runCrossAxisExtent;

      while (child != null) {
        final WrapParentData childParentData = child.parentData! as WrapParentData;
        if (childParentData._runIndex != i)
          break;
        final double childMainAxisExtent = _getMainAxisExtent(child.size);
        final double childCrossAxisExtent = _getCrossAxisExtent(child.size);
        final double childCrossAxisOffset = _getChildCrossAxisOffset(flipCrossAxis, runCrossAxisExtent, childCrossAxisExtent);
        if (flipMainAxis)
          childMainPosition -= childMainAxisExtent;
        childParentData.offset = _getOffset(childMainPosition, crossAxisOffset + childCrossAxisOffset);
        if (flipMainAxis)
          childMainPosition -= childBetweenSpace;
        else
          childMainPosition += childMainAxisExtent + childBetweenSpace;
        child = childParentData.nextSibling;
      }

      if (flipCrossAxis)
        crossAxisOffset -= runBetweenSpace;
      else
        crossAxisOffset += runCrossAxisExtent + runBetweenSpace;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // TODO(ianh): move the debug flex overflow paint logic somewhere common so
    // it can be reused here
    if (_hasVisualOverflow && clipBehavior != Clip.none) {
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        defaultPaint,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      defaultPaint(context, offset);
    }
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('direction', direction));
    properties.add(EnumProperty<WrapAlignment>('alignment', alignment));
    properties.add(DoubleProperty('spacing', spacing));
    properties.add(EnumProperty<WrapAlignment>('runAlignment', runAlignment));
    properties.add(DoubleProperty('runSpacing', runSpacing));
    properties.add(DoubleProperty('crossAxisAlignment', runSpacing));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(EnumProperty<VerticalDirection>('verticalDirection', verticalDirection, defaultValue: VerticalDirection.down));
  }
}
