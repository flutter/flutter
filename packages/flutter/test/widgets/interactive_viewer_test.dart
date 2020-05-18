// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' show Quad, Vector3, Matrix4;

void main() {
  group('InteractiveViewer', () {
    testWidgets('child fits in viewport', (WidgetTester tester) async {
      final ValueNotifier<Matrix4> transformationController =
          ValueNotifier<Matrix4>(Matrix4.identity());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                disableRotation: true,
                transformationController: transformationController,
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      expect(transformationController.value, equals(Matrix4.identity()));

      // Attempting to drag to pan doesn't work because the child fits inside
      // the viewport and has a tight boundary.
      final Offset childOffset = tester.getTopLeft(find.byType(Container));
      final Offset insideChild = Offset(
        childOffset.dx + 20.0,
        childOffset.dy + 20.0,
      );
      TestGesture gesture = await tester.startGesture(insideChild);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(childOffset);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, equals(Matrix4.identity()));

      // Pinch to zoom works.
      final Offset scaleStart1 = insideChild;
      final Offset scaleStart2 = Offset(insideChild.dx + 10.0, insideChild.dy);
      final Offset scaleEnd1 = Offset(insideChild.dx - 10.0, insideChild.dy);
      final Offset scaleEnd2 = Offset(insideChild.dx + 20.0, insideChild.dy);
      gesture = await tester.createGesture();
      final TestGesture gesture2 = await tester.createGesture();
      await gesture.down(scaleStart1);
      await gesture2.down(scaleStart2);
      await tester.pump();
      await gesture.moveTo(scaleEnd1);
      await gesture2.moveTo(scaleEnd2);
      await tester.pump();
      await gesture.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, isNot(equals(Matrix4.identity())));
    });

    testWidgets('child bigger than viewport', (WidgetTester tester) async {
      final ValueNotifier<Matrix4> transformationController =
          ValueNotifier<Matrix4>(Matrix4.identity());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                disableRotation: true,
                disableScale: true,
                transformationController: transformationController,
                child: Container(width: 2000.0, height: 2000.0),
              ),
            ),
          ),
        ),
      );

      expect(transformationController.value, equals(Matrix4.identity()));

      // Attempting to move against the boundary doesn't work.
      final Offset childOffset = tester.getTopLeft(find.byType(Container));
      final Offset insideChild = Offset(
        childOffset.dx + 20.0,
        childOffset.dy + 20.0,
      );
      TestGesture gesture = await tester.startGesture(childOffset);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(insideChild);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, equals(Matrix4.identity()));

      // Attempting to pinch to zoom doens't work.
      final Offset scaleStart1 = insideChild;
      final Offset scaleStart2 = Offset(insideChild.dx + 10.0, insideChild.dy);
      final Offset scaleEnd1 = Offset(insideChild.dx - 10.0, insideChild.dy);
      final Offset scaleEnd2 = Offset(insideChild.dx + 20.0, insideChild.dy);
      gesture = await tester.startGesture(scaleStart1);
      TestGesture gesture2 = await tester.startGesture(scaleStart2);
      addTearDown(gesture2.removePointer);
      await tester.pump();
      await gesture.moveTo(scaleEnd1);
      await gesture2.moveTo(scaleEnd2);
      await tester.pump();
      await gesture.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, equals(Matrix4.identity()));

      // Attempting to pinch to rotate doesn't work because it's disabled.
      final Offset rotateStart1 = insideChild;
      final Offset rotateStart2 = Offset(insideChild.dx + 10.0, insideChild.dy);
      final Offset rotateEnd1 = Offset(insideChild.dx + 5.0, insideChild.dy + 5.0);
      final Offset rotateEnd2 = Offset(insideChild.dx - 5.0, insideChild.dy - 5.0);
      gesture = await tester.startGesture(rotateStart1);
      gesture2 = await tester.startGesture(rotateStart2);
      await tester.pump();
      await gesture.moveTo(rotateEnd1);
      await gesture2.moveTo(rotateEnd2);
      await tester.pump();
      await gesture.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, equals(Matrix4.identity()));

      // Drag to pan away from the boundary.
      gesture = await tester.startGesture(insideChild);
      await tester.pump();
      await gesture.moveTo(childOffset);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, isNot(equals(Matrix4.identity())));
    });
  });

  group('getNearestPointOnLine', () {
    test('does not modify parameters', () {
      final Vector3 point = Vector3(5.0, 5.0, 0.0);
      final Vector3 a = Vector3(0.0, 0.0, 0.0);
      final Vector3 b = Vector3(10.0, 0.0, 0.0);

      final Vector3 closestPoint = getNearestPointOnLine(point, a , b);

      expect(closestPoint, Vector3(5.0, 0.0, 0.0));
      expect(point, Vector3(5.0, 5.0, 0.0));
      expect(a, Vector3(0.0, 0.0, 0.0));
      expect(b, Vector3(10.0, 0.0, 0.0));
    });

    test('simple example', () {
      final Vector3 point = Vector3(0.0, 5.0, 0.0);
      final Vector3 a = Vector3(0.0, 0.0, 0.0);
      final Vector3 b = Vector3(5.0, 5.0, 0.0);

      expect(getNearestPointOnLine(point, a, b), Vector3(2.5, 2.5, 0.0));
    });

    test('closest to a', () {
      final Vector3 point = Vector3(-1.0, -1.0, 0.0);
      final Vector3 a = Vector3(0.0, 0.0, 0.0);
      final Vector3 b = Vector3(5.0, 5.0, 0.0);

      expect(getNearestPointOnLine(point, a, b), a);
    });

    test('closest to b', () {
      final Vector3 point = Vector3(6.0, 6.0, 0.0);
      final Vector3 a = Vector3(0.0, 0.0, 0.0);
      final Vector3 b = Vector3(5.0, 5.0, 0.0);

      expect(getNearestPointOnLine(point, a, b), b);
    });

    test('point already on the line returns the point', () {
      final Vector3 point = Vector3(2.0, 2.0, 0.0);
      final Vector3 a = Vector3(0.0, 0.0, 0.0);
      final Vector3 b = Vector3(5.0, 5.0, 0.0);

      expect(getNearestPointOnLine(point, a, b), point);
    });

    test('real example', () {
      final Vector3 point = Vector3(-436.9, 433.6, 0.0);
      final Vector3 a = Vector3(-1114.0, -60.3, 0.0);
      final Vector3 b = Vector3(288.8, 432.7, 0.0);

      final Vector3 closestPoint = getNearestPointOnLine(point, a , b);

      expect(closestPoint.x, closeTo(-356.8, 0.1));
      expect(closestPoint.y, closeTo(205.8, 0.1));
    });
  });

  group('getAxisAlignedBoundingBox', () {
    test('rectangle already axis aligned returns the rectangle', () {
      final Quad quad = Quad.points(
        Vector3(0.0, 0.0, 0.0),
        Vector3(10.0, 0.0, 0.0),
        Vector3(10.0, 10.0, 0.0),
        Vector3(0.0, 10.0, 0.0),
      );

      final Quad aabb = getAxisAlignedBoundingBox(quad);

      expect(aabb.point0, quad.point0);
      expect(aabb.point1, quad.point1);
      expect(aabb.point2, quad.point2);
      expect(aabb.point3, quad.point3);
    });

    test('rectangle rotated by 45 degrees', () {
      final Quad quad = Quad.points(
        Vector3(0.0, 5.0, 0.0),
        Vector3(5.0, 10.0, 0.0),
        Vector3(10.0, 5.0, 0.0),
        Vector3(5.0, 0.0, 0.0),
      );

      final Quad aabb = getAxisAlignedBoundingBox(quad);

      expect(aabb.point0, Vector3(0.0, 0.0, 0.0));
      expect(aabb.point1, Vector3(10.0, 0.0, 0.0));
      expect(aabb.point2, Vector3(10.0, 10.0, 0.0));
      expect(aabb.point3, Vector3(0.0, 10.0, 0.0));
    });

    test('rectangle rotated very slightly', () {
      final Quad quad = Quad.points(
        Vector3(0.0, 1.0, 0.0),
        Vector3(1.0, 11.0, 0.0),
        Vector3(11.0, 9.0, 0.0),
        Vector3(9.0, -1.0, 0.0),
      );

      final Quad aabb = getAxisAlignedBoundingBox(quad);

      expect(aabb.point0, Vector3(0.0, -1.0, 0.0));
      expect(aabb.point1, Vector3(11.0, -1.0, 0.0));
      expect(aabb.point2, Vector3(11.0, 11.0, 0.0));
      expect(aabb.point3, Vector3(0.0, 11.0, 0.0));
    });

    test('example from hexagon board', () {
      final Quad quad = Quad.points(
        Vector3(-462.7, 165.9, 0.0),
        Vector3(690.6, -576.7, 0.0),
        Vector3(1188.1, 196.0, 0.0),
        Vector3(34.9, 938.6, 0.0),
      );

      final Quad aabb = getAxisAlignedBoundingBox(quad);

      expect(aabb.point0, Vector3(-462.7, -576.7, 0.0));
      expect(aabb.point1, Vector3(1188.1, -576.7, 0.0));
      expect(aabb.point2, Vector3(1188.1, 938.6, 0.0));
      expect(aabb.point3, Vector3(-462.7, 938.6, 0.0));
    });
  });

  group('pointIsInside', () {
    test('inside', () {
      final Quad quad = Quad.points(
        Vector3(0.0, 0.0, 0.0),
        Vector3(0.0, 10.0, 0.0),
        Vector3(10.0, 10.0, 0.0),
        Vector3(10.0, 0.0, 0.0),
      );
      final Vector3 point = Vector3(5.0, 5.0, 0.0);

      expect(pointIsInside(point, quad), true);
    });

    test('outside', () {
      final Quad quad = Quad.points(
        Vector3(0.0, 0.0, 0.0),
        Vector3(0.0, 10.0, 0.0),
        Vector3(10.0, 10.0, 0.0),
        Vector3(10.0, 0.0, 0.0),
      );
      final Vector3 point = Vector3(12.0, 0.0, 0.0);

      expect(pointIsInside(point, quad), false);
    });

    test('on the edge', () {
      final Quad quad = Quad.points(
        Vector3(0.0, 0.0, 0.0),
        Vector3(0.0, 10.0, 0.0),
        Vector3(10.0, 10.0, 0.0),
        Vector3(10.0, 0.0, 0.0),
      );
      final Vector3 point = Vector3(0.0, 0.0, 0.0);

      expect(pointIsInside(point, quad), true);
    });
  });

  group('getNearestPointInside', () {
    test('point already inside quad', () {
      final Vector3 point = Vector3(5.0, 5.0, 0.0);
      final Quad quad = Quad.points(
        Vector3(0.0, 0.0, 0.0),
        Vector3(0.0, 10.0, 0.0),
        Vector3(10.0, 10.0, 0.0),
        Vector3(10.0, 0.0, 0.0),
      );

      final Vector3 nearestPoint = getNearestPointInside(point, quad);

      expect(nearestPoint, point);
    });

    test('axis aligned quad', () {
      final Vector3 point = Vector3(5.0, 15.0, 0.0);
      final Quad quad = Quad.points(
        Vector3(0.0, 0.0, 0.0),
        Vector3(0.0, 10.0, 0.0),
        Vector3(10.0, 10.0, 0.0),
        Vector3(10.0, 0.0, 0.0),
      );

      final Vector3 nearestPoint = getNearestPointInside(point, quad);

      expect(nearestPoint, Vector3(5.0, 10.0, 0.0));
    });

    test('not axis aligned quad', () {
      final Vector3 point = Vector3(5.0, 15.0, 0.0);
      final Quad quad = Quad.points(
        Vector3(0.0, 0.0, 0.0),
        Vector3(2.0, 10.0, 0.0),
        Vector3(12.0, 12.0, 0.0),
        Vector3(10.0, 2.0, 0.0),
      );

      final Vector3 nearestPoint = getNearestPointInside(point, quad);

      expect(nearestPoint.x, closeTo(5.8, 0.1));
      expect(nearestPoint.y, closeTo(10.8, 0.1));
    });
  });
}
