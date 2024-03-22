// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'box.dart';
import 'debug_overflow_indicator.dart';
import 'layer.dart';
import 'layout_helper.dart';
import 'object.dart';

// A type that describes a 2D size along the main axis and the cross axis of a
// [RenderFlex].
extension type const _AxisSize(Size _size) {
  _AxisSize.fromAxisExtents({ required double mainAxisExtent, required double crossAxisExtent }) : this(Size(mainAxisExtent, crossAxisExtent));
  _AxisSize.fromSize({ required Size size, required Axis direction }) : this(_convert(size, direction));

  static Size _convert(Size size, Axis direction) {
    return switch (direction) {
      Axis.horizontal => size,
      Axis.vertical => Size(size.height, size.width),
    };
  }
  double get mainAxisExtent => _size.width;
  double get crossAxisExtent => _size.height;

  Size toSize(Axis direction) => _convert(_size, direction);
}

typedef _AscentDescent = ({double ascent, double descent});

// The intermediate layout result when determining the overall size of the
// RenderFlex. The ascent/descent values and the axis size are stored separately
// because non-baseline aligned children are start-aligned.
extension type const _LayoutAxisDimensions(({_AxisSize axisSize, _AscentDescent? ascentDescent}) axisDimensions) {
  _AxisSize get axisSize => axisDimensions.axisSize;
  _AscentDescent? get ascentDescent => axisDimensions.ascentDescent;

  double get mainAxisExtent => axisSize.mainAxisExtent;
  double get crossAxisExtent => axisSize.crossAxisExtent;

  static const _LayoutAxisDimensions empty = _LayoutAxisDimensions((axisSize: _AxisSize(Size.zero), ascentDescent: null));

  // Updates the `current` _LayoutAxisDimensions with the dimensions of the given
  // child and returns the updated _LayoutAxisDimensions.
  _LayoutAxisDimensions update(_AxisSize childSize, BaselineOffset baseline) {
    final double? baselineOffset = baseline.offset;
    final double newMainExtent = axisSize.mainAxisExtent + childSize.mainAxisExtent;
    if (baselineOffset == null) {
      final double newCrossSize = math.max(childSize.crossAxisExtent, axisSize.crossAxisExtent);
      return _LayoutAxisDimensions((axisSize: _AxisSize.fromAxisExtents(mainAxisExtent: newMainExtent, crossAxisExtent: newCrossSize), ascentDescent: ascentDescent));
    } else {
      final _AscentDescent? oldAscentDescent = ascentDescent;
      final double ascent = baselineOffset;
      final double descent = childSize.crossAxisExtent - baselineOffset;
      final _AscentDescent newAscentDescent = oldAscentDescent == null
        ? (ascent: ascent, descent: descent)
        : (ascent: math.max(ascent, oldAscentDescent.ascent), descent: math.max(descent, oldAscentDescent.descent));
      final double newCrossExtent = math.max(axisSize.crossAxisExtent, newAscentDescent.ascent + newAscentDescent.descent);
      return _LayoutAxisDimensions((axisSize: _AxisSize.fromAxisExtents(mainAxisExtent: newMainExtent, crossAxisExtent: newCrossExtent), ascentDescent: newAscentDescent));
    }
  }
}

typedef _ChildSizingFunction = double Function(RenderBox child, double extent);
typedef _NextChild = RenderBox? Function(RenderBox child);

class _LayoutSizes {
  const _LayoutSizes({
    required this.size,
    required this.baselineOffset,
    required this.allocatedMainAxisSize,
  });

  // The final constrained Size of the RenderFlex.
  final _AxisSize size;

  // Sum of the main axis of all children.
  final double allocatedMainAxisSize;

  // Null if the RenderFlex is not baseline aligned, or none of its children has
  // a valid baseline of the given [TextBaseline] type.
  final double? baselineOffset;
}

/// How the child is inscribed into the available space.
///
/// See also:
///
///  * [RenderFlex], the flex render object.
///  * [Column], [Row], and [Flex], the flex widgets.
///  * [Expanded], the widget equivalent of [tight].
///  * [Flexible], the widget equivalent of [loose].
enum FlexFit {
  /// The child is forced to fill the available space.
  ///
  /// The [Expanded] widget assigns this kind of [FlexFit] to its child.
  tight,

  /// The child can be at most as large as the available space (but is
  /// allowed to be smaller).
  ///
  /// The [Flexible] widget assigns this kind of [FlexFit] to its child.
  loose,
}

/// Parent data for use with [RenderFlex].
class FlexParentData extends ContainerBoxParentData<RenderBox> {
  /// The flex factor to use for this child.
  ///
  /// If null or zero, the child is inflexible and determines its own size. If
  /// non-zero, the amount of space the child's can occupy in the main axis is
  /// determined by dividing the free space (after placing the inflexible
  /// children) according to the flex factors of the flexible children.
  int? flex;

  /// How a flexible child is inscribed into the available space.
  ///
  /// If [flex] is non-zero, the [fit] determines whether the child fills the
  /// space the parent makes available during layout. If the fit is
  /// [FlexFit.tight], the child is required to fill the available space. If the
  /// fit is [FlexFit.loose], the child can be at most as large as the available
  /// space (but is allowed to be smaller).
  FlexFit? fit;

  @override
  String toString() => '${super.toString()}; flex=$flex; fit=$fit';
}

