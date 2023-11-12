// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'box.dart';
import 'layer.dart';
import 'layout_helper.dart';
import 'object.dart';

// The same as Size, but instead of describing a 2D size along the x-axis and the
// y-axis, an _AxisSize's width is along the main axis and its height along the
// cross axis.
typedef _AxisSize = Size;

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
  spaceEvenly;

  WrapAlignment get _flipped => switch (this) {
      WrapAlignment.start => WrapAlignment.end,
      WrapAlignment.end => WrapAlignment.start,
      _ => this,
  };

  (double, double) _distributeSpace(double freeSpace, double itemSpacing, int itemCount) {
    assert(itemCount > 0);
    return switch (this) {
      WrapAlignment.start =>  (0,               itemSpacing),
      WrapAlignment.end =>    (freeSpace,       itemSpacing),
      WrapAlignment.center => (freeSpace / 2.0, itemSpacing),
      WrapAlignment.spaceBetween when itemCount < 2 => (0, itemSpacing),
      WrapAlignment.spaceBetween => (0, freeSpace / (itemCount - 1) + itemSpacing),
      WrapAlignment.spaceAround =>  (freeSpace / itemCount / 2,       freeSpace / itemCount + itemSpacing),
      WrapAlignment.spaceEvenly =>  (freeSpace / (itemCount + 1), freeSpace / (itemCount + 1) + itemSpacing),
    };
  }
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
  center;

  // TODO(ianh): baseline.

  WrapCrossAlignment get _flipped => switch (this) {
    WrapCrossAlignment.start => WrapCrossAlignment.end,
    WrapCrossAlignment.end => WrapCrossAlignment.start,
    WrapCrossAlignment.center => WrapCrossAlignment.center,
  };

  double get _alignment => switch (this) {
    WrapCrossAlignment.start => 0,
    WrapCrossAlignment.end => 1,
    WrapCrossAlignment.center => 0.5,
  };

}

class _RunMetrics {
  _RunMetrics(this.mainAxisExtent, this.crossAxisExtent, this.childCount, this.leadingChild, this.nextChild)
    : assert(childCount > 0);

  final double mainAxisExtent;
  final double crossAxisExtent;
  final int childCount;
  final RenderBox leadingChild;
  final RenderBox? Function(RenderBox) nextChild;

  void visitChildren(bool Function(RenderBox) visitor) {
    int childCount = this.childCount;
    for (RenderBox? child = leadingChild;
      child != null && childCount > 0 && visitor(child);
      child = nextChild(child), childCount -= 1
    ) {}
  }
}

