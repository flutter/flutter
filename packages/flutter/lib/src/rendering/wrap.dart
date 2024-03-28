// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

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

/// How the child is inscribed into the available space.
///
/// See also:
///
///  * [RenderWrap], the wrap render object.
///  * [Wrap], the wrap widget.
///  * [Wrapped], the widget to set the [WrapFit].
enum WrapFit {
  /// The child is placed either in the current or the next run, depending on
  /// its min intrinsic size in the [Wrap.direction].
  /// Within this run, it is forced to fill the entire run, unless the [Wrap]
  /// has no max size constraint in the run direction.
  ///
  /// This setting is more expensive, because it also computes the minimal
  /// size of the child. Avoid using it for complex children.
  ///
  /// The [Wrapped] widget assigns this kind of [WrapFit] to its child.
  runTight(true),

  /// The child is placed either in the current or the next run, depending on
  /// its min intrinsic size in the [Wrap.direction].
  ///
  /// This setting is more expensive, because it also computes the minimal
  /// size of the child. Avoid using it for complex children.
  runLoose(false),

  /// The child is forced to fill the available space in a new run, unless the
  /// [Wrap] has no max size constraint in the run direction.
  tight(true),

  /// The child can at most fill the available space in an empty run and is
  /// placed base on its size and the remaining space.
  ///
  /// This is the default behavior for a child of [Wrap].
  loose(false);

  const WrapFit(this.isTight);

  /// `true` if the [WrapFit] forces the child to fill the assigned run.
  final bool isTight;

  /// `true` if the [WrapFit] allows the child to only fill the assigned run
  /// partially.
  bool get isLoose => !isTight;
}

/// Parent data for use with [RenderWrap].
class WrapParentData extends ContainerBoxParentData<RenderBox> {
  int _runIndex = 0;

