// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'box.dart';
import 'object.dart';

/// Parent data for use with [RenderFlex]
class FlexParentData extends ContainerBoxParentDataMixin<RenderBox> {
  /// The flex factor to use for this child
  ///
  /// If null, the child is inflexible and determines its own size. If non-null,
  /// the child is flexible and its extent in the main axis is determined by
  /// dividing the free space (after placing the inflexible children)
  /// according to the flex factors of the flexible children.
  int flex;

  void merge(FlexParentData other) {
    if (other.flex != null)
      flex = other.flex;
    super.merge(other);
  }

  String toString() => '${super.toString()}; flex=$flex';
}

/// The direction in which the box should flex
enum FlexDirection {
  /// Children are arranged horizontally, from left to right
  horizontal,
  /// Children are arranged vertically, from top to bottom
  vertical
}

/// How the children should be placed along the main axis in a flex layout
enum FlexJustifyContent {
  /// Place the children as close to the start of the main axis as possible
  start,
  /// Place the children as close to the end of the main axis as possible
  end,
  /// Place the children as close to the middle of the main axis as possible
  center,
  /// Place the free space evenly between the children
  spaceBetween,
  /// Place the free space evenly between the children as well as before and after the first and last child
  spaceAround,
  /// Do not expand to fill the free space. None of the children may specify a flex factor.
  collapse,
}

/// How the children should be placed along the cross axis in a flex layout
enum FlexAlignItems {
  /// Place the children as close to the start of the cross axis as possible
  start,
  /// Place the children as close to the end of the cross axis as possible
  end,
  /// Place the children as close to the middle of the cross axis as possible
  center,
  /// Require the children to fill the cross axis
  stretch,
  /// Place the children along the cross axis such that their baselines match
  baseline,
}