/// Parent data for use with [RenderWrap].
class WrapParentData extends ContainerBoxParentData<RenderBox> {}

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

  Size _convertAxisSize(Size size) => switch (direction) {
    Axis.horizontal => size,
    Axis.vertical => Size(size.height, size.width),
  };

  (bool, bool) get _areAxesFlipped {
    final bool flipHorizontal = switch (textDirection ?? TextDirection.ltr) {
      TextDirection.ltr => false,
      TextDirection.rtl => true,
    };
    final bool flipVertical = switch (verticalDirection) {
      VerticalDirection.down => false,
      VerticalDirection.up => true,
    };
    return switch (direction) {
      Axis.horizontal => (flipHorizontal, flipVertical),
      Axis.vertical => (flipVertical, flipHorizontal),
    };
  }

  static void _setChildPosition(Offset offset, RenderBox child) {
    final WrapParentData childParentData = child.parentData! as WrapParentData;
    childParentData.offset = offset;
  }

  bool _hasVisualOverflow = false;

  (_AxisSize, Iterable<_RunMetrics>) _computeRuns(BoxConstraints constraints, [ChildLayouter layoutChild = ChildLayoutHelper.dryLayoutChild]) {
    final List<_RunMetrics> runMetrics = <_RunMetrics>[];

    final (double mainAxisLimit, BoxConstraints childConstraints) = switch (direction) {
      Axis.horizontal => (constraints.maxWidth, BoxConstraints(maxWidth: constraints.maxWidth)),
      Axis.vertical => (constraints.maxHeight, BoxConstraints(maxHeight: constraints.maxHeight)),
    };
    double mainAxisExtent = 0.0;
    double crossAxisExtent = 0.0;
    double runMainAxisExtent = 0.0;
    double runCrossAxisExtent = 0.0;
    int childCount = 0;

    final (bool flipMainAxis, bool flipCrossAxis) = _areAxesFlipped;

    RenderBox? child = firstChild;
    RenderBox? leadingChild;
    RenderBox? trailingChild;

    while (child != null) {
      // The child closest to the top left edge.
      final RenderBox? topLeftChild = flipMainAxis ? trailingChild : leadingChild;
      final Size childSize = layoutChild(child, childConstraints);
      final double childMainAxisExtent = _getMainAxisExtent(childSize);
      final double childCrossAxisExtent = _getCrossAxisExtent(childSize);
      if (topLeftChild != null && runMainAxisExtent + spacing + childMainAxisExtent > mainAxisLimit) {
        assert(childCount > 0);
        mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);
        crossAxisExtent += runCrossAxisExtent;
        if (runMetrics.isNotEmpty) {
          crossAxisExtent += runSpacing;
        }
        runMetrics.add(_RunMetrics(runMainAxisExtent, runCrossAxisExtent, childCount, topLeftChild, flipMainAxis ? childBefore : childAfter));
        runMainAxisExtent = 0.0;
        runCrossAxisExtent = 0.0;
        childCount = 0;
        leadingChild = child;
      }
      trailingChild = child;
      leadingChild ??= child;
      runMainAxisExtent += childMainAxisExtent;
      if (childCount > 0) {
        runMainAxisExtent += spacing;
      }
      runCrossAxisExtent = math.max(runCrossAxisExtent, childCrossAxisExtent);
      childCount += 1;
      child = childAfter(child);
    }
    final RenderBox? topLeftChild = flipMainAxis ? trailingChild : leadingChild;
    if (topLeftChild != null) {
      assert(childCount > 0);
      mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);
      crossAxisExtent += runCrossAxisExtent;
      if (runMetrics.isNotEmpty) {
        crossAxisExtent += runSpacing;
      }
      runMetrics.add(_RunMetrics(runMainAxisExtent, runCrossAxisExtent, childCount, topLeftChild, flipMainAxis ? childBefore : childAfter));
    }
    return (_AxisSize(mainAxisExtent, crossAxisExtent), flipCrossAxis ? runMetrics.reversed : runMetrics);
  }

  void _positionChild(Iterable<_RunMetrics> runMetrics, _AxisSize childrenAxisSize, _AxisSize containerAxisSize, void Function(Offset, RenderBox) positionChild) {
    final _AxisSize freeAxisSize = _AxisSize(
      containerAxisSize.width - childrenAxisSize.width,
      containerAxisSize.height - childrenAxisSize.height,
    );

    final int runCount = runMetrics.length;
    final double spacing = this.spacing;
    final double crossAxisFreeSpace = math.max(0.0, freeAxisSize.height);

    final (bool flipMainAxis, bool flipCrossAxis) = _areAxesFlipped;
    final WrapAlignment effectiveAlignment = flipMainAxis ? alignment._flipped : alignment;
    final WrapCrossAlignment effectiveCrossAlignment = flipCrossAxis ? crossAxisAlignment._flipped : crossAxisAlignment;
    final (double runLeadingSpace, double runBetweenSpace) = (flipCrossAxis? runAlignment._flipped : runAlignment)._distributeSpace(crossAxisFreeSpace, runSpacing, runCount);

    double runCrossAxisOffset = runLeadingSpace;
    for (final _RunMetrics run in runMetrics) {
      final double runMainAxisExtent = run.mainAxisExtent;
      final double runCrossAxisExtent = run.crossAxisExtent;
      final int childCount = run.childCount;

      final double mainAxisFreeSpace = math.max(0.0, containerAxisSize.width - runMainAxisExtent);
      final (
        double childLeadingSpace,
        double childBetweenSpace
      ) = effectiveAlignment._distributeSpace(mainAxisFreeSpace, spacing, childCount);

      double childMainAxisOffset = childLeadingSpace;

      run.visitChildren((RenderBox child) {
        final double childMainAxisExtent = _getMainAxisExtent(child.size);
        final double childCrossAxisExtent = _getCrossAxisExtent(child.size);
        final double childCrossAxisOffset = effectiveCrossAlignment._alignment * (runCrossAxisExtent - childCrossAxisExtent);
        positionChild(_getOffset(childMainAxisOffset, runCrossAxisOffset + childCrossAxisOffset), child);
        childMainAxisOffset += childMainAxisExtent + childBetweenSpace;
        return true;
      });

      runCrossAxisOffset += runCrossAxisExtent + runBetweenSpace;
    }
  }

  @override
  double? computeDryBaseline(covariant BoxConstraints constraints, TextBaseline baseline) {
    double? baselineOffset;
    final BoxConstraints childConstraints = switch (direction) {
      Axis.horizontal => BoxConstraints(maxWidth: constraints.maxWidth),
      Axis.vertical => BoxConstraints(maxHeight: constraints.maxHeight),
    };

    final (_AxisSize childrenAxisSize, Iterable<_RunMetrics> runMetrics) = _computeRuns(constraints);

    final Size size = constraints.constrain(_convertAxisSize(childrenAxisSize));
    final _AxisSize containerAxisSize = _convertAxisSize(size);

    void findHighestBaseline(Offset offset, RenderBox child) {
      final double? childBaseline = child.getDryBaseline(childConstraints, baseline);
      if (childBaseline != null) {
        final double? localBaselineOffset = baselineOffset;
        baselineOffset = localBaselineOffset == null
          ? offset.dy + childBaseline
          : math.min(localBaselineOffset, offset.dy + childBaseline);
      }
    }
    _positionChild(runMetrics, childrenAxisSize, containerAxisSize, findHighestBaseline);
    return baselineOffset;
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return _computeDryLayout(constraints);
  }

  Size _computeDryLayout(BoxConstraints constraints, [ChildLayouter layoutChild = ChildLayoutHelper.dryLayoutChild]) {
    final BoxConstraints childConstraints;
    double mainAxisLimit = 0.0;
    switch (direction) {
      case Axis.horizontal:
        childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
        mainAxisLimit = constraints.maxWidth;
      case Axis.vertical:
        childConstraints = BoxConstraints(maxHeight: constraints.maxHeight);
        mainAxisLimit = constraints.maxHeight;
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
      if (childCount > 0) {
        runMainAxisExtent += spacing;
      }
      childCount += 1;
      child = childAfter(child);
    }
    crossAxisExtent += runCrossAxisExtent;
    mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);

    return switch (direction) {
      Axis.horizontal => constraints.constrain(Size(mainAxisExtent, crossAxisExtent)),
      Axis.vertical => constraints.constrain(Size(crossAxisExtent, mainAxisExtent)),
    };
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    assert(_debugHasNecessaryDirections);
    if (firstChild == null) {
      _hasVisualOverflow = false;
      size = constraints.smallest;
      return;
    }

    final (_AxisSize childrenAxisSize, Iterable<_RunMetrics> runMetrics) = _computeRuns(constraints, ChildLayoutHelper.layoutChild);
    assert(runMetrics.isNotEmpty);

    size = constraints.constrain(_convertAxisSize(childrenAxisSize));

    final _AxisSize containerAxisSize = _convertAxisSize(size);
    _hasVisualOverflow = containerAxisSize.width < childrenAxisSize.width
                      || containerAxisSize.height < childrenAxisSize.height;
    _positionChild(runMetrics, childrenAxisSize, containerAxisSize, _setChildPosition);
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