  /// How a wrapped child is inscribed into the available space of the current
  /// or an empty run.
  WrapFit fit = WrapFit.loose;
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
  }) : _direction = direction,
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
    if (_direction == value) {
      return;
    }
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
    if (_alignment == value) {
      return;
    }
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
    if (_spacing == value) {
      return;
    }
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
    if (_runAlignment == value) {
      return;
    }
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
    if (_runSpacing == value) {
      return;
    }
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
    if (_crossAxisAlignment == value) {
      return;
    }
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
  /// Defaults to [Clip.none].
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  bool get _debugHasNecessaryDirections {
    if (firstChild != null && lastChild != firstChild) {
      // i.e. there's more than one child
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null, 'Horizontal $runtimeType with multiple children has a null textDirection, so the layout order is undefined.');
        case Axis.vertical:
          break;
      }
    }
    if (alignment == WrapAlignment.start || alignment == WrapAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null, 'Horizontal $runtimeType with alignment $alignment has a null textDirection, so the alignment cannot be resolved.');
        case Axis.vertical:
          break;
      }
    }
    if (runAlignment == WrapAlignment.start || runAlignment == WrapAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          break;
        case Axis.vertical:
          assert(textDirection != null, 'Vertical $runtimeType with runAlignment $runAlignment has a null textDirection, so the alignment cannot be resolved.');
      }
    }
    if (crossAxisAlignment == WrapCrossAlignment.start || crossAxisAlignment == WrapCrossAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          break;
        case Axis.vertical:
          assert(textDirection != null, 'Vertical $runtimeType with crossAxisAlignment $crossAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
      }
    }
    return true;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! WrapParentData) {
      child.parentData = WrapParentData();
    }
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
        return getDryLayout(BoxConstraints(maxHeight: height)).width;
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
        return getDryLayout(BoxConstraints(maxHeight: height)).width;
    }
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    switch (direction) {
      case Axis.horizontal:
        return getDryLayout(BoxConstraints(maxWidth: width)).height;
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
        return getDryLayout(BoxConstraints(maxWidth: width)).height;
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

  double _getMainAxisExtent(Size childSize) => _getMainAxisExtentInDirection(childSize, direction);

  static double _getMainAxisExtentInDirection(Size childSize, Axis direction) {
    return switch (direction) {
      Axis.horizontal => childSize.width,
      Axis.vertical => childSize.height,
    };
  }

  double _getCrossAxisExtent(Size childSize) => _getCrossAxisExtentInDirection(childSize, direction);

  static double _getCrossAxisExtentInDirection(Size childSize, Axis direction) {
    return switch (direction) {
      Axis.horizontal => childSize.height,
      Axis.vertical => childSize.width,
    };
  }

  Offset _getOffset(double mainAxisOffset, double crossAxisOffset) {
    return switch (direction) {
      Axis.horizontal => Offset(mainAxisOffset, crossAxisOffset),
      Axis.vertical   => Offset(crossAxisOffset, mainAxisOffset),
    };
  }

  double _getChildCrossAxisOffset(bool flipCrossAxis, double runCrossAxisExtent, double childCrossAxisExtent) {
    final double freeSpace = runCrossAxisExtent - childCrossAxisExtent;
    return switch (crossAxisAlignment) {
      WrapCrossAlignment.start  => flipCrossAxis ? freeSpace : 0.0,
      WrapCrossAlignment.end    => flipCrossAxis ? 0.0 : freeSpace,
      WrapCrossAlignment.center => freeSpace / 2.0,
    };
  }

  bool _hasVisualOverflow = false;

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final (:double crossAxisExtent, :double mainAxisExtent, runCount: _) = _computeLayout(
      layoutChild: ChildLayoutHelper.dryLayoutChild,
      next: (RenderBox child, WrapParentData parentData) => childAfter(child),
      direction: direction, constraints: constraints, firstChild: firstChild, spacing: spacing, runSpacing: runSpacing,
    );

    return constraints.constrain(switch (direction) {
      Axis.horizontal => Size(mainAxisExtent, crossAxisExtent),
      Axis.vertical   => Size(crossAxisExtent, mainAxisExtent),
    });
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    assert(_debugHasNecessaryDirections);
    _hasVisualOverflow = false;
    if (firstChild == null) {
      size = constraints.smallest;
      return;
    }
    bool flipMainAxis = false;
    bool flipCrossAxis = false;
    final double spacing = this.spacing;
    final double runSpacing = this.runSpacing;
    switch (direction) {
      case Axis.horizontal:
        if (textDirection == TextDirection.rtl) {
          flipMainAxis = true;
        }
        if (verticalDirection == VerticalDirection.up) {
          flipCrossAxis = true;
        }
      case Axis.vertical:
        if (verticalDirection == VerticalDirection.up) {
          flipMainAxis = true;
        }
        if (textDirection == TextDirection.rtl) {
          flipCrossAxis = true;
        }
    }
    final List<_RunMetrics> runMetrics = <_RunMetrics>[];

    final (:double crossAxisExtent, :double mainAxisExtent, :int runCount) = _computeLayout(
      layoutChild: (RenderBox child, BoxConstraints constraints) {
        child.layout(constraints, parentUsesSize: true);
        return child.size;
      },
      next: (RenderBox child, WrapParentData parentData) => parentData.nextSibling,
      onRunFinished: ({required int childCount, required double runCrossAxisExtent, required double runMainAxisExtent}) {
        runMetrics.add(_RunMetrics(runMainAxisExtent, runCrossAxisExtent, childCount));
      },
      onLayoutChild: (WrapParentData parentData, int runIndex) {
        parentData._runIndex = runIndex;
      },
      direction: direction, constraints: constraints, firstChild: firstChild, spacing: spacing, runSpacing: runSpacing,
    );

    assert(runCount > 0);

    double containerMainAxisExtent = 0.0;
    double containerCrossAxisExtent = 0.0;

    switch (direction) {
      case Axis.horizontal:
        size = constraints.constrain(Size(mainAxisExtent, crossAxisExtent));
        containerMainAxisExtent = size.width;
        containerCrossAxisExtent = size.height;
      case Axis.vertical:
        size = constraints.constrain(Size(crossAxisExtent, mainAxisExtent));
        containerMainAxisExtent = size.height;
        containerCrossAxisExtent = size.width;
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
      case WrapAlignment.center:
        runLeadingSpace = crossAxisFreeSpace / 2.0;
      case WrapAlignment.spaceBetween:
        runBetweenSpace = runCount > 1 ? crossAxisFreeSpace / (runCount - 1) : 0.0;
      case WrapAlignment.spaceAround:
        runBetweenSpace = crossAxisFreeSpace / runCount;
        runLeadingSpace = runBetweenSpace / 2.0;
      case WrapAlignment.spaceEvenly:
        runBetweenSpace = crossAxisFreeSpace / (runCount + 1);
        runLeadingSpace = runBetweenSpace;
    }

    runBetweenSpace += runSpacing;
    double crossAxisOffset = flipCrossAxis ? containerCrossAxisExtent - runLeadingSpace : runLeadingSpace;

    RenderBox? child = firstChild;
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
        case WrapAlignment.center:
          childLeadingSpace = mainAxisFreeSpace / 2.0;
        case WrapAlignment.spaceBetween:
          childBetweenSpace = childCount > 1 ? mainAxisFreeSpace / (childCount - 1) : 0.0;
        case WrapAlignment.spaceAround:
          childBetweenSpace = mainAxisFreeSpace / childCount;
          childLeadingSpace = childBetweenSpace / 2.0;
        case WrapAlignment.spaceEvenly:
          childBetweenSpace = mainAxisFreeSpace / (childCount + 1);
          childLeadingSpace = childBetweenSpace;
      }

      childBetweenSpace += spacing;
      double childMainPosition = flipMainAxis ? containerMainAxisExtent - childLeadingSpace : childLeadingSpace;

      if (flipCrossAxis) {
        crossAxisOffset -= runCrossAxisExtent;
      }

      while (child != null) {
        final WrapParentData childParentData = child.parentData! as WrapParentData;
        if (childParentData._runIndex != i) {
          break;
        }
        final double childMainAxisExtent = _getMainAxisExtent(child.size);
        final double childCrossAxisExtent = _getCrossAxisExtent(child.size);
        final double childCrossAxisOffset = _getChildCrossAxisOffset(flipCrossAxis, runCrossAxisExtent, childCrossAxisExtent);
        if (flipMainAxis) {
          childMainPosition -= childMainAxisExtent;
        }
        childParentData.offset = _getOffset(childMainPosition, crossAxisOffset + childCrossAxisOffset);
        if (flipMainAxis) {
          childMainPosition -= childBetweenSpace;
        } else {
          childMainPosition += childMainAxisExtent + childBetweenSpace;
        }
        child = childParentData.nextSibling;
      }

      if (flipCrossAxis) {
        crossAxisOffset -= runBetweenSpace;
      } else {
        crossAxisOffset += runCrossAxisExtent + runBetweenSpace;
      }
    }
  }

  /// This function computes the layout of a [Wrap] without side effects.
  /// It is for computing the dry layout as well as performing the layout.
  static ({double mainAxisExtent, double crossAxisExtent, int runCount}) _computeLayout({
    required ChildLayouter layoutChild,
    required RenderBox? Function(RenderBox child, WrapParentData parentData) next,
    void Function({required double runMainAxisExtent, required double runCrossAxisExtent, required int childCount})? onRunFinished,
    void Function(WrapParentData parentData, int runIndex)? onLayoutChild,
    required Axis direction,
    required BoxConstraints constraints,
    required RenderBox? firstChild,
    required double spacing,
    required double runSpacing,
  }) {
    final BoxConstraints childConstraintsLoose;
    final BoxConstraints childConstraintsTight;
    double mainAxisLimit = 0.0;
    final double Function(RenderBox child, double crossAxisSize) getChildMinIntrinsicMainAxisExtent;
    final BoxConstraints Function(double maxSize) childConstraintsFittingLooseInRun;
    final BoxConstraints Function(double maxSize) childConstraintsFittingTightInRun;

    switch (direction) {
      case Axis.horizontal:
        childConstraintsLoose = BoxConstraints(maxWidth: constraints.maxWidth);
        childConstraintsTight = BoxConstraints(minWidth: constraints.maxWidth, maxWidth: constraints.maxWidth);
        mainAxisLimit = constraints.maxWidth;
        getChildMinIntrinsicMainAxisExtent = (RenderBox child, double crossAxisSize) => child.getMinIntrinsicWidth(crossAxisSize);
        childConstraintsFittingLooseInRun = (double maxSize) => BoxConstraints(maxWidth: maxSize);
        childConstraintsFittingTightInRun = (double maxSize) => BoxConstraints(minWidth: maxSize, maxWidth: maxSize);
      case Axis.vertical:
        childConstraintsLoose = BoxConstraints(maxHeight: constraints.maxHeight);
        childConstraintsTight = BoxConstraints(minHeight: constraints.maxHeight, maxHeight: constraints.maxHeight);
        mainAxisLimit = constraints.maxHeight;
        getChildMinIntrinsicMainAxisExtent = (RenderBox child, double crossAxisSize) => child.getMinIntrinsicHeight(crossAxisSize);
        childConstraintsFittingLooseInRun = (double maxSize) => BoxConstraints(maxHeight: maxSize);
        childConstraintsFittingTightInRun = (double maxSize) => BoxConstraints(minHeight: maxSize, maxHeight: maxSize);
    }

    double mainAxisExtent = 0.0;
    double crossAxisExtent = 0.0;
    double runMainAxisExtent = 0.0;
    double runCrossAxisExtent = 0.0;

    RenderBox? child = firstChild;
    int childCount = 0; // Number of children in the current run.
    int runCount = 0; // Number of finished runs.

    while (child != null) {
      final WrapParentData childParentData = child.parentData! as WrapParentData;
      WrapFit fit = childParentData.fit;

      // Downgrade the [WrapFit] in an unbound scenario.
      if (mainAxisLimit.isInfinite) {
        switch (fit){
          case WrapFit.runTight:
            fit = WrapFit.runLoose;
          case WrapFit.tight:
            fit = WrapFit.loose;
          case WrapFit.loose:
          case WrapFit.runLoose:
        }
      }

      final Size childSize;

      switch (fit) {
        case WrapFit.runTight:
        case WrapFit.runLoose:
          if (runMainAxisExtent != 0 && runMainAxisExtent + getChildMinIntrinsicMainAxisExtent(child, double.infinity) + spacing <= mainAxisLimit) {
            if (fit.isTight) {
              childSize = layoutChild(child, childConstraintsFittingTightInRun(mainAxisLimit - runMainAxisExtent - spacing));
            } else {
              childSize = layoutChild(child, childConstraintsFittingLooseInRun(mainAxisLimit - runMainAxisExtent - spacing));
            }
          } else {
            if (fit.isTight) {
              childSize = layoutChild(child, childConstraintsFittingTightInRun(mainAxisLimit));
            } else {
              childSize = layoutChild(child, childConstraintsFittingLooseInRun(mainAxisLimit));
            }
          }
        case WrapFit.tight:
          childSize = layoutChild(child, childConstraintsTight);
        case WrapFit.loose:
          childSize = layoutChild(child, childConstraintsLoose);
      }

      final double childMainAxisExtent = _getMainAxisExtentInDirection(childSize, direction);
      final double childCrossAxisExtent = _getCrossAxisExtentInDirection(childSize, direction);

      // There must be at least one child before we move on to the next run.
      if (childCount > 0 && runMainAxisExtent + spacing + childMainAxisExtent > mainAxisLimit) {
        mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);
        crossAxisExtent += runCrossAxisExtent;
        if (runCount > 0) {
          crossAxisExtent += runSpacing;
        }
        if (onRunFinished != null) {
          onRunFinished(runMainAxisExtent: runMainAxisExtent, runCrossAxisExtent: runCrossAxisExtent, childCount: childCount);
        }
        runMainAxisExtent = 0.0;
        runCrossAxisExtent = 0.0;
        childCount = 0;
        runCount += 1;
      }
      runMainAxisExtent += childMainAxisExtent;
      runCrossAxisExtent = math.max(runCrossAxisExtent, childCrossAxisExtent);
      if (childCount > 0) {
        runMainAxisExtent += spacing;
      }
      childCount += 1;
      if (onLayoutChild != null) {
        onLayoutChild(childParentData, runCount);
      }
      child = next(child, childParentData);
    }

    if (childCount > 0) {
      mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);
      crossAxisExtent += runCrossAxisExtent;
      if (runCount > 0) {
        crossAxisExtent += runSpacing;
      }
      if (onRunFinished != null) {
        onRunFinished(runMainAxisExtent: runMainAxisExtent, runCrossAxisExtent: runCrossAxisExtent, childCount: childCount);
      }
    }

    return (mainAxisExtent: mainAxisExtent, crossAxisExtent: crossAxisExtent, runCount: runCount + 1);
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
