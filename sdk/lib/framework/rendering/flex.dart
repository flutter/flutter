// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'box.dart';
import 'object.dart';

class FlexBoxParentData extends BoxParentData with ContainerParentDataMixin<RenderBox> {
  int flex;
  void merge(FlexBoxParentData other) {
    if (other.flex != null)
      flex = other.flex;
    super.merge(other);
  }
  String toString() => '${super.toString()}; flex=$flex';
}

enum FlexDirection { horizontal, vertical }
enum FlexJustifyContent {
  flexStart,
  flexEnd,
  center,
  spaceBetween,
  spaceAround,
}

class RenderFlex extends RenderBox with ContainerRenderObjectMixin<RenderBox, FlexBoxParentData>,
                                        RenderBoxContainerDefaultsMixin<RenderBox, FlexBoxParentData> {
  // lays out RenderBox children using flexible layout

  RenderFlex({
    FlexDirection direction: FlexDirection.horizontal,
    FlexJustifyContent justifyContent: FlexJustifyContent.flexStart
  }) : _direction = direction, _justifyContent = justifyContent;

  FlexDirection _direction;
  FlexDirection get direction => _direction;
  void set direction (FlexDirection value) {
    if (_direction != value) {
      _direction = value;
      markNeedsLayout();
    }
  }

  FlexJustifyContent _justifyContent;
  FlexJustifyContent get justifyContent => _justifyContent;
  void set justifyContent (FlexJustifyContent value) {
    if (_justifyContent != value) {
      _justifyContent = value;
      markNeedsLayout();
    }
  }

  void setParentData(RenderBox child) {
    if (child.parentData is! FlexBoxParentData)
      child.parentData = new FlexBoxParentData();
  }

  // We don't currently support this for RenderFlex
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(false);
    return constraints.constrainWidth(0.0);
  }

  // We don't currently support this for RenderFlex
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(false);
    return constraints.constrainWidth(0.0);
  }

  // We don't currently support this for RenderFlex
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(false);
    return constraints.constrainHeight(0.0);
  }

  // We don't currently support this for RenderFlex
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(false);
    return constraints.constrainHeight(0.0);
  }

  bool get sizedByParent => true;
  void performResize() {
    size = constraints.constrain(new Size(constraints.maxWidth, constraints.maxHeight));
    assert(size.height < double.INFINITY);
    assert(size.width < double.INFINITY);
  }

  int _getFlex(RenderBox child) {
    assert(child.parentData is FlexBoxParentData);
    return child.parentData.flex != null ? child.parentData.flex : 0;
  }

  void performLayout() {
    // Based on http://www.w3.org/TR/css-flexbox-1/ Section 9.7 Resolving Flexible Lengths
    // Steps 1-3. Determine used flex factor, size inflexible items, calculate free space
    int totalFlex = 0;
    int totalChildren = 0;
    assert(constraints != null);
    double freeSpace = (_direction == FlexDirection.horizontal) ? constraints.maxWidth : constraints.maxHeight;
    RenderBox child = firstChild;
    while (child != null) {
      totalChildren++;
      int flex = _getFlex(child);
      if (flex > 0) {
        totalFlex += child.parentData.flex;
      } else {
        BoxConstraints innerConstraints = new BoxConstraints(maxHeight: constraints.maxHeight,
                                                             maxWidth: constraints.maxWidth);
        child.layout(innerConstraints, parentUsesSize: true);
        freeSpace -= (_direction == FlexDirection.horizontal) ? child.size.width : child.size.height;
      }
      child = child.parentData.nextSibling;
    }

    // Steps 4-5. Distribute remaining space to flexible children.
    double spacePerFlex = totalFlex > 0 ? (freeSpace / totalFlex) : 0.0;
    double usedSpace = 0.0;
    child = firstChild;
    while (child != null) {
      int flex = _getFlex(child);
      if (flex > 0) {
        double spaceForChild = spacePerFlex * flex;
        BoxConstraints innerConstraints;
        switch (_direction) {
          case FlexDirection.horizontal:
            innerConstraints = new BoxConstraints(maxHeight: constraints.maxHeight,
                                                  minWidth: spaceForChild,
                                                  maxWidth: spaceForChild);
            break;
          case FlexDirection.vertical:
            innerConstraints = new BoxConstraints(minHeight: spaceForChild,
                                                  maxHeight: spaceForChild,
                                                  maxWidth: constraints.maxWidth);
            break;
        }
        child.layout(innerConstraints, parentUsesSize: true);
        usedSpace += _direction == FlexDirection.horizontal ? child.size.width : child.size.height;
      }
      child = child.parentData.nextSibling;
    }

    // Section 8.2: Axis Alignment using the justify-content property
    double remainingSpace = math.max(0.0, freeSpace - usedSpace);
    double leadingSpace;
    double betweenSpace;
    child = firstChild;
    switch (_justifyContent) {
      case FlexJustifyContent.flexStart:
        leadingSpace = 0.0;
        betweenSpace = 0.0;
        break;
      case FlexJustifyContent.flexEnd:
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

    // Position elements. For now, center the flex items in the cross direction
    double mainDimPosition = leadingSpace;
    child = firstChild;
    while (child != null) {
      switch (_direction) {
        case FlexDirection.horizontal:
          child.parentData.position = new Point(mainDimPosition, size.height / 2.0 - child.size.height / 2.0);
          mainDimPosition += child.size.width;
          break;
        case FlexDirection.vertical:
          child.parentData.position = new Point(size.width / 2.0 - child.size.width / 2.0, mainDimPosition);
          mainDimPosition += child.size.height;
          break;
      }
      mainDimPosition += betweenSpace;
      child = child.parentData.nextSibling;
    }
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position);
  }

  void paint(RenderObjectDisplayList canvas) {
    defaultPaint(canvas);
  }
}
