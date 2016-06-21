// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'box.dart';
import 'object.dart';

/// Parent data for use with [RenderFlex].
class FlexParentData extends ContainerBoxParentDataMixin<RenderBox> {
  /// The flex factor to use for this child
  ///
  /// If null, the child is inflexible and determines its own size. If non-null,
  /// the child is flexible and its extent in the main axis is determined by
  /// dividing the free space (after placing the inflexible children)
  /// according to the flex factors of the flexible children.
  int flex;

  @override
  String toString() => '${super.toString()}; flex=$flex';
}

/// The direction in which the box should flex
enum FlexDirection {
  /// Children are arranged horizontally, from left to right
  horizontal,
  /// Children are arranged vertically, from top to bottom
  vertical
}

/// The incoming constraint parameter that defines how much space is available
/// along the main axis in a flex layout. Flex layouts allocate the difference
/// between the available space and the sum of the sizes of the children
/// which are not flexible to the layout's flexible children and the space
/// around the children. See [Row], [Column], [MainAxisAlignment], [Flexible].
enum MainAxisSize {
  /// The available space is defined by the incoming constraint's min parameter.
  min,

  /// The available space is defined by the incoming constraint's max parameter.
  max,
}

/// How the children should be placed along the main axis in a flex layout.
enum MainAxisAlignment {
  /// Place the children as close to the start of the main axis as possible.
  start,

  /// Place the children as close to the end of the main axis as possible.
  end,

  /// Place the children as close to the middle of the main axis as possible.
  center,

  /// Place the free space evenly between the children.
  spaceBetween,

  /// Place the free space evenly between the children as well as half of that space before and after the first and last child.
  spaceAround,

  /// Place the free space evenly between the children as well as before and after the first and last child.
  spaceEvenly
}

/// How the children should be placed along the cross axis in a flex layout.
enum CrossAxisAlignment {
  /// Place the children as close to the start of the cross axis as possible.
  start,

  /// Place the children as close to the end of the cross axis as possible.
  end,

  /// Place the children as close to the middle of the cross axis as possible.
  center,

  /// Require the children to fill the cross axis.
  stretch,

  /// Place the children along the cross axis such that their baselines match.
  baseline,
}

typedef double _ChildSizingFunction(RenderBox child, double extent);