typedef double _ChildSizingFunction(RenderBox child, BoxConstraints constraints);

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
/// flexible children) is allocated according to the [justifyContent] property.
///
/// In the cross axis, children determine their own size. The flex then sizes
/// its cross axis to fix the largest of its children. The children are then
/// positioned along the cross axis according to the [alignItems] property.
class RenderFlex extends RenderBox with ContainerRenderObjectMixin<RenderBox, FlexParentData>,
                                        RenderBoxContainerDefaultsMixin<RenderBox, FlexParentData> {

  RenderFlex({
    List<RenderBox> children,
    FlexDirection direction: FlexDirection.horizontal,
    FlexJustifyContent justifyContent: FlexJustifyContent.start,
    FlexAlignItems alignItems: FlexAlignItems.center,
    TextBaseline textBaseline
  }) : _direction = direction,
       _justifyContent = justifyContent,
       _alignItems = alignItems,
       _textBaseline = textBaseline {
    addAll(children);
  }

  /// The direction to use as the main axis
  FlexDirection get direction => _direction;
  FlexDirection _direction;
  void set direction (FlexDirection value) {
    if (_direction != value) {
      _direction = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the main axis
  FlexJustifyContent get justifyContent => _justifyContent;
  FlexJustifyContent _justifyContent;
  void set justifyContent (FlexJustifyContent value) {
    if (_justifyContent != value) {
      _justifyContent = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the cross axis
  FlexAlignItems get alignItems => _alignItems;
  FlexAlignItems _alignItems;
  void set alignItems (FlexAlignItems value) {
    if (_alignItems != value) {
      _alignItems = value;
      markNeedsLayout();
    }
  }

  /// If using aligning items according to their baseline, which baseline to use
  TextBaseline get textBaseline => _textBaseline;
  TextBaseline _textBaseline;
  void set textBaseline (TextBaseline value) {
    if (_textBaseline != value) {
      _textBaseline = value;
      markNeedsLayout();
    }
  }

  /// Set during layout if overflow occurred on the main axis
  double _overflow;

  void setupParentData(RenderBox child) {
    if (child.parentData is! FlexParentData)
      child.parentData = new FlexParentData();
  }

  double _getIntrinsicSize({ BoxConstraints constraints,
                             FlexDirection sizingDirection,
                             _ChildSizingFunction childSize }) {
    assert(constraints.isNormalized);
    // http://www.w3.org/TR/2015/WD-css-flexbox-1-20150514/#intrinsic-sizes
    if (_direction == sizingDirection) {
      // INTRINSIC MAIN SIZE
      // Intrinsic main size is the smallest size the flex container can take
      // while maintaining the min/max-content contributions of its flex items.
      BoxConstraints childConstraints;
      switch(_direction) {
        case FlexDirection.horizontal:
          childConstraints = new BoxConstraints(maxHeight: constraints.maxHeight);
          break;
        case FlexDirection.vertical:
          childConstraints = new BoxConstraints(maxWidth: constraints.maxWidth);
          break;
      }

      double totalFlex = 0.0;
      double inflexibleSpace = 0.0;
      double maxFlexFractionSoFar = 0.0;
      RenderBox child = firstChild;
      while (child != null) {
        int flex = _getFlex(child);
        totalFlex += flex;
        if (flex > 0) {
          double flexFraction = childSize(child, childConstraints) / _getFlex(child);
          maxFlexFractionSoFar = math.max(maxFlexFractionSoFar, flexFraction);
        } else {
          inflexibleSpace += childSize(child, childConstraints);
        }
        final FlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }
      double mainSize = maxFlexFractionSoFar * totalFlex + inflexibleSpace;

      // Ensure that we don't violate the given constraints with our result
      switch(_direction) {
        case FlexDirection.horizontal:
          return constraints.constrainWidth(mainSize);
        case FlexDirection.vertical:
          return constraints.constrainHeight(mainSize);
      }
    } else {
      // INTRINSIC CROSS SIZE
      // The spec wants us to perform layout into the given available main-axis
      // space and return the cross size. That's too expensive, so instead we
      // size inflexible children according to their max intrinsic size in the
      // main direction and use those constraints to determine their max
      // intrinsic size in the cross direction. We don't care if the caller
      // asked for max or min -- the answer is always computed using the
      // max size in the main direction.

      double availableMainSpace;
      BoxConstraints childConstraints;
      switch(_direction) {
        case FlexDirection.horizontal:
          childConstraints = new BoxConstraints(maxWidth: constraints.maxWidth);
          availableMainSpace = constraints.maxWidth;
          break;
        case FlexDirection.vertical:
          childConstraints = new BoxConstraints(maxHeight: constraints.maxHeight);
          availableMainSpace = constraints.maxHeight;
          break;
      }

      // Get inflexible space using the max in the main direction
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
                mainSize = child.getMaxIntrinsicWidth(childConstraints);
                BoxConstraints widthConstraints =
                  new BoxConstraints(minWidth: mainSize, maxWidth: mainSize);
                crossSize = child.getMaxIntrinsicHeight(widthConstraints);
                break;
              case FlexDirection.vertical:
                mainSize = child.getMaxIntrinsicHeight(childConstraints);
                BoxConstraints heightConstraints =
                  new BoxConstraints(minWidth: mainSize, maxWidth: mainSize);
                crossSize = child.getMaxIntrinsicWidth(heightConstraints);
                break;
          }
          inflexibleSpace += mainSize;
          maxCrossSize = math.max(maxCrossSize, crossSize);
        }
        final FlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }

      // Determine the spacePerFlex by allocating the remaining available space
      double spacePerFlex = (availableMainSpace - inflexibleSpace) / totalFlex;

      // Size remaining items, find the maximum cross size
      child = firstChild;
      while (child != null) {
        int flex = _getFlex(child);
        if (flex > 0) {
          double childMainSize = spacePerFlex * flex;
          double crossSize;
          switch (_direction) {
            case FlexDirection.horizontal:
              BoxConstraints childConstraints =
                new BoxConstraints(minWidth: childMainSize, maxWidth: childMainSize);
              crossSize = child.getMaxIntrinsicHeight(childConstraints);
              break;
            case FlexDirection.vertical:
              BoxConstraints childConstraints =
                new BoxConstraints(minHeight: childMainSize, maxHeight: childMainSize);
              crossSize = child.getMaxIntrinsicWidth(childConstraints);
              break;
          }
          maxCrossSize = math.max(maxCrossSize, crossSize);
        }
        final FlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }

      // Ensure that we don't violate the given constraints with our result
      switch(_direction) {
        case FlexDirection.horizontal:
          return constraints.constrainHeight(maxCrossSize);
        case FlexDirection.vertical:
          return constraints.constrainWidth(maxCrossSize);
      }
    }
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return _getIntrinsicSize(
      constraints: constraints,
      sizingDirection: FlexDirection.horizontal,
      childSize: (RenderBox child, BoxConstraints innerConstraints) => child.getMinIntrinsicWidth(innerConstraints)
    );
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return _getIntrinsicSize(
      constraints: constraints,
      sizingDirection: FlexDirection.horizontal,
      childSize: (RenderBox child, BoxConstraints innerConstraints) => child.getMaxIntrinsicWidth(innerConstraints)
    );
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return _getIntrinsicSize(
      constraints: constraints,
      sizingDirection: FlexDirection.vertical,
      childSize: (RenderBox child, BoxConstraints innerConstraints) => child.getMinIntrinsicHeight(innerConstraints)
    );
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return _getIntrinsicSize(
      constraints: constraints,
      sizingDirection: FlexDirection.vertical,
      childSize: (RenderBox child, BoxConstraints innerConstraints) => child.getMaxIntrinsicHeight(innerConstraints));
  }

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

  void performLayout() {
    // Originally based on http://www.w3.org/TR/css-flexbox-1/ Section 9.7 Resolving Flexible Lengths

    // Determine used flex factor, size inflexible items, calculate free space.
    int totalFlex = 0;
    int totalChildren = 0;
    assert(constraints != null);
    final double mainSize = (_direction == FlexDirection.horizontal) ? constraints.constrainWidth() : constraints.constrainHeight();
    final bool canFlex = mainSize < double.INFINITY && justifyContent != FlexJustifyContent.collapse;
    double crossSize = 0.0;  // This is determined as we lay out the children
    double freeSpace = canFlex ? mainSize : 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      final FlexParentData childParentData = child.parentData;
      totalChildren++;
      int flex = _getFlex(child);
      if (flex > 0) {
        // Flexible children can only be used when the RenderFlex box's container has a finite size.
        // When the container is infinite, for example if you are in a scrollable viewport, then
        // it wouldn't make any sense to have a flexible child.
        assert(canFlex && 'See https://flutter.github.io/layout/#flex' is String);
        totalFlex += childParentData.flex;
      } else {
        BoxConstraints innerConstraints;
        if (alignItems == FlexAlignItems.stretch) {
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
        freeSpace -= _getMainSize(child);
        crossSize = math.max(crossSize, _getCrossSize(child));
      }
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    _overflow = math.max(0.0, -freeSpace);
    freeSpace = math.max(0.0, freeSpace);

    // Distribute remaining space to flexible children, and determine baseline.
    double maxBaselineDistance = 0.0;
    double usedSpace = 0.0;
    if (totalFlex > 0 || alignItems == FlexAlignItems.baseline) {
      double spacePerFlex = totalFlex > 0 ? (freeSpace / totalFlex) : 0.0;
      child = firstChild;
      while (child != null) {
        int flex = _getFlex(child);
        if (flex > 0) {
          double spaceForChild = spacePerFlex * flex;
          BoxConstraints innerConstraints;
          if (alignItems == FlexAlignItems.stretch) {
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
        if (alignItems == FlexAlignItems.baseline) {
          assert(textBaseline != null && 'To use FlexAlignItems.baseline, you must also specify which baseline to use using the "baseline" argument.' is String);
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
      remainingSpace = math.max(0.0, freeSpace - usedSpace);
      switch (_direction) {
        case FlexDirection.horizontal:
          size = constraints.constrain(new Size(mainSize, crossSize));
          crossSize = size.height;
          assert(size.width == mainSize);
          break;
        case FlexDirection.vertical:
          size = constraints.constrain(new Size(crossSize, mainSize));
          crossSize = size.width;
          assert(size.height == mainSize);
          break;
      }
    } else {
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
    switch (_justifyContent) {
      case FlexJustifyContent.start:
      case FlexJustifyContent.collapse:
        leadingSpace = 0.0;
        betweenSpace = 0.0;
        break;
      case FlexJustifyContent.end:
        leadingSpace = remainingSpace;
        betweenSpace = 0.0;
        break;
      case FlexJustifyContent.center:
        leadingSpace = remainingSpace / 2.0;
        betweenSpace = 0.0;
        break;
      case FlexJustifyContent.spaceBetween:
        leadingSpace = 0.0;
        betweenSpace = totalChildren > 1 ? remainingSpace / (totalChildren - 1) : 0.0;
        break;
      case FlexJustifyContent.spaceAround:
        betweenSpace = totalChildren > 0 ? remainingSpace / totalChildren : 0.0;
        leadingSpace = betweenSpace / 2.0;
        break;
    }

    // Position elements
    double childMainPosition = leadingSpace;
    child = firstChild;
    while (child != null) {
      final FlexParentData childParentData = child.parentData;
      double childCrossPosition;
      switch (_alignItems) {
        case FlexAlignItems.stretch:
        case FlexAlignItems.start:
          childCrossPosition = 0.0;
          break;
        case FlexAlignItems.end:
          childCrossPosition = crossSize - _getCrossSize(child);
          break;
        case FlexAlignItems.center:
          childCrossPosition = crossSize / 2.0 - _getCrossSize(child) / 2.0;
          break;
        case FlexAlignItems.baseline:
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
          childParentData.position = new Point(childMainPosition, childCrossPosition);
          break;
        case FlexDirection.vertical:
          childParentData.position = new Point(childCrossPosition, childMainPosition);
          break;
      }
      childMainPosition += _getMainSize(child) + betweenSpace;
      child = childParentData.nextSibling;
    }
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position);
  }

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
      const kMarkerSize = 0.1;
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

  String toString() {
    String header = super.toString();
    if (_overflow is double && _overflow > 0.0)
      header += ' OVERFLOWING';
    return header;
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('direction: $_direction');
    settings.add('justifyContent: $_justifyContent');
    settings.add('alignItems: $_alignItems');
    settings.add('textBaseline: $_textBaseline');
  }

}
