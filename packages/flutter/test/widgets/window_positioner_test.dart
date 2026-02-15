// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member

import 'dart:ui';
import 'package:flutter/src/widgets/_window_positioner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindowPlacementTest', () {
    const clientDisplayArea = Rect.fromLTWH(0, 0, 800, 600);
    const clientParentSize = Size(400, 300);
    const clientChildSize = Size(100, 50);
    final clientParentPosition = Offset(
      (clientDisplayArea.width - clientParentSize.width) / 2,
      (clientDisplayArea.height - clientParentSize.height) / 2,
    );

    final clientParentRect = Rect.fromLTWH(
      clientParentPosition.dx,
      clientParentPosition.dy,
      clientParentSize.width,
      clientParentSize.height,
    );

    const displayArea = Rect.fromLTWH(0, 0, 640, 480);
    const parentSize = Size(600, 400);
    const childSize = Size(300, 300);
    const rectangleNearRhs = Rect.fromLTWH(590, 20, 10, 20);
    const rectangleNearLeftSide = Rect.fromLTWH(0, 20, 20, 20);
    const rectangleNearAllSides = Rect.fromLTWH(0, 20, 600, 380);
    const rectangleNearBottom = Rect.fromLTWH(20, 380, 20, 20);
    const rectangleNearBothBottomRight = Rect.fromLTWH(400, 380, 200, 20);

    final parentPosition = Offset(
      (displayArea.width - parentSize.width) / 2,
      (displayArea.height - parentSize.height) / 2,
    );

    final parentRect = Rect.fromLTWH(
      parentPosition.dx,
      parentPosition.dy,
      parentSize.width,
      parentSize.height,
    );

    Rect anchorRectFor(Rect rect) => rect.translate(parentPosition.dx, parentPosition.dy);
    Offset onTopEdge(Rect rect, Size childSize) => rect.topLeft - Offset(0, childSize.height);
    Offset onLeftEdge(Rect rect, Size childSize) => rect.topLeft - Offset(childSize.width, 0);

    test('Client anchors to parent given anchor rectangle right of parent', () {
      const rectSize = 10.0;
      final overlappingRight = Rect.fromCenter(
        center: clientParentRect.topRight.translate(-rectSize / 2, clientParentRect.height / 2),
        width: rectSize,
        height: rectSize,
      );

      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topRight,
        childAnchor: WindowPositionerAnchor.topLeft,
        constraintAdjustment: WindowPositionerConstraintAdjustment(slideY: true, resizeX: true),
      );

      final Rect childRect = positioner.placeWindow(
        childSize: clientChildSize,
        anchorRect: overlappingRight,
        parentRect: clientParentRect,
        displayRect: clientDisplayArea,
      );

      final Offset expectedPosition = overlappingRight.topRight;

      expect(childRect.topLeft, expectedPosition);
      expect(childRect.size, clientChildSize);
    });

    test('Client anchors to parent given anchor rectangle above parent', () {
      const rectSize = 10.0;
      final overlappingAbove = Rect.fromCenter(
        center: clientParentRect.topCenter.translate(0, -rectSize / 2),
        width: rectSize,
        height: rectSize,
      );

      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topRight,
        childAnchor: WindowPositionerAnchor.bottomRight,
        constraintAdjustment: WindowPositionerConstraintAdjustment(slideX: true),
      );

      final Rect childRect = positioner.placeWindow(
        childSize: clientChildSize,
        anchorRect: overlappingAbove,
        parentRect: clientParentRect,
        displayRect: clientDisplayArea,
      );

      final Offset expectedPosition =
          overlappingAbove.bottomRight - Offset(clientChildSize.width, clientChildSize.height);

      expect(childRect.topLeft, expectedPosition);
      expect(childRect.size, clientChildSize);
    });

    test('Client anchors to parent given offset right of parent', () {
      const rectSize = 10.0;
      final midRight = Rect.fromLTWH(
        clientParentRect.right - rectSize,
        clientParentRect.center.dy,
        rectSize,
        rectSize,
      );

      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topRight,
        childAnchor: WindowPositionerAnchor.topLeft,
        offset: Offset(rectSize, 0),
        constraintAdjustment: WindowPositionerConstraintAdjustment(slideY: true, resizeX: true),
      );

      final Rect childRect = positioner.placeWindow(
        childSize: clientChildSize,
        anchorRect: midRight,
        parentRect: clientParentRect,
        displayRect: clientDisplayArea,
      );

      final Offset expectedPosition = midRight.topRight;

      expect(childRect.topLeft, expectedPosition);
      expect(childRect.size, clientChildSize);
    });

    test('Client anchors to parent given offset above parent', () {
      const rectSize = 10.0;
      final midTop = Rect.fromLTWH(
        clientParentRect.center.dx,
        clientParentRect.top,
        rectSize,
        rectSize,
      );

      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topRight,
        childAnchor: WindowPositionerAnchor.bottomRight,
        offset: Offset(0, -rectSize),
        constraintAdjustment: WindowPositionerConstraintAdjustment(slideX: true),
      );

      final Rect childRect = positioner.placeWindow(
        childSize: clientChildSize,
        anchorRect: midTop,
        parentRect: clientParentRect,
        displayRect: clientDisplayArea,
      );

      final Offset expectedPosition =
          clientParentPosition +
          Offset(clientParentSize.width / 2 + rectSize, 0) -
          Offset(clientChildSize.width, clientChildSize.height);

      expect(childRect.topLeft, expectedPosition);
      expect(childRect.size, clientChildSize);
    });

    test('Client anchors to parent given anchor rectangle and offset below left parent', () {
      const rectSize = 10.0;
      final belowLeft = Rect.fromLTWH(
        clientParentRect.left - rectSize,
        clientParentRect.bottom,
        rectSize,
        rectSize,
      );

      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.bottomLeft,
        childAnchor: WindowPositionerAnchor.topRight,
        offset: Offset(-rectSize, rectSize),
        constraintAdjustment: WindowPositionerConstraintAdjustment(resizeX: true, resizeY: true),
      );

      final Rect childRect = positioner.placeWindow(
        childSize: clientChildSize,
        anchorRect: belowLeft,
        parentRect: clientParentRect,
        displayRect: clientDisplayArea,
      );

      final Offset expectedPosition =
          clientParentRect.bottomLeft - Offset(clientChildSize.width, 0);

      expect(childRect.topLeft, expectedPosition);
      expect(childRect.size, clientChildSize);
    });

    group('Can attach by every anchor given no constraint adjustment', () {
      Offset anchorPositionFor(WindowPositionerAnchor anchor, Rect rect) {
        return switch (anchor) {
          WindowPositionerAnchor.center => rect.center,
          WindowPositionerAnchor.top => rect.topCenter,
          WindowPositionerAnchor.bottom => rect.bottomCenter,
          WindowPositionerAnchor.left => rect.centerLeft,
          WindowPositionerAnchor.right => rect.centerRight,
          WindowPositionerAnchor.topLeft => rect.topLeft,
          WindowPositionerAnchor.bottomLeft => rect.bottomLeft,
          WindowPositionerAnchor.topRight => rect.topRight,
          WindowPositionerAnchor.bottomRight => rect.bottomRight,
        };
      }

      for (final WindowPositionerAnchor parentAnchor in WindowPositionerAnchor.values) {
        for (final WindowPositionerAnchor childAnchor in WindowPositionerAnchor.values) {
          test('parent: $parentAnchor, child: $childAnchor', () {
            final Rect anchorRect = anchorRectFor(const Rect.fromLTWH(100, 50, 20, 20));
            final positioner = WindowPositioner(
              parentAnchor: parentAnchor,
              childAnchor: childAnchor,
            );

            final Rect childRect = positioner.placeWindow(
              childSize: childSize,
              anchorRect: anchorRect,
              parentRect: parentRect,
              displayRect: displayArea,
            );

            expect(
              anchorPositionFor(childAnchor, childRect),
              anchorPositionFor(parentAnchor, anchorRect),
            );
          });
        }
      }
    });

    test('Placement is flipped given anchor rectangle near right side and offset', () {
      const xOffset = 42.0;
      const yOffset = 13.0;
      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topRight,
        childAnchor: WindowPositionerAnchor.topLeft,
        offset: Offset(xOffset, yOffset),
        constraintAdjustment: WindowPositionerConstraintAdjustment(flipX: true),
      );

      final Rect anchorRect = anchorRectFor(rectangleNearRhs);
      final Rect childRect = positioner.placeWindow(
        childSize: childSize,
        anchorRect: anchorRect,
        parentRect: parentRect,
        displayRect: displayArea,
      );

      final Offset expectedPosition =
          onLeftEdge(anchorRect, childSize) + const Offset(-xOffset, yOffset);

      expect(childRect.topLeft, expectedPosition);
    });

    test('Placement is flipped given anchor rectangle near bottom and offset', () {
      const xOffset = 42.0;
      const yOffset = 13.0;
      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.bottomLeft,
        childAnchor: WindowPositionerAnchor.topLeft,
        offset: Offset(xOffset, yOffset),
        constraintAdjustment: WindowPositionerConstraintAdjustment(flipY: true),
      );

      final Rect anchorRect = anchorRectFor(rectangleNearBottom);
      final Rect childRect = positioner.placeWindow(
        childSize: childSize,
        anchorRect: anchorRect,
        parentRect: parentRect,
        displayRect: displayArea,
      );

      final Offset expectedPosition =
          onTopEdge(anchorRect, childSize) + const Offset(xOffset, -yOffset);

      expect(childRect.topLeft, expectedPosition);
    });

    test('Placement is flipped both ways given anchor rectangle near bottom right and offset', () {
      const xOffset = 42.0;
      const yOffset = 13.0;
      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.bottomRight,
        childAnchor: WindowPositionerAnchor.topLeft,
        offset: Offset(xOffset, yOffset),
        constraintAdjustment: WindowPositionerConstraintAdjustment(flipX: true, flipY: true),
      );

      final Rect anchorRect = anchorRectFor(rectangleNearBothBottomRight);
      final Rect childRect = positioner.placeWindow(
        childSize: childSize,
        anchorRect: anchorRect,
        parentRect: parentRect,
        displayRect: displayArea,
      );

      final Offset expectedPosition =
          anchorRect.topLeft -
          Offset(childSize.width, childSize.height) -
          const Offset(xOffset, yOffset);

      expect(childRect.topLeft, expectedPosition);
    });

    test('Placement can slide in X given anchor rectangle near right side', () {
      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topRight,
        childAnchor: WindowPositionerAnchor.topLeft,
        constraintAdjustment: WindowPositionerConstraintAdjustment(slideX: true),
      );

      final Rect anchorRect = anchorRectFor(rectangleNearRhs);
      final Rect childRect = positioner.placeWindow(
        childSize: childSize,
        anchorRect: anchorRect,
        parentRect: parentRect,
        displayRect: displayArea,
      );

      expect(childRect.topLeft.dx, displayArea.right - childSize.width);
    });

    test('Placement can slide in X given anchor rectangle near left side', () {
      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topLeft,
        childAnchor: WindowPositionerAnchor.topRight,
        constraintAdjustment: WindowPositionerConstraintAdjustment(slideX: true),
      );

      final Rect anchorRect = anchorRectFor(rectangleNearLeftSide);
      final Rect childRect = positioner.placeWindow(
        childSize: childSize,
        anchorRect: anchorRect,
        parentRect: parentRect,
        displayRect: displayArea,
      );

      expect(childRect.topLeft.dx, displayArea.left);
    });

    test('Placement can slide in Y given anchor rectangle near bottom', () {
      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.bottomLeft,
        childAnchor: WindowPositionerAnchor.topLeft,
        constraintAdjustment: WindowPositionerConstraintAdjustment(slideY: true),
      );

      final Rect anchorRect = anchorRectFor(rectangleNearBottom);
      final Rect childRect = positioner.placeWindow(
        childSize: childSize,
        anchorRect: anchorRect,
        parentRect: parentRect,
        displayRect: displayArea,
      );

      expect(childRect.topLeft.dy, displayArea.bottom - childSize.height);
    });

    test('Placement can slide in Y given anchor rectangle near top', () {
      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topLeft,
        childAnchor: WindowPositionerAnchor.bottomLeft,
        constraintAdjustment: WindowPositionerConstraintAdjustment(slideY: true),
      );

      final Rect anchorRect = anchorRectFor(rectangleNearAllSides);
      final Rect childRect = positioner.placeWindow(
        childSize: childSize,
        anchorRect: anchorRect,
        parentRect: parentRect,
        displayRect: displayArea,
      );

      expect(childRect.topLeft.dy, displayArea.top);
    });

    test('Placement can slide in X and Y given anchor rectangle near bottom right and offset', () {
      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.bottomLeft,
        childAnchor: WindowPositionerAnchor.topLeft,
        constraintAdjustment: WindowPositionerConstraintAdjustment(slideX: true, slideY: true),
      );

      final Rect anchorRect = anchorRectFor(rectangleNearBothBottomRight);
      final Rect childRect = positioner.placeWindow(
        childSize: childSize,
        anchorRect: anchorRect,
        parentRect: parentRect,
        displayRect: displayArea,
      );

      final expectedPosition = Offset(
        displayArea.right - childSize.width,
        displayArea.bottom - childSize.height,
      );

      expect(childRect.topLeft, expectedPosition);
    });

    test('Placement can resize in X given anchor rectangle near right side', () {
      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topRight,
        childAnchor: WindowPositionerAnchor.topLeft,
        constraintAdjustment: WindowPositionerConstraintAdjustment(resizeX: true),
      );

      final Rect anchorRect = anchorRectFor(rectangleNearRhs);
      final Rect childRect = positioner.placeWindow(
        childSize: childSize,
        anchorRect: anchorRect,
        parentRect: parentRect,
        displayRect: displayArea,
      );

      expect(childRect.width, displayArea.right - (anchorRect.left + anchorRect.width));
    });

    test('Placement can resize in X given anchor rectangle near left side', () {
      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topLeft,
        childAnchor: WindowPositionerAnchor.topRight,
        constraintAdjustment: WindowPositionerConstraintAdjustment(resizeX: true),
      );

      final Rect anchorRect = anchorRectFor(rectangleNearLeftSide);
      final Rect childRect = positioner.placeWindow(
        childSize: childSize,
        anchorRect: anchorRect,
        parentRect: parentRect,
        displayRect: displayArea,
      );

      expect(childRect.width, anchorRect.left - displayArea.left);
    });

    test('Placement can resize in Y given anchor rectangle near bottom', () {
      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.bottomLeft,
        childAnchor: WindowPositionerAnchor.topLeft,
        constraintAdjustment: WindowPositionerConstraintAdjustment(resizeY: true),
      );

      final Rect anchorRect = anchorRectFor(rectangleNearAllSides);
      final Rect childRect = positioner.placeWindow(
        childSize: childSize,
        anchorRect: anchorRect,
        parentRect: parentRect,
        displayRect: displayArea,
      );

      expect(childRect.height, displayArea.bottom - (anchorRect.top + anchorRect.height));
    });

    test('Placement can resize in Y given anchor rectangle near top', () {
      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topLeft,
        childAnchor: WindowPositionerAnchor.bottomLeft,
        constraintAdjustment: WindowPositionerConstraintAdjustment(resizeY: true),
      );

      final Rect anchorRect = anchorRectFor(rectangleNearAllSides);
      final Rect childRect = positioner.placeWindow(
        childSize: childSize,
        anchorRect: anchorRect,
        parentRect: parentRect,
        displayRect: displayArea,
      );

      expect(childRect.height, anchorRect.top - displayArea.top);
    });

    test('Placement can resize in X and Y given anchor rectangle near bottom right and offset', () {
      const positioner = WindowPositioner(
        parentAnchor: WindowPositionerAnchor.bottomRight,
        childAnchor: WindowPositionerAnchor.topLeft,
        constraintAdjustment: WindowPositionerConstraintAdjustment(resizeX: true, resizeY: true),
      );

      final Rect anchorRect = anchorRectFor(rectangleNearBothBottomRight);
      final Rect childRect = positioner.placeWindow(
        childSize: childSize,
        anchorRect: anchorRect,
        parentRect: parentRect,
        displayRect: displayArea,
      );

      final expectedSize = Size(
        displayArea.right - (anchorRect.left + anchorRect.width),
        displayArea.bottom - (anchorRect.top + anchorRect.height),
      );

      expect(childRect.size, expectedSize);
    });
  });
}