/// Implements the flex layout algorithm
///
/// In flex layout, children are arranged linearly along the main axis (either
/// horizontally or vertically). First, inflexible children (those with a null
/// flex factor) are allocated space along the main axis. If the flex is given
/// unlimited space in the main axis, the flex sizes its main axis to the total
/// size of the inflexible children along the main axis and forbids flexible
/// children. Otherwise, the flex expands to the maximum max-axis size and the
/// remaining space along is divided among the flexible children according to
/// their flex factors. Any remaining free space (i.e., if there aren't any
/// flexible children) is allocated according to the [mainAxisAlignment] property.
///
/// In the cross axis, children determine their own size. The flex then sizes
/// its cross axis to fix the largest of its children. The children are then
/// positioned along the cross axis according to the [crossAxisAlignment] property.
class RenderFlex extends RenderBox with ContainerRenderObjectMixin<RenderBox, FlexParentData>,
                                        RenderBoxContainerDefaultsMixin<RenderBox, FlexParentData> {
  /// Creates a flex render object.
  ///
  /// By default, the flex layout is horizontal and children are aligned to the
  /// start of the main axis and the center of the cross axis.
  RenderFlex({
    List<RenderBox> children,
    FlexDirection direction: FlexDirection.horizontal,
    MainAxisSize mainAxisSize: MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment: MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment: CrossAxisAlignment.center,
    TextBaseline textBaseline
  }) : _direction = direction,
       _mainAxisAlignment = mainAxisAlignment,
       _mainAxisSize = mainAxisSize,
       _crossAxisAlignment = crossAxisAlignment,
       _textBaseline = textBaseline {
    addAll(children);
  }

  /// The direction to use as the main axis.
  FlexDirection get direction => _direction;
  FlexDirection _direction;
  set direction (FlexDirection value) {
    if (_direction != value) {
      _direction = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the main axis.
  MainAxisAlignment get mainAxisAlignment => _mainAxisAlignment;
  MainAxisAlignment _mainAxisAlignment;
  set mainAxisAlignment (MainAxisAlignment value) {
    assert(value != null);
    if (_mainAxisAlignment != value) {
      _mainAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// The limit used to compute free space along the main axis.
  MainAxisSize get mainAxisSize => _mainAxisSize;
  MainAxisSize _mainAxisSize;
  set mainAxisSize (MainAxisSize value) {
    if (_mainAxisSize != value) {
      _mainAxisSize = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the cross axis.
  CrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment (CrossAxisAlignment value) {
    if (_crossAxisAlignment != value) {
      _crossAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// If aligning items according to their baseline, which baseline to use.
  TextBaseline get textBaseline => _textBaseline;
  TextBaseline _textBaseline;
  set textBaseline (TextBaseline value) {
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
    FlexDirection sizingDirection,
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
        int flex = _getFlex(child);
        totalFlex += flex;
        if (flex > 0) {
          double flexFraction = childSize(child, extent) / _getFlex(child);
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
      double availableMainSpace = extent;
      int totalFlex = 0;
      double inflexibleSpace = 0.0;
      double maxCrossSize = 0.0;
      RenderBox child = firstChild;
      while (child != null) {
        int flex = _getFlex(child);
        totalFlex += flex;
        double mainSize;
        double crossSize;
        if (flex == 0) {
          switch (_direction) {
              case FlexDirection.horizontal:
                mainSize = child.getMaxIntrinsicWidth(double.INFINITY);
                crossSize = childSize(child, mainSize);
                break;
              case FlexDirection.vertical:
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
      double spacePerFlex = math.max(0.0,
          (availableMainSpace - inflexibleSpace) / totalFlex);

      // Size remaining (flexible) items, find the maximum cross size.
      child = firstChild;
      while (child != null) {
        int flex = _getFlex(child);
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
      sizingDirection: FlexDirection.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicWidth(extent)
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: FlexDirection.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicWidth(extent)
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: FlexDirection.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicHeight(extent)
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: FlexDirection.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicHeight(extent)
    );
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (_direction == FlexDirection.horizontal)
      return defaultComputeDistanceToHighestActualBaseline(baseline);
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  int _getFlex(RenderBox child) {
    final FlexParentData childParentData = child.parentData;
    return childParentData.flex != null ? childParentData.flex : 0;
  }

  double _getCrossSize(RenderBox child) {
    return (_direction == FlexDirection.horizontal) ? child.size.height : child.size.width;
  }

  double _getMainSize(RenderBox child) {
    return (_direction == FlexDirection.horizontal) ? child.size.width : child.size.height;
  }

  @override
  void performLayout() {
    // Determine used flex factor, size inflexible items, calculate free space.
    int totalFlex = 0;
    int totalChildren = 0;
    assert(constraints != null);
    final bool isHorizontal = _direction == FlexDirection.horizontal;
    final double minMainSize = isHorizontal ? constraints.constrainWidth(0.0) : constraints.constrainHeight(0.0);
    final double maxMainSize = isHorizontal ? constraints.constrainWidth() : constraints.constrainHeight();
    final double availableSize = mainAxisSize == MainAxisSize.max ? maxMainSize : minMainSize;
    final bool canFlex = availableSize < double.INFINITY;

    double crossSize = 0.0;
    double allocatedSize = 0.0; // Sum of the sizes of the the non-flexible children.
    RenderBox child = firstChild;
    while (child != null) {
      final FlexParentData childParentData = child.parentData;
      totalChildren++;
      int flex = _getFlex(child);
      if (flex > 0) {
        assert(() {
          final String identity = _direction == FlexDirection.horizontal ? 'row' : 'column';
          final String axis = _direction == FlexDirection.horizontal ? 'horizontal' : 'vertical';
          final String dimension = _direction == FlexDirection.horizontal ? 'width' : 'height';
          String error, message;
          String addendum = '';
          if (availableSize == double.INFINITY) {
            error = 'RenderFlex children have non-zero flex but incoming $dimension constraints are unbounded.';
            message = 'When a $identity is in a parent that does not provide a finite $dimension constraint, for example '
                      'if it is in a $axis scrollable, it will try to shrink-wrap its children along the $axis '
                      'axis. Setting a flex on a child (e.g. using a Flexible) indicates that the child is to '
                      'expand to fill the remaining space in the $axis direction.';
            StringBuffer information = new StringBuffer();
            RenderBox node = this;
            switch (_direction) {
              case FlexDirection.horizontal:
                while (!node.constraints.hasBoundedWidth && node.parent is RenderBox)
                  node = node.parent;
                if (!node.constraints.hasBoundedWidth)
                  node = null;
                break;
              case FlexDirection.vertical:
                while (!node.constraints.hasBoundedHeight && node.parent is RenderBox)
                  node = node.parent;
                if (!node.constraints.hasBoundedHeight)
                  node = null;
                break;
            }
            if (node != null) {
              information.writeln('The nearest ancestor providing an unbounded width constraint is:');
              information.writeln('  $node');
              List<String> description = <String>[];
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
            case FlexDirection.horizontal:
              innerConstraints = new BoxConstraints(minHeight: constraints.maxHeight,
                                                    maxHeight: constraints.maxHeight);
              break;
            case FlexDirection.vertical:
              innerConstraints = new BoxConstraints(minWidth: constraints.maxWidth,
                                                    maxWidth: constraints.maxWidth);
              break;
          }
        } else {
          switch (_direction) {
            case FlexDirection.horizontal:
              innerConstraints = new BoxConstraints(maxHeight: constraints.maxHeight);
              break;
            case FlexDirection.vertical:
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
    double freeSpace = math.max(0.0, (canFlex ? availableSize : 0.0) - allocatedSize);
    double maxBaselineDistance = 0.0;
    double usedSpace = 0.0;
    if (totalFlex > 0 || crossAxisAlignment == CrossAxisAlignment.baseline) {
      double spacePerFlex = totalFlex > 0 ? (freeSpace / totalFlex) : 0.0;
      child = firstChild;
      while (child != null) {
        int flex = _getFlex(child);
        if (flex > 0) {
          double spaceForChild = spacePerFlex * flex;
          BoxConstraints innerConstraints;
          if (crossAxisAlignment == CrossAxisAlignment.stretch) {
            switch (_direction) {
              case FlexDirection.horizontal:
                innerConstraints = new BoxConstraints(minWidth: spaceForChild,
                                                      maxWidth: spaceForChild,
                                                      minHeight: constraints.maxHeight,
                                                      maxHeight: constraints.maxHeight);
                break;
              case FlexDirection.vertical:
                innerConstraints = new BoxConstraints(minWidth: constraints.maxWidth,
                                                      maxWidth: constraints.maxWidth,
                                                      minHeight: spaceForChild,
                                                      maxHeight: spaceForChild);
                break;
            }
          } else {
            switch (_direction) {
              case FlexDirection.horizontal:
                innerConstraints = new BoxConstraints(minWidth: spaceForChild,
                                                      maxWidth: spaceForChild,
                                                      maxHeight: constraints.maxHeight);
                break;
              case FlexDirection.vertical:
                innerConstraints = new BoxConstraints(maxWidth: constraints.maxWidth,
                                                      minHeight: spaceForChild,
                                                      maxHeight: spaceForChild);
                break;
            }
          }
          child.layout(innerConstraints, parentUsesSize: true);
          usedSpace += _getMainSize(child);
          crossSize = math.max(crossSize, _getCrossSize(child));
        }
        if (crossAxisAlignment == CrossAxisAlignment.baseline) {
          assert(() {
            if (textBaseline == null)
              throw new FlutterError('To use FlexAlignItems.baseline, you must also specify which baseline to use using the "baseline" argument.');
            return true;
          });
          double distance = child.getDistanceToBaseline(textBaseline, onlyReal: true);
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
      remainingSpace = math.max(0.0, freeSpace - usedSpace);
      switch (_direction) {
        case FlexDirection.horizontal:
          size = constraints.constrain(new Size(preferredSize, crossSize));
          crossSize = size.height;
          assert(isMainAxisSizeMax ? size.width == maxMainSize : size.width >= minMainSize);
          break;
        case FlexDirection.vertical:
          size = constraints.constrain(new Size(crossSize, preferredSize));
          crossSize = size.width;
          assert(isMainAxisSizeMax ? size.height == maxMainSize : size.height >= minMainSize);
          break;
      }
    } else {
      assert(mainAxisSize == MainAxisSize.max);
      leadingSpace = 0.0;
      betweenSpace = 0.0;
      switch (_direction) {
        case FlexDirection.horizontal:
          size = constraints.constrain(new Size(_overflow, crossSize));
          crossSize = size.height;
          remainingSpace = math.max(0.0, size.width - _overflow);
          break;
        case FlexDirection.vertical:
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
          if (_direction == FlexDirection.horizontal) {
            assert(textBaseline != null);
            double distance = child.getDistanceToBaseline(textBaseline, onlyReal: true);
            if (distance != null)
              childCrossPosition = maxBaselineDistance - distance;
          }
          break;
      }
      switch (_direction) {
        case FlexDirection.horizontal:
          childParentData.offset = new Offset(childMainPosition, childCrossPosition);
          break;
        case FlexDirection.vertical:
          childParentData.offset = new Offset(childCrossPosition, childMainPosition);
          break;
      }
      childMainPosition += _getMainSize(child) + betweenSpace;
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_overflow <= 0.0) {
      defaultPaint(context, offset);
      return;
    }

    // We have overflow. Clip it.
    context.pushClipRect(needsCompositing, offset, Point.origin & size, defaultPaint);

    assert(() {
      // In debug mode, if you have overflow, we highlight where the
      // overflow would be by painting that area red. Since that is
      // likely to be clipped by an ancestor, we also draw a thick red
      // line at the edge that's overflowing.

      // If you do want clipping, use a RenderClip (Clip in the
      // Widgets library).

      Paint markerPaint = new Paint()..color = const Color(0xE0FF0000);
      Paint highlightPaint = new Paint()..color = const Color(0x7FFF0000);
      const double kMarkerSize = 0.1;
      Rect markerRect, overflowRect;
      switch(direction) {
        case FlexDirection.horizontal:
          markerRect = offset + new Offset(size.width * (1.0 - kMarkerSize), 0.0) &
                       new Size(size.width * kMarkerSize, size.height);
          overflowRect = offset + new Offset(size.width, 0.0) &
                         new Size(_overflow, size.height);
          break;
        case FlexDirection.vertical:
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
  Rect describeApproximatePaintClip(RenderObject child) => _overflow > 0.0 ? Point.origin & size : null;

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
