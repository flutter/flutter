// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'box.dart';
import 'object.dart';

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
  /// The flex factor to use for this child
  ///
  /// If null or zero, the child is inflexible and determines its own size. If
  /// non-zero, the amount of space the child's can occupy in the main axis is
  /// determined by dividing the free space (after placing the inflexible
  /// children) according to the flex factors of the flexible children.
  int flex;

  /// How a flexible child is inscribed into the available space.
  ///
  /// If [flex] is non-zero, the [fit] determines whether the child fills the
  /// space the parent makes available during layout. If the fit is
  /// [FlexFit.tight], the child is required to fill the available space. If the
  /// fit is [FlexFit.loose], the child can be at most as large as the available
  /// space (but is allowed to be smaller).
  FlexFit fit;

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
  min,

  /// Maximize the amount of free space along the main axis, subject to the
  /// incoming layout constraints.
  ///
  /// If the incoming layout constraints have a small enough
  /// [BoxConstraints.maxWidth] or [BoxConstraints.maxHeight], there might still
  /// be no free space.
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
  start,

  /// Place the children as close to the end of the main axis as possible.
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
  spaceEvenly,
}

/// How the children should be placed along the cross axis in a flex layout.
///
/// See also:
///
///  * [Column], [Row], and [Flex], the flex widgets.
///  * [RenderFlex], the flex render object.
enum CrossAxisAlignment {
  /// Place the children with their start edge aligned with the start side of
  /// the cross axis.
  ///
  /// For example, in a column (a flex with a vertical axis), this aligns the
  /// left edge of the children along the left edge of the column.
  start,

  /// Place the children as close to the end of the cross axis as possible.
  ///
  /// For example, in a column (a flex with a vertical axis), this aligns the
  /// right edge of the children along the right edge of the column.
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
  /// If the main axis is vertical, then this value is treated like [start]
  /// (since baselines are always horizontal).
  baseline,
}

typedef double _ChildSizingFunction(RenderBox child, double extent);