/// How much space should be occupied in the main axis.
///
/// During a flex layout, available space along the main axis is allocated to
/// children. After allocating space, there might be some remaining free space.
/// This value controls whether to maximize or minimize the amount of free
/// space, subject to the incoming layout constraints.
///
/// See also:
///
///  * [Column], [Row], and [Flex], the flex widgets.
///  * [Expanded] and [Flexible], the widgets that controls a flex widgets'
///    children's flex.
///  * [RenderFlex], the flex render object.
///  * [MainAxisAlignment], which controls how the free space is distributed.
enum MainAxisSize {
  /// Minimize the amount of free space along the main axis, subject to the
  /// incoming layout constraints.
  ///
  /// If the incoming layout constraints have a large enough
  /// [BoxConstraints.minWidth] or [BoxConstraints.minHeight], there might still
  /// be a non-zero amount of free space.
  ///
  /// If the incoming layout constraints are unbounded, and any children have a
  /// non-zero [FlexParentData.flex] and a [FlexFit.tight] fit (as applied by
  /// [Expanded]), the [RenderFlex] will assert, because there would be infinite
  /// remaining free space and boxes cannot be given infinite size.
  min,

  /// Maximize the amount of free space along the main axis, subject to the
  /// incoming layout constraints.
  ///
  /// If the incoming layout constraints have a small enough
  /// [BoxConstraints.maxWidth] or [BoxConstraints.maxHeight], there might still
  /// be no free space.
  ///
  /// If the incoming layout constraints are unbounded, the [RenderFlex] will
  /// assert, because there would be infinite remaining free space and boxes
  /// cannot be given infinite size.
  max,
}

/// How the children should be placed along the main axis in a flex layout.
///
/// See also:
///
///  * [Column], [Row], and [Flex], the flex widgets.
///  * [RenderFlex], the flex render object.
enum MainAxisAlignment {
  /// Place the children as close to the start of the main axis as possible.
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the start is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the start is the top or the bottom.
  start,

  /// Place the children as close to the end of the main axis as possible.
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the end is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the end is the top or the bottom.
  end,

  /// Place the children as close to the middle of the main axis as possible.
  center,

  /// Place the free space evenly between the children.
  spaceBetween,

  /// Place the free space evenly between the children as well as half of that
  /// space before and after the first and last child.
  spaceAround,

  /// Place the free space evenly between the children as well as before and
  /// after the first and last child.
  spaceEvenly;

  // Returns (leadingSpace, betweenSpace).
  (double, double) _distributeSpace(double freeSpace, int itemCount, bool flipped) {
    assert(itemCount >= 0);
    return switch (this) {
      MainAxisAlignment.start => flipped ? (freeSpace, 0.0) : (0.0, 0.0),

      MainAxisAlignment.end =>                             MainAxisAlignment.start._distributeSpace(freeSpace, itemCount, !flipped),
      MainAxisAlignment.spaceBetween when itemCount < 2 => MainAxisAlignment.start._distributeSpace(freeSpace, itemCount, flipped),
      MainAxisAlignment.spaceAround when itemCount == 0 => MainAxisAlignment.start._distributeSpace(freeSpace, itemCount, flipped),

      MainAxisAlignment.center =>       (freeSpace / 2.0,             0.0),
      MainAxisAlignment.spaceBetween => (0.0,                         freeSpace / (itemCount - 1)),
      MainAxisAlignment.spaceAround =>  (freeSpace / itemCount / 2,   freeSpace / itemCount),
      MainAxisAlignment.spaceEvenly =>  (freeSpace / (itemCount + 1), freeSpace / (itemCount + 1)),
    };
  }
}

/// How the children should be placed along the cross axis in a flex layout.
///
/// See also:
///
///  * [Column], [Row], and [Flex], the flex widgets.
///  * [Flex.crossAxisAlignment], the property on flex widgets that
///    has this type.
///  * [RenderFlex], the flex render object.
enum CrossAxisAlignment {
  /// Place the children with their start edge aligned with the start side of
  /// the cross axis.
  ///
  /// For example, in a column (a flex with a vertical axis) whose
  /// [TextDirection] is [TextDirection.ltr], this aligns the left edge of the
  /// children along the left edge of the column.
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the start is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the start is the top or the bottom.
  start,

  /// Place the children as close to the end of the cross axis as possible.
  ///
  /// For example, in a column (a flex with a vertical axis) whose
  /// [TextDirection] is [TextDirection.ltr], this aligns the right edge of the
  /// children along the right edge of the column.
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the end is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the end is the top or the bottom.
  end,

  /// Place the children so that their centers align with the middle of the
  /// cross axis.
  ///
  /// This is the default cross-axis alignment.
  center,

  /// Require the children to fill the cross axis.
  ///
  /// This causes the constraints passed to the children to be tight in the
  /// cross axis.
  stretch,