/// Displays its children in a one-dimensional array.
///
/// Layout for a [RenderFlex] proceeds in six steps:
///
/// 1. Layout each child a null or zero flex factor with unbounded main axis
///    constraints and the incoming cross axis constraints. If the
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
class RenderFlex extends RenderBox with ContainerRenderObjectMixin<RenderBox, FlexParentData>,
                                        RenderBoxContainerDefaultsMixin<RenderBox, FlexParentData> {
  /// Creates a flex render object.
  ///
  /// By default, the flex layout is horizontal and children are aligned to the
  /// start of the main axis and the center of the cross axis.
  RenderFlex({
    List<RenderBox> children,
    Axis direction: Axis.horizontal,
    MainAxisSize mainAxisSize: MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment: MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment: CrossAxisAlignment.center,
    TextBaseline textBaseline
  }) : assert(direction != null),
       assert(mainAxisAlignment != null),
       assert(mainAxisSize != null),
       assert(crossAxisAlignment != null),
       _direction = direction,
       _mainAxisAlignment = mainAxisAlignment,
       _mainAxisSize = mainAxisSize,
       _crossAxisAlignment = crossAxisAlignment,
       _textBaseline = textBaseline {
    addAll(children);
  }

  /// The direction to use as the main axis.
  Axis get direction => _direction;
  Axis _direction;
  set direction(Axis value) {
    assert(value != null);
    if (_direction != value) {
      _direction = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the main axis.
  MainAxisAlignment get mainAxisAlignment => _mainAxisAlignment;
  MainAxisAlignment _mainAxisAlignment;
  set mainAxisAlignment(MainAxisAlignment value) {
    assert(value != null);
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
    assert(value != null);
    if (_mainAxisSize != value) {
      _mainAxisSize = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the cross axis.
  CrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    assert(value != null);
    if (_crossAxisAlignment != value) {
      _crossAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// If aligning items according to their baseline, which baseline to use.
  ///
  /// Must not be null if [crossAxisAlignment] is [CrossAxisAlignment.baseline].
  TextBaseline get textBaseline => _textBaseline;
  TextBaseline _textBaseline;
  set textBaseline(TextBaseline value) {
    assert(_crossAxisAlignment != CrossAxisAlignment.baseline || value != null);
    if (_textBaseline != value) {
      _textBaseline = value;
      markNeedsLayout();
    }
  }

  /// Set during layout if overflow occurred on the main axis.
  double _overflow;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FlexParentData)
      child.parentData = new FlexParentData();
  }

  double _getIntrinsicSize({
    Axis sizingDirection,
    double extent, // the extent in the direction that isn't the sizing direction
    _ChildSizingFunction childSize // a method to find the size in the sizing direction
  }) {
    if (_direction == sizingDirection) {
      // INTRINSIC MAIN SIZE
      // Intrinsic main size is the smallest size the flex container can take
      // while maintaining the min/max-content contributions of its flex items.
      double totalFlex = 0.0;
      double inflexibleSpace = 0.0;
      double maxFlexFractionSoFar = 0.0;
      RenderBox child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        totalFlex += flex;
        if (flex > 0) {
          final double flexFraction = childSize(child, extent) / _getFlex(child);
          maxFlexFractionSoFar = math.max(maxFlexFractionSoFar, flexFraction);
        } else {
          inflexibleSpace += childSize(child, extent);
        }
        final FlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }
      return maxFlexFractionSoFar * totalFlex + inflexibleSpace;
    } else {
      // INTRINSIC CROSS SIZE
      // Intrinsic cross size is the max of the intrinsic cross sizes of the
      // children, after the flexible children are fit into the available space,
      // with the children sized using their max intrinsic dimensions.
      // TODO(ianh): Support baseline alignment.

      // Get inflexible space using the max intrinsic dimensions of fixed children in the main direction.
      final double availableMainSpace = extent;
      int totalFlex = 0;
      double inflexibleSpace = 0.0;
      double maxCrossSize = 0.0;
      RenderBox child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        totalFlex += flex;
        double mainSize;
        double crossSize;
        if (flex == 0) {
          switch (_direction) {
              case Axis.horizontal:
                mainSize = child.getMaxIntrinsicWidth(double.INFINITY);
                crossSize = childSize(child, mainSize);
                break;
              case Axis.vertical:
                mainSize = child.getMaxIntrinsicHeight(double.INFINITY);
                crossSize = childSize(child, mainSize);
                break;
          }
          inflexibleSpace += mainSize;
          maxCrossSize = math.max(maxCrossSize, crossSize);
        }
        final FlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }

      // Determine the spacePerFlex by allocating the remaining available space.
      // When you're overconstrained spacePerFlex can be negative.
      final double spacePerFlex = math.max(0.0,
          (availableMainSpace - inflexibleSpace) / totalFlex);

      // Size remaining (flexible) items, find the maximum cross size.
      child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        if (flex > 0)
          maxCrossSize = math.max(maxCrossSize, childSize(child, spacePerFlex * flex));
        final FlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }

      return maxCrossSize;
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicWidth(extent)
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicWidth(extent)
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicHeight(extent)
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicHeight(extent)
    );
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (_direction == Axis.horizontal)
      return defaultComputeDistanceToHighestActualBaseline(baseline);
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  int _getFlex(RenderBox child) {
    final FlexParentData childParentData = child.parentData;
    return childParentData.flex ?? 0;
  }

  FlexFit _getFit(RenderBox child) {
    final FlexParentData childParentData = child.parentData;
    return childParentData.fit ?? FlexFit.tight;
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
    // Determine used flex factor, size inflexible items, calculate free space.
    int totalFlex = 0;
    int totalChildren = 0;
    assert(constraints != null);
    final double maxMainSize = _direction == Axis.horizontal ? constraints.maxWidth : constraints.maxHeight;
    final bool canFlex = maxMainSize < double.INFINITY;

    double crossSize = 0.0;
    double allocatedSize = 0.0; // Sum of the sizes of the the non-flexible children.
    RenderBox child = firstChild;
    while (child != null) {
      final FlexParentData childParentData = child.parentData;
      totalChildren++;
      final int flex = _getFlex(child);
      if (flex > 0) {
        assert(() {
          final String identity = _direction == Axis.horizontal ? 'row' : 'column';
          final String axis = _direction == Axis.horizontal ? 'horizontal' : 'vertical';
          final String dimension = _direction == Axis.horizontal ? 'width' : 'height';
          String error, message;
          String addendum = '';
          if (maxMainSize == double.INFINITY) {
            error = 'RenderFlex children have non-zero flex but incoming $dimension constraints are unbounded.';
            message = 'When a $identity is in a parent that does not provide a finite $dimension constraint, for example '
                      'if it is in a $axis scrollable, it will try to shrink-wrap its children along the $axis '
                      'axis. Setting a flex on a child (e.g. using a Flexible) indicates that the child is to '
                      'expand to fill the remaining space in the $axis direction.';
            final StringBuffer information = new StringBuffer();
            RenderBox node = this;
            switch (_direction) {
              case Axis.horizontal:
                while (!node.constraints.hasBoundedWidth && node.parent is RenderBox)
                  node = node.parent;
                if (!node.constraints.hasBoundedWidth)
                  node = null;
                break;
              case Axis.vertical:
                while (!node.constraints.hasBoundedHeight && node.parent is RenderBox)
                  node = node.parent;
                if (!node.constraints.hasBoundedHeight)
                  node = null;
                break;
            }
            if (node != null) {
              information.writeln('The nearest ancestor providing an unbounded width constraint is:');
              information.writeln('  $node');
              final List<String> description = <String>[];
              node.debugFillDescription(description);
              for (String line in description)
                information.writeln('  $line');
            }
            information.writeln('See also: https://flutter.io/layout/');
            addendum = information.toString();
          } else {
            return true;
          }
          throw new FlutterError(
            '$error\n'
            '$message\n'
            'These two directives are mutually exclusive. If a parent is to shrink-wrap its child, the child '
            'cannot simultaneously expand to fit its parent.\n'
            'The affected RenderFlex is:\n'
            '  $this\n'
            'The creator information is set to:\n'
            '  $debugCreator\n'
            '$addendum'
            'If this message did not help you determine the problem, consider using debugDumpRenderTree():\n'
            '  https://flutter.io/debugging/#rendering-layer\n'
            '  http://docs.flutter.io/flutter/rendering/debugDumpRenderTree.html\n'
            'If none of the above helps enough to fix this problem, please don\'t hesitate to file a bug:\n'
            '  https://github.com/flutter/flutter/issues/new'
          );
        });
        totalFlex += childParentData.flex;
      } else {
        BoxConstraints innerConstraints;
        if (crossAxisAlignment == CrossAxisAlignment.stretch) {
          switch (_direction) {
            case Axis.horizontal:
              innerConstraints = new BoxConstraints(minHeight: constraints.maxHeight,
                                                    maxHeight: constraints.maxHeight);
              break;
            case Axis.vertical:
              innerConstraints = new BoxConstraints(minWidth: constraints.maxWidth,
                                                    maxWidth: constraints.maxWidth);
              break;
          }
        } else {
          switch (_direction) {
            case Axis.horizontal:
              innerConstraints = new BoxConstraints(maxHeight: constraints.maxHeight);
              break;
            case Axis.vertical:
              innerConstraints = new BoxConstraints(maxWidth: constraints.maxWidth);
              break;
          }
        }
        child.layout(innerConstraints, parentUsesSize: true);
        allocatedSize += _getMainSize(child);
        crossSize = math.max(crossSize, _getCrossSize(child));
      }
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    _overflow = math.max(0.0, allocatedSize - (canFlex ? maxMainSize : 0.0));

    // Distribute free space to flexible children, and determine baseline.
    final double freeSpace = math.max(0.0, (canFlex ? maxMainSize : 0.0) - allocatedSize);
    double maxBaselineDistance = 0.0;
    if (totalFlex > 0 || crossAxisAlignment == CrossAxisAlignment.baseline) {
      final double spacePerFlex = totalFlex > 0 ? (freeSpace / totalFlex) : 0.0;
      child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        if (flex > 0) {
          final double maxChildExtent = spacePerFlex * flex;
          double minChildExtent;
          switch (_getFit(child)) {
            case FlexFit.tight:
              minChildExtent = maxChildExtent;
              break;
            case FlexFit.loose:
              minChildExtent = 0.0;
              break;
          }
          assert(minChildExtent != null);
          BoxConstraints innerConstraints;
          if (crossAxisAlignment == CrossAxisAlignment.stretch) {
            switch (_direction) {
              case Axis.horizontal:
                innerConstraints = new BoxConstraints(minWidth: minChildExtent,
                                                      maxWidth: maxChildExtent,
                                                      minHeight: constraints.maxHeight,
                                                      maxHeight: constraints.maxHeight);
                break;
              case Axis.vertical:
                innerConstraints = new BoxConstraints(minWidth: constraints.maxWidth,
                                                      maxWidth: constraints.maxWidth,
                                                      minHeight: minChildExtent,
                                                      maxHeight: maxChildExtent);
                break;
            }
          } else {
            switch (_direction) {
              case Axis.horizontal:
                innerConstraints = new BoxConstraints(minWidth: minChildExtent,
                                                      maxWidth: maxChildExtent,
                                                      maxHeight: constraints.maxHeight);
                break;
              case Axis.vertical:
                innerConstraints = new BoxConstraints(maxWidth: constraints.maxWidth,
                                                      minHeight: minChildExtent,
                                                      maxHeight: maxChildExtent);
                break;
            }
          }
          child.layout(innerConstraints, parentUsesSize: true);
          allocatedSize += _getMainSize(child);
          crossSize = math.max(crossSize, _getCrossSize(child));
        }
        if (crossAxisAlignment == CrossAxisAlignment.baseline) {
          assert(() {
            if (textBaseline == null)
              throw new FlutterError('To use FlexAlignItems.baseline, you must also specify which baseline to use using the "baseline" argument.');
            return true;
          });
          final double distance = child.getDistanceToBaseline(textBaseline, onlyReal: true);
          if (distance != null)
            maxBaselineDistance = math.max(maxBaselineDistance, distance);
        }
        final FlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }
    }

    // Align items along the main axis.
    double leadingSpace;
    double betweenSpace;
    double remainingSpace;
    if (canFlex) {
      final bool isMainAxisSizeMax = mainAxisSize == MainAxisSize.max;
      final double preferredSize = isMainAxisSizeMax ? maxMainSize : allocatedSize;
      switch (_direction) {
        case Axis.horizontal:
          size = constraints.constrain(new Size(preferredSize, crossSize));
          remainingSpace = math.max(0.0, size.width - allocatedSize);
          crossSize = size.height;
          assert(isMainAxisSizeMax ? size.width == maxMainSize : size.width >= constraints.minWidth);
          break;
        case Axis.vertical:
          size = constraints.constrain(new Size(crossSize, preferredSize));
          remainingSpace = math.max(0.0, size.height - allocatedSize);
          crossSize = size.width;
          assert(isMainAxisSizeMax ? size.height == maxMainSize : size.height >= constraints.minHeight);
          break;
      }
    } else {
      leadingSpace = 0.0;
      betweenSpace = 0.0;
      switch (_direction) {
        case Axis.horizontal:
          size = constraints.constrain(new Size(_overflow, crossSize));
          crossSize = size.height;
          remainingSpace = math.max(0.0, size.width - _overflow);
          break;
        case Axis.vertical:
          size = constraints.constrain(new Size(crossSize, _overflow));
          crossSize = size.width;
          remainingSpace = math.max(0.0, size.height - _overflow);
          break;
      }
      _overflow = 0.0;
    }
    switch (_mainAxisAlignment) {
      case MainAxisAlignment.start:
        leadingSpace = 0.0;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.end:
        leadingSpace = remainingSpace;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.center:
        leadingSpace = remainingSpace / 2.0;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.spaceBetween:
        leadingSpace = 0.0;
        betweenSpace = totalChildren > 1 ? remainingSpace / (totalChildren - 1) : 0.0;
        break;
      case MainAxisAlignment.spaceAround:
        betweenSpace = totalChildren > 0 ? remainingSpace / totalChildren : 0.0;
        leadingSpace = betweenSpace / 2.0;
        break;
      case MainAxisAlignment.spaceEvenly:
        betweenSpace = totalChildren > 0 ? remainingSpace / (totalChildren + 1) : 0.0;
        leadingSpace = betweenSpace;
        break;
    }

    // Position elements
    double childMainPosition = leadingSpace;
    child = firstChild;
    while (child != null) {
      final FlexParentData childParentData = child.parentData;
      double childCrossPosition;
      switch (_crossAxisAlignment) {
        case CrossAxisAlignment.stretch:
        case CrossAxisAlignment.start:
          childCrossPosition = 0.0;
          break;
        case CrossAxisAlignment.end:
          childCrossPosition = crossSize - _getCrossSize(child);
          break;
        case CrossAxisAlignment.center:
          childCrossPosition = crossSize / 2.0 - _getCrossSize(child) / 2.0;
          break;
        case CrossAxisAlignment.baseline:
          childCrossPosition = 0.0;
          if (_direction == Axis.horizontal) {
            assert(textBaseline != null);
            final double distance = child.getDistanceToBaseline(textBaseline, onlyReal: true);
            if (distance != null)
              childCrossPosition = maxBaselineDistance - distance;
          }
          break;
      }
      switch (_direction) {
        case Axis.horizontal:
          childParentData.offset = new Offset(childMainPosition, childCrossPosition);
          break;
        case Axis.vertical:
          childParentData.offset = new Offset(childCrossPosition, childMainPosition);
          break;
      }
      childMainPosition += _getMainSize(child) + betweenSpace;
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_overflow <= 0.0) {
      defaultPaint(context, offset);
      return;
    }

    // We have overflow. Clip it.
    context.pushClipRect(needsCompositing, offset, Offset.zero & size, defaultPaint);

    assert(() {
      // In debug mode, if you have overflow, we highlight where the
      // overflow would be by painting that area red. Since that is
      // likely to be clipped by an ancestor, we also draw a thick red
      // line at the edge that's overflowing.

      // If you do want clipping, use a RenderClip (Clip in the
      // Widgets library).

      final Paint markerPaint = new Paint()..color = const Color(0xE0FF0000);
      final Paint highlightPaint = new Paint()..color = const Color(0x7FFF0000);
      const double kMarkerSize = 0.1;
      Rect markerRect, overflowRect;
      switch(direction) {
        case Axis.horizontal:
          markerRect = offset + new Offset(size.width * (1.0 - kMarkerSize), 0.0) &
                       new Size(size.width * kMarkerSize, size.height);
          overflowRect = offset + new Offset(size.width, 0.0) &
                         new Size(_overflow, size.height);
          break;
        case Axis.vertical:
          markerRect = offset + new Offset(0.0, size.height * (1.0 - kMarkerSize)) &
                       new Size(size.width, size.height * kMarkerSize);
          overflowRect = offset + new Offset(0.0, size.height) &
                         new Size(size.width, _overflow);
          break;
      }
      context.canvas.drawRect(markerRect, markerPaint);
      context.canvas.drawRect(overflowRect, highlightPaint);
      return true;
    });
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) => _overflow > 0.0 ? Offset.zero & size : null;

  @override
  String toString() {
    String header = super.toString();
    if (_overflow is double && _overflow > 0.0)
      header += ' OVERFLOWING';
    return header;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('direction: $_direction');
    description.add('mainAxisAlignment: $_mainAxisAlignment');
    description.add('mainAxisSize: $_mainAxisSize');
    description.add('crossAxisAlignment: $_crossAxisAlignment');
    description.add('textBaseline: $_textBaseline');
  }

}