  /// Place the children along the cross axis such that their baselines match.
  ///
  /// Consider using this value for any horizontal main axis (as with [Row])
  /// where the children primarily contain text.  If the different children
  /// have text with different font metrics (for example because they differ
  /// in [TextStyle.fontSize] or other [TextStyle] properties, or because
  /// they use different fonts due to being written in different scripts),
  /// then this typically produces better visual alignment than the other
  /// [CrossAxisAlignment] values, which use no information about
  /// where the text sits vertically within its bounding box.
  ///
  /// The baseline of a widget is typically the typographic baseline of the
  /// first text in the first [Text] or [RichText] widget it encloses, if any.
  /// The typographic baseline is a horizontal line used for aligning text,
  /// which is specified by each font; for alphabetic scripts, it ordinarily
  /// runs along the bottom of letters excluding any descenders.
  ///
  /// Because baselines are always horizontal, this alignment is intended for
  /// horizontal main axes (as with [Row]). If the main axis is vertical
  /// (as with [Column]), then this value is treated like [start].
  ///
  /// For horizontal main axes, if the minimum height constraint passed to the
  /// flex layout exceeds the intrinsic height of the cross axis, children will
  /// be aligned as close to the top as they can be while honoring the baseline
  /// alignment. In other words, the extra space will be below all the children.
  ///
  /// Children who report no baseline will be top-aligned.
  ///
  /// See also:
  ///
  ///  * [RenderBox.getDistanceToBaseline], which defines the baseline of a box.
  baseline;

  CrossAxisAlignment get _flipped => switch (this) {
    CrossAxisAlignment.start => CrossAxisAlignment.end,
    CrossAxisAlignment.end => CrossAxisAlignment.start,
    CrossAxisAlignment.center => CrossAxisAlignment.center,
    CrossAxisAlignment.stretch => CrossAxisAlignment.stretch,
    CrossAxisAlignment.baseline => CrossAxisAlignment.baseline,
  };
}

/// Displays its children in a one-dimensional array.
///
/// ## Layout algorithm
///
/// _This section describes how the framework causes [RenderFlex] to position
/// its children._
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// Layout for a [RenderFlex] proceeds in six steps:
///
/// 1. Layout each child with a null or zero flex factor with unbounded main
///    axis constraints and the incoming cross axis constraints. If the
///    [crossAxisAlignment] is [CrossAxisAlignment.stretch], instead use tight
///    cross axis constraints that match the incoming max extent in the cross
///    axis.
/// 2. Divide the remaining main axis space among the children with non-zero
///    flex factors according to their flex factor. For example, a child with a
///    flex factor of 2.0 will receive twice the amount of main axis space as a
///    child with a flex factor of 1.0.
/// 3. Layout each of the remaining children with the same cross axis
///    constraints as in step 1, but instead of using unbounded main axis
///    constraints, use max axis constraints based on the amount of space
///    allocated in step 2. Children with [Flexible.fit] properties that are
///    [FlexFit.tight] are given tight constraints (i.e., forced to fill the
///    allocated space), and children with [Flexible.fit] properties that are
///    [FlexFit.loose] are given loose constraints (i.e., not forced to fill the
///    allocated space).
/// 4. The cross axis extent of the [RenderFlex] is the maximum cross axis
///    extent of the children (which will always satisfy the incoming
///    constraints).
/// 5. The main axis extent of the [RenderFlex] is determined by the
///    [mainAxisSize] property. If the [mainAxisSize] property is
///    [MainAxisSize.max], then the main axis extent of the [RenderFlex] is the
///    max extent of the incoming main axis constraints. If the [mainAxisSize]
///    property is [MainAxisSize.min], then the main axis extent of the [Flex]
///    is the sum of the main axis extents of the children (subject to the
///    incoming constraints).
/// 6. Determine the position for each child according to the
///    [mainAxisAlignment] and the [crossAxisAlignment]. For example, if the
///    [mainAxisAlignment] is [MainAxisAlignment.spaceBetween], any main axis
///    space that has not been allocated to children is divided evenly and
///    placed between the children.
///
/// See also:
///
///  * [Flex], the widget equivalent.
///  * [Row] and [Column], direction-specific variants of [Flex].
class RenderFlex extends RenderBox with ContainerRenderObjectMixin<RenderBox, FlexParentData>,
                                        RenderBoxContainerDefaultsMixin<RenderBox, FlexParentData>,
                                        DebugOverflowIndicatorMixin {
  /// Creates a flex render object.
  ///
  /// By default, the flex layout is horizontal and children are aligned to the
  /// start of the main axis and the center of the cross axis.
  RenderFlex({
    List<RenderBox>? children,
    Axis direction = Axis.horizontal,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    Clip clipBehavior = Clip.none,
  }) : _direction = direction,
       _mainAxisAlignment = mainAxisAlignment,
       _mainAxisSize = mainAxisSize,
       _crossAxisAlignment = crossAxisAlignment,
       _textDirection = textDirection,
       _verticalDirection = verticalDirection,
       _textBaseline = textBaseline,
       _clipBehavior = clipBehavior {
    addAll(children);
  }

  /// The direction to use as the main axis.
  Axis get direction => _direction;
  Axis _direction;
  set direction(Axis value) {
    if (_direction != value) {
      _direction = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the main axis.
  ///
  /// If the [direction] is [Axis.horizontal], and the [mainAxisAlignment] is
  /// either [MainAxisAlignment.start] or [MainAxisAlignment.end], then the
  /// [textDirection] must not be null.
  ///
  /// If the [direction] is [Axis.vertical], and the [mainAxisAlignment] is
  /// either [MainAxisAlignment.start] or [MainAxisAlignment.end], then the
  /// [verticalDirection] must not be null.
  MainAxisAlignment get mainAxisAlignment => _mainAxisAlignment;
  MainAxisAlignment _mainAxisAlignment;
  set mainAxisAlignment(MainAxisAlignment value) {
    if (_mainAxisAlignment != value) {
      _mainAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// How much space should be occupied in the main axis.
  ///
  /// After allocating space to children, there might be some remaining free
  /// space. This value controls whether to maximize or minimize the amount of
  /// free space, subject to the incoming layout constraints.
  ///
  /// If some children have a non-zero flex factors (and none have a fit of
  /// [FlexFit.loose]), they will expand to consume all the available space and
  /// there will be no remaining free space to maximize or minimize, making this
  /// value irrelevant to the final layout.
  MainAxisSize get mainAxisSize => _mainAxisSize;
  MainAxisSize _mainAxisSize;
  set mainAxisSize(MainAxisSize value) {
    if (_mainAxisSize != value) {
      _mainAxisSize = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the cross axis.
  ///
  /// If the [direction] is [Axis.horizontal], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.vertical], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [textDirection] must not be null.
  CrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    if (_crossAxisAlignment != value) {
      _crossAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the order in which
  /// children are positioned (left-to-right or right-to-left), and the meaning
  /// of the [mainAxisAlignment] property's [MainAxisAlignment.start] and
  /// [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [mainAxisAlignment] is either [MainAxisAlignment.start] or
  /// [MainAxisAlignment.end], or there's more than one child, then the
  /// [textDirection] must not be null.
  ///
  /// If the [direction] is [Axis.vertical], this controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
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
  /// are painted in (down or up), the meaning of the [mainAxisAlignment]
  /// property's [MainAxisAlignment.start] and [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the [mainAxisAlignment]
  /// is either [MainAxisAlignment.start] or [MainAxisAlignment.end], or there's
  /// more than one child, then the [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [verticalDirection] must not be null.
  VerticalDirection get verticalDirection => _verticalDirection;
  VerticalDirection _verticalDirection;
  set verticalDirection(VerticalDirection value) {
    if (_verticalDirection != value) {
      _verticalDirection = value;
      markNeedsLayout();
    }
  }

  /// If aligning items according to their baseline, which baseline to use.
  ///
  /// Must not be null if [crossAxisAlignment] is [CrossAxisAlignment.baseline].
  TextBaseline? get textBaseline => _textBaseline;
  TextBaseline? _textBaseline;
  set textBaseline(TextBaseline? value) {
    assert(_crossAxisAlignment != CrossAxisAlignment.baseline || value != null);
    if (_textBaseline != value) {
      _textBaseline = value;
      markNeedsLayout();
    }
  }

  bool get _debugHasNecessaryDirections {
    if (RenderObject.debugCheckingIntrinsics) {
      return true;
    }
    if (firstChild != null && lastChild != firstChild) {
      // i.e. there's more than one child
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null, 'Horizontal $runtimeType with multiple children has a null textDirection, so the layout order is undefined.');
        case Axis.vertical:
          break;
      }
    }
    if (mainAxisAlignment == MainAxisAlignment.start ||
        mainAxisAlignment == MainAxisAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null, 'Horizontal $runtimeType with $mainAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
        case Axis.vertical:
          break;
      }
    }
    if (crossAxisAlignment == CrossAxisAlignment.start ||
        crossAxisAlignment == CrossAxisAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          break;
        case Axis.vertical:
          assert(textDirection != null, 'Vertical $runtimeType with $crossAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
      }
    }
    return true;
  }

  // Set during layout if overflow occurred on the main axis.
  double _overflow = 0;
  // Check whether any meaningful overflow is present. Values below an epsilon
  // are treated as not overflowing.
  bool get _hasOverflow => _overflow > precisionErrorTolerance;

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

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FlexParentData) {
      child.parentData = FlexParentData();
    }
  }

  double _getIntrinsicSize({
    required Axis sizingDirection,
    required double extent, // the extent in the direction that isn't the sizing direction
    required _ChildSizingFunction childSize, // a method to find the size in the sizing direction
  }) {
    // Translate the extent into BoxConstraints.
    final BoxConstraints extentConstraints = switch (sizingDirection) {
      Axis.horizontal => BoxConstraints(maxHeight: extent),
      Axis.vertical   => BoxConstraints(maxWidth: extent),
    };
    if (_direction == sizingDirection) {
      // INTRINSIC MAIN SIZE
      Size computeIntrinsicMainExtentForChild(RenderBox child, BoxConstraints constraints) {
        switch (_direction) {
          case Axis.horizontal:
            final double height = constraints.maxHeight;
            return Size(childSize(child, height), height);
          case Axis.vertical:
            final double width = constraints.maxWidth;
            return Size(width, childSize(child, width));
        }
      }
      return _computeSizes(constraints: extentConstraints, layoutChild: computeIntrinsicMainExtentForChild, computeBaseline: ChildLayoutHelper.getDryBaseline).size.mainAxisExtent;
    } else {
      // INTRINSIC CROSS SIZE
      Size computeIntrinsicCrossExtentForChild(RenderBox child, BoxConstraints constraints) {
        final bool isFlexChild = _getFlex(child) > 0;
        switch (_direction) {
          case Axis.horizontal:
            final double width = isFlexChild
              ? math.min(child.getMaxIntrinsicWidth(constraints.maxHeight), constraints.maxWidth)
              : child.getMaxIntrinsicWidth(constraints.maxHeight);
            return Size(width, childSize(child, width));
          case Axis.vertical:
            final double height = isFlexChild
              ? math.min(child.getMaxIntrinsicHeight(constraints.maxWidth), constraints.maxHeight)
              : child.getMaxIntrinsicHeight(constraints.maxWidth);
            return Size(childSize(child, height), height);
        }
      }
      return _computeSizes(constraints: extentConstraints, layoutChild: computeIntrinsicCrossExtentForChild, computeBaseline: ChildLayoutHelper.getDryBaseline).size.crossAxisExtent;
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicWidth(extent),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicWidth(extent),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicHeight(extent),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicHeight(extent),
    );
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    // `defaultComputeDistanceToFirstActualBaseline` does not work even for
    // Columns, because the children reorder with VerticalDirection.up.
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  static int _getFlex(RenderBox child) {
    final FlexParentData childParentData = child.parentData! as FlexParentData;
    return childParentData.flex ?? 0;
  }

  static FlexFit _getFit(RenderBox child) {
    final FlexParentData childParentData = child.parentData! as FlexParentData;
    return childParentData.fit ?? FlexFit.tight;
  }

  bool get _isBaselineAligned {
    return switch (crossAxisAlignment) {
      CrossAxisAlignment.baseline => switch (direction) {
        Axis.horizontal => true,
        Axis.vertical => false,
      },
      CrossAxisAlignment.start || CrossAxisAlignment.center || CrossAxisAlignment.end || CrossAxisAlignment.stretch  => false,
    };
  }

  double _getCrossSize(Size size) {
    return switch (_direction) {
      Axis.horizontal => size.height,
      Axis.vertical => size.width,
    };
  }

  double _getMainSize(Size size) {
    return switch (_direction) {
      Axis.horizontal => size.width,
      Axis.vertical => size.height,
    };
  }

  // flipMainAxis is used to decide whether to lay out
  // left-to-right/top-to-bottom (false), or right-to-left/bottom-to-top
  // (true). Returns false in cases when the layout direction does not matter
  // (for instance, there is no child).
  bool get _flipMainAxis => firstChild != null && switch (direction) {
    Axis.horizontal => switch (textDirection) {
      null || TextDirection.ltr => false,
      TextDirection.rtl => true,
    },
    Axis.vertical => switch (verticalDirection) {
      VerticalDirection.down => false,
      VerticalDirection.up => true,
    },
  };

  bool get _flipCrossAxis => firstChild != null && switch (direction) {
    Axis.vertical => switch (textDirection) {
      null || TextDirection.ltr => false,
      TextDirection.rtl => true,
    },
    Axis.horizontal => switch (verticalDirection) {
      VerticalDirection.down => false,
      VerticalDirection.up => true,
    },
  };

  BoxConstraints _constraintsForNonFlexChild(BoxConstraints constraints) {
    final bool fillCrossAxis = switch (crossAxisAlignment) {
      CrossAxisAlignment.stretch  => true,
      CrossAxisAlignment.start ||
      CrossAxisAlignment.center ||
      CrossAxisAlignment.end ||
      CrossAxisAlignment.baseline => false,
    };
    return switch (_direction) {
      Axis.horizontal => fillCrossAxis
        ? BoxConstraints.tightFor(height: constraints.maxHeight)
        : BoxConstraints(maxHeight: constraints.maxHeight),
      Axis.vertical => fillCrossAxis
        ? BoxConstraints.tightFor(width: constraints.maxWidth)
        : BoxConstraints(maxWidth: constraints.maxWidth),
    };
  }

  BoxConstraints _constraintsForFlexChild(RenderBox child, BoxConstraints constraints, double maxChildExtent) {
    assert(maxChildExtent >= 0.0);
    final double minChildExtent = switch (_getFit(child)) {
      FlexFit.tight => maxChildExtent,
      FlexFit.loose => 0.0,
    };
    final bool fillCrossAxis = switch (crossAxisAlignment) {
      CrossAxisAlignment.stretch  => true,
      CrossAxisAlignment.start ||
      CrossAxisAlignment.center ||
      CrossAxisAlignment.end ||
      CrossAxisAlignment.baseline => false,
    };
    return switch (_direction) {
      Axis.horizontal => BoxConstraints(
        minWidth: minChildExtent,
        maxWidth: maxChildExtent,
        minHeight: fillCrossAxis ? constraints.maxHeight : 0.0,
        maxHeight: constraints.maxHeight,
      ),
      Axis.vertical => BoxConstraints(
        minWidth: fillCrossAxis ? constraints.maxWidth : 0.0,
        maxWidth: constraints.maxWidth,
        minHeight: minChildExtent,
        maxHeight: maxChildExtent,
      ),
    };
  }

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    if (_isBaselineAligned) {
      return _computeSizes(
        constraints: constraints,
        layoutChild: ChildLayoutHelper.dryLayoutChild,
        computeBaseline: ChildLayoutHelper.getDryBaseline,
      ).baselineOffset;
    }

    final Map<RenderBox, BoxConstraints> flexChildConstraints = <RenderBox, BoxConstraints>{};
    final _LayoutSizes sizes = _computeSizes(
      constraints: constraints,
      layoutChild: ChildLayoutHelper.dryLayoutChild,
      computeBaseline: ChildLayoutHelper.getDryBaseline,
      flexChildConstraints: flexChildConstraints,
    );

    final BoxConstraints nonFlexConstraints = _constraintsForNonFlexChild(constraints);
    BoxConstraints constraintsForChild(RenderBox child) => flexChildConstraints[child] ?? nonFlexConstraints;

    BaselineOffset baselineOffset = BaselineOffset.noBaseline;
    switch (direction) {
      case Axis.vertical:
        final double freeSpace = math.max(0.0, sizes.size.mainAxisExtent - sizes.allocatedMainAxisSize);
        final bool flipMainAxis = _flipMainAxis;
        final (double leadingSpaceY, double spaceBetween) = mainAxisAlignment._distributeSpace(freeSpace, childCount, flipMainAxis);
        double y = leadingSpaceY;
        final (_NextChild nextChild, RenderBox? topLeftChild) = flipMainAxis ? (childBefore, lastChild) : (childAfter, firstChild);
        for (RenderBox? child = topLeftChild; child != null; child = nextChild(child)) {
          final BoxConstraints childConstraints = constraintsForChild(child);
          final Size childSize = child.getDryLayout(childConstraints);
          baselineOffset = baselineOffset.minOf(BaselineOffset(child.getDryBaseline(childConstraints, baseline)) + y);
          y += spaceBetween + childSize.height;
        }
        return baselineOffset.offset;
      case Axis.horizontal:
        for (RenderBox? child = firstChild; child != null; child = childAfter(child)) {
          final BoxConstraints childConstraints = constraintsForChild(child);
          final double? distance = child.getDryBaseline(childConstraints, baseline);
          final CrossAxisAlignment effectiveCrossAxisAlignment = _flipCrossAxis ? crossAxisAlignment._flipped : crossAxisAlignment;
          if (distance == null) {
            continue;
          }
          final BaselineOffset childBaseline = BaselineOffset(distance) + switch (effectiveCrossAxisAlignment) {
            CrossAxisAlignment.start || CrossAxisAlignment.stretch || CrossAxisAlignment.baseline => 0.0,
            CrossAxisAlignment.end => sizes.size.crossAxisExtent - child.getDryLayout(childConstraints).height,
            CrossAxisAlignment.center => (sizes.size.crossAxisExtent - child.getDryLayout(childConstraints).height) / 2,
          };
          baselineOffset = baselineOffset.minOf(childBaseline);
        }
        return baselineOffset.offset;
    }
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    FlutterError? constraintsError;
    assert(() {
      constraintsError = _debugCheckConstraints(
        constraints: constraints,
        reportParentConstraints: false,
      );
      return true;
    }());
    if (constraintsError != null) {
      assert(debugCannotComputeDryLayout(error: constraintsError));
      return Size.zero;
    }

    return _computeSizes(
      constraints: constraints,
      layoutChild: ChildLayoutHelper.dryLayoutChild,
      computeBaseline: ChildLayoutHelper.getDryBaseline,
    ).size.toSize(direction);
  }

  FlutterError? _debugCheckConstraints({required BoxConstraints constraints, required bool reportParentConstraints}) {
    FlutterError? result;
    assert(() {
      final double maxMainSize = _direction == Axis.horizontal ? constraints.maxWidth : constraints.maxHeight;
      final bool canFlex = maxMainSize < double.infinity;
      RenderBox? child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        if (flex > 0) {
          final String identity = _direction == Axis.horizontal ? 'row' : 'column';
          final String axis = _direction == Axis.horizontal ? 'horizontal' : 'vertical';
          final String dimension = _direction == Axis.horizontal ? 'width' : 'height';
          DiagnosticsNode error, message;
          final List<DiagnosticsNode> addendum = <DiagnosticsNode>[];
          if (!canFlex && (mainAxisSize == MainAxisSize.max || _getFit(child) == FlexFit.tight)) {
            error = ErrorSummary('RenderFlex children have non-zero flex but incoming $dimension constraints are unbounded.');
            message = ErrorDescription(
              'When a $identity is in a parent that does not provide a finite $dimension constraint, for example '
              'if it is in a $axis scrollable, it will try to shrink-wrap its children along the $axis '
              'axis. Setting a flex on a child (e.g. using Expanded) indicates that the child is to '
              'expand to fill the remaining space in the $axis direction.',
            );
            if (reportParentConstraints) { // Constraints of parents are unavailable in dry layout.
              RenderBox? node = this;
              switch (_direction) {
                case Axis.horizontal:
                  while (!node!.constraints.hasBoundedWidth && node.parent is RenderBox) {
                    node = node.parent! as RenderBox;
                  }
                  if (!node.constraints.hasBoundedWidth) {
                    node = null;
                  }
                case Axis.vertical:
                  while (!node!.constraints.hasBoundedHeight && node.parent is RenderBox) {
                    node = node.parent! as RenderBox;
                  }
                  if (!node.constraints.hasBoundedHeight) {
                    node = null;
                  }
              }
              if (node != null) {
                addendum.add(node.describeForError('The nearest ancestor providing an unbounded width constraint is'));
              }
            }
            addendum.add(ErrorHint('See also: https://flutter.dev/unbounded-constraints'));
          } else {
            return true;
          }
          result = FlutterError.fromParts(<DiagnosticsNode>[
            error,
            message,
            ErrorDescription(
              'These two directives are mutually exclusive. If a parent is to shrink-wrap its child, the child '
              'cannot simultaneously expand to fit its parent.',
            ),
            ErrorHint(
              'Consider setting mainAxisSize to MainAxisSize.min and using FlexFit.loose fits for the flexible '
              'children (using Flexible rather than Expanded). This will allow the flexible children '
              'to size themselves to less than the infinite remaining space they would otherwise be '
              'forced to take, and then will cause the RenderFlex to shrink-wrap the children '
              'rather than expanding to fit the maximum constraints provided by the parent.',
            ),
            ErrorDescription(
              'If this message did not help you determine the problem, consider using debugDumpRenderTree():\n'
              '  https://flutter.dev/debugging/#rendering-layer\n'
              '  http://api.flutter.dev/flutter/rendering/debugDumpRenderTree.html',
            ),
            describeForError('The affected RenderFlex is', style: DiagnosticsTreeStyle.errorProperty),
            DiagnosticsProperty<dynamic>('The creator information is set to', debugCreator, style: DiagnosticsTreeStyle.errorProperty),
            ...addendum,
            ErrorDescription(
              "If none of the above helps enough to fix this problem, please don't hesitate to file a bug:\n"
              '  https://github.com/flutter/flutter/issues/new?template=2_bug.yml',
            ),
          ]);
          return true;
        }
        child = childAfter(child);
      }
      return true;
    }());
    return result;
  }

  _LayoutSizes _computeSizes({
      required BoxConstraints constraints,
      required ChildLayouter layoutChild,
      required ChildBaselineGetter computeBaseline,
      Map<RenderBox, BoxConstraints>? flexChildConstraints,
  }) {
    assert(_debugHasNecessaryDirections);

    // Determine used flex factor, size inflexible items, calculate free space.
    final double maxMainSize = _getMainSize(constraints.biggest);
    final bool canFlex = maxMainSize.isFinite;
    final BoxConstraints nonFlexChildConstraints = _constraintsForNonFlexChild(constraints);
    // Null indicates the children are not baseline aligned.
    final TextBaseline? textBaseline = _isBaselineAligned
      ? (this.textBaseline ?? (throw FlutterError('To use CrossAxisAlignment.baseline, you must also specify which baseline to use using the "textBaseline" argument.')))
      : null;

    // The first pass lays out non-flex children and computes total flex.
    int totalFlex = 0;
    _LayoutAxisDimensions layoutAxisDimensions = _LayoutAxisDimensions.empty;
    RenderBox? firstFlexChild;
    for (RenderBox? child = firstChild; child != null; child = childAfter(child)) {
      final int flex;
      if (canFlex && (flex = _getFlex(child)) > 0) {
        totalFlex += flex;
        firstFlexChild ??= child;
      } else {
        final _AxisSize childSize = _AxisSize.fromSize(size: layoutChild(child, nonFlexChildConstraints), direction: direction);
        final double? baselineOffset = textBaseline == null ? null : computeBaseline(child, nonFlexChildConstraints, textBaseline);
        layoutAxisDimensions = layoutAxisDimensions.update(childSize, BaselineOffset(baselineOffset));
      }
    }

    assert((totalFlex == 0) == (firstFlexChild == null));
    assert(firstFlexChild == null || canFlex); // If we are given infinite space there's no need for this extra step.

    // The second pass distributes free space to flexible children.
    final double flexSpace = math.max(0.0, maxMainSize - layoutAxisDimensions.mainAxisExtent);
    final double spacePerFlex = flexSpace / totalFlex;
    for (RenderBox? child = firstFlexChild; child != null; child = childAfter(child)) {
      final int flex = _getFlex(child);
      if (flex == 0) {
        continue;
      }
      final bool isLastFlexChild = (totalFlex -= flex) == 0;
      final double maxChildExtent = isLastFlexChild
        ? math.max(0.0, maxMainSize - layoutAxisDimensions.mainAxisExtent)
        : spacePerFlex * flex;
      assert(_getFit(child) == FlexFit.loose || maxChildExtent < double.infinity);
      final BoxConstraints childConstraints = _constraintsForFlexChild(child, constraints, maxChildExtent);
      flexChildConstraints?[child] = childConstraints;
      final _AxisSize childSize = _AxisSize.fromSize(size: layoutChild(child, childConstraints), direction: direction);
      final double? baselineOffset = textBaseline == null ? null : computeBaseline(child, childConstraints, textBaseline);
      layoutAxisDimensions = layoutAxisDimensions.update(childSize, BaselineOffset(baselineOffset));
      if (isLastFlexChild) {
        break;
      }
    }
    assert(totalFlex == 0);
    final double idealMainSize = switch (mainAxisSize) {
      MainAxisSize.max when maxMainSize.isFinite => maxMainSize,
      MainAxisSize.max || MainAxisSize.min => layoutAxisDimensions.mainAxisExtent,
    };
    final Size constrainedSize = constraints.constrain(
      _AxisSize.fromAxisExtents(mainAxisExtent: idealMainSize, crossAxisExtent: layoutAxisDimensions.crossAxisExtent).toSize(direction),
    );
    return _LayoutSizes(
      size: _AxisSize.fromSize(size: constrainedSize, direction: direction),
      allocatedMainAxisSize: layoutAxisDimensions.mainAxisExtent,
      baselineOffset: layoutAxisDimensions.ascentDescent?.ascent,
    );
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    assert(() {
      final FlutterError? constraintsError = _debugCheckConstraints(
        constraints: constraints,
        reportParentConstraints: true,
      );
      if (constraintsError != null) {
        throw constraintsError;
      }
      return true;
    }());

    final _LayoutSizes sizes = _computeSizes(
      constraints: constraints,
      layoutChild: ChildLayoutHelper.layoutChild,
      computeBaseline: ChildLayoutHelper.getBaseline,
    );

    final double allocatedSize = sizes.allocatedMainAxisSize;

    final _AxisSize(:double mainAxisExtent, :double crossAxisExtent) = sizes.size;
    size = sizes.size.toSize(direction);

    final double actualSizeDelta = mainAxisExtent - allocatedSize;
    _overflow = math.max(0.0, -actualSizeDelta);

    final double remainingSpace = math.max(0.0, actualSizeDelta);
    final bool flipMainAxis = _flipMainAxis;
    final (double leadingSpace, double betweenSpace) = mainAxisAlignment._distributeSpace(remainingSpace, childCount, flipMainAxis);
    final (_NextChild nextChild, RenderBox? topLeftChild) = flipMainAxis ? (childBefore, lastChild) : (childAfter, firstChild);
    final CrossAxisAlignment effectiveCrossAxisAlignment = _flipCrossAxis ? crossAxisAlignment._flipped : crossAxisAlignment;
    final double? baselineOffset = sizes.baselineOffset;
    assert(baselineOffset == null || (crossAxisAlignment == CrossAxisAlignment.baseline && direction == Axis.horizontal));

    // Position all chilren in visual order: starting from the top-left child and
    // work towards the child that's farthest away from the origin.
    double childMainPosition = leadingSpace;
    for (RenderBox? child = topLeftChild; child != null; child = nextChild(child)) {
      final double childCrossPosition;
      if (baselineOffset == null) {
        childCrossPosition = switch (effectiveCrossAxisAlignment) {
          CrossAxisAlignment.start || CrossAxisAlignment.stretch || CrossAxisAlignment.baseline => 0.0,
          CrossAxisAlignment.end => crossAxisExtent - _getCrossSize(child.size),
          CrossAxisAlignment.center => (crossAxisExtent - _getCrossSize(child.size)) / 2,
        };
      } else {
        assert(_isBaselineAligned);
        final double? childBaselineOffset = child.getDistanceToBaseline(textBaseline!, onlyReal: true);
        childCrossPosition = childBaselineOffset == null ? 0.0 : baselineOffset - childBaselineOffset;
      }
      final FlexParentData childParentData = child.parentData! as FlexParentData;
      childParentData.offset = switch (_direction) {
        Axis.horizontal => Offset(childMainPosition, childCrossPosition),
        Axis.vertical => Offset(childCrossPosition, childMainPosition),
      };
      childMainPosition += _getMainSize(child.size) + betweenSpace;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasOverflow) {
      defaultPaint(context, offset);
      return;
    }

    // There's no point in drawing the children if we're empty.
    if (size.isEmpty) {
      return;
    }

    _clipRectLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      defaultPaint,
      clipBehavior: clipBehavior,
      oldLayer: _clipRectLayer.layer,
    );

    assert(() {
      final List<DiagnosticsNode> debugOverflowHints = <DiagnosticsNode>[
        ErrorDescription(
          'The overflowing $runtimeType has an orientation of $_direction.',
        ),
        ErrorDescription(
          'The edge of the $runtimeType that is overflowing has been marked '
          'in the rendering with a yellow and black striped pattern. This is '
          'usually caused by the contents being too big for the $runtimeType.',
        ),
        ErrorHint(
          'Consider applying a flex factor (e.g. using an Expanded widget) to '
          'force the children of the $runtimeType to fit within the available '
          'space instead of being sized to their natural size.',
        ),
        ErrorHint(
          'This is considered an error condition because it indicates that there '
          'is content that cannot be seen. If the content is legitimately bigger '
          'than the available space, consider clipping it with a ClipRect widget '
          'before putting it in the flex, or using a scrollable container rather '
          'than a Flex, like a ListView.',
        ),
      ];

      // Simulate a child rect that overflows by the right amount. This child
      // rect is never used for drawing, just for determining the overflow
      // location and amount.
      final Rect overflowChildRect = switch (_direction) {
        Axis.horizontal => Rect.fromLTWH(0.0, 0.0, size.width + _overflow, 0.0),
        Axis.vertical   => Rect.fromLTWH(0.0, 0.0, 0.0, size.height + _overflow),
      };
      paintOverflowIndicator(context, offset, Offset.zero & size, overflowChildRect, overflowHints: debugOverflowHints);
      return true;
    }());
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    switch (clipBehavior) {
      case Clip.none:
        return null;
      case Clip.hardEdge:
      case Clip.antiAlias:
      case Clip.antiAliasWithSaveLayer:
        return _hasOverflow ? Offset.zero & size : null;
    }
  }


  @override
  String toStringShort() {
    String header = super.toStringShort();
    if (!kReleaseMode) {
      if (_hasOverflow) {
        header += ' OVERFLOWING';
      }
    }
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('direction', direction));
    properties.add(EnumProperty<MainAxisAlignment>('mainAxisAlignment', mainAxisAlignment));
    properties.add(EnumProperty<MainAxisSize>('mainAxisSize', mainAxisSize));
    properties.add(EnumProperty<CrossAxisAlignment>('crossAxisAlignment', crossAxisAlignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(EnumProperty<VerticalDirection>('verticalDirection', verticalDirection, defaultValue: null));
    properties.add(EnumProperty<TextBaseline>('textBaseline', textBaseline, defaultValue: null));
  }
}
