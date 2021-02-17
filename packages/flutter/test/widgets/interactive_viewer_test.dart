// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' show Quad, Vector3, Matrix4, Matrix3;

import 'gesture_utils.dart';

void main() {
  group('InteractiveViewer', () {
    testWidgets('child fits in viewport', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
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
      final Offset childInterior = Offset(
        childOffset.dx + 20.0,
        childOffset.dy + 20.0,
      );
      TestGesture gesture = await tester.startGesture(childInterior);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(childOffset);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, equals(Matrix4.identity()));

      // Pinch to zoom works.
      final Offset scaleStart1 = childInterior;
      final Offset scaleStart2 = Offset(childInterior.dx + 10.0, childInterior.dy);
      final Offset scaleEnd1 = Offset(childInterior.dx - 10.0, childInterior.dy);
      final Offset scaleEnd2 = Offset(childInterior.dx + 20.0, childInterior.dy);
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

    testWidgets('child fits in viewport - rotation', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                // Scale seems to supercede rotation in the tests, so disable it
                // here for simplicity.
                scaleEnabled: false,
                transformationController: transformationController,
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      expect(transformationController.value, equals(Matrix4.identity()));

      // Pinch to rotate works.
      final Offset childOffset = tester.getTopLeft(find.byType(Container));
      final Offset childCenter = Offset(
        childOffset.dx + 100.0,
        childOffset.dy + 100.0,
      );
      const double radius = 20.0;
      final Offset rotateStart1 = Offset(childCenter.dx - radius, childCenter.dy);
      final Offset rotateStart2 = Offset(childCenter.dx + radius, childCenter.dy);
      // Rotate each finger 45 degrees in opposite directions on a circle of
      // radius 20.0 pixels.
      final double value = radius * math.sin(math.pi / 4);
      final Offset rotateEnd1 = Offset(childCenter.dx - value, childCenter.dy - value);
      final Offset rotateEnd2 = Offset(childCenter.dx + value, childCenter.dy + value);
      final TestGesture gesture = await tester.createGesture();
      addTearDown(gesture.removePointer);
      final TestGesture gesture2 = await tester.createGesture();
      addTearDown(gesture2.removePointer);
      await gesture.down(rotateStart1);
      await gesture2.down(rotateStart2);
      await tester.pump();
      await gesture.moveTo(rotateEnd1);
      await gesture2.moveTo(rotateEnd2);
      await tester.pump();
      await gesture.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, isNot(equals(Matrix4.identity())));
      expect(transformationController.value.getMaxScaleOnAxis(), equals(1.0));
      final Matrix3 rotationMatrix = transformationController.value.getRotation();
      final double rotation = math.atan2(rotationMatrix.row1.x, rotationMatrix.row0.x);
      expect(rotation, moreOrLessEquals(math.pi / 8, epsilon: 1e-9));
    });

    testWidgets('boundary slightly bigger than child', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      const double boundaryMargin = 10.0;
      const double minScale = 0.8;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(boundaryMargin),
                minScale: minScale,
                transformationController: transformationController,
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      expect(transformationController.value, equals(Matrix4.identity()));

      // Dragging to pan works only until it hits the boundary.
      final Offset childOffset = tester.getTopLeft(find.byType(Container));
      final Offset childInterior = Offset(
        childOffset.dx + 20.0,
        childOffset.dy + 20.0,
      );
      TestGesture gesture = await tester.startGesture(childInterior);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(childOffset);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      final Vector3 translation = transformationController.value.getTranslation();
      expect(translation.x, -boundaryMargin);
      expect(translation.y, -boundaryMargin);

      // Pinch to zoom also only works until expanding to the boundary.
      final Offset scaleStart1 = childInterior;
      final Offset scaleStart2 = Offset(childInterior.dx + 20.0, childInterior.dy);
      final Offset scaleEnd1 = Offset(scaleStart1.dx + 5.0, scaleStart1.dy);
      final Offset scaleEnd2 = Offset(scaleStart2.dx - 5.0, scaleStart2.dy);
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
      // The new scale is the scale that makes the original size (200.0) as big
      // as the boundary (220.0).
      expect(transformationController.value.getMaxScaleOnAxis(), 200.0 / 220.0);
    });

    testWidgets('child bigger than viewport', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                constrained: false,
                scaleEnabled: false,
                rotateEnabled: false,
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
      final Offset childInterior = Offset(
        childOffset.dx + 20.0,
        childOffset.dy + 20.0,
      );
      TestGesture gesture = await tester.startGesture(childOffset);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(childInterior);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, equals(Matrix4.identity()));

      // Attempting to pinch to zoom doesn't work because it's disabled.
      final Offset scaleStart1 = childInterior;
      final Offset scaleStart2 = Offset(childInterior.dx + 10.0, childInterior.dy);
      final Offset scaleEnd1 = Offset(childInterior.dx - 10.0, childInterior.dy);
      final Offset scaleEnd2 = Offset(childInterior.dx + 20.0, childInterior.dy);
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
      final Offset rotateStart1 = childInterior;
      final Offset rotateStart2 = Offset(childInterior.dx + 10.0, childInterior.dy);
      final Offset rotateEnd1 = Offset(childInterior.dx + 5.0, childInterior.dy + 5.0);
      final Offset rotateEnd2 = Offset(childInterior.dx - 5.0, childInterior.dy - 5.0);
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
      gesture = await tester.startGesture(childInterior);
      await tester.pump();
      await gesture.moveTo(childOffset);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, isNot(equals(Matrix4.identity())));
    });

    testWidgets('no boundary', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      const double minScale = 0.8;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: minScale,
                transformationController: transformationController,
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      expect(transformationController.value, equals(Matrix4.identity()));

      // Drag to pan works because even though the viewport fits perfectly
      // around the child, there is no boundary.
      final Offset childOffset = tester.getTopLeft(find.byType(Container));
      final Offset childInterior = Offset(
        childOffset.dx + 20.0,
        childOffset.dy + 20.0,
      );
      TestGesture gesture = await tester.startGesture(childInterior);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(childOffset);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      final Vector3 translation = transformationController.value.getTranslation();
      expect(translation.x, childOffset.dx - childInterior.dx);
      expect(translation.y, childOffset.dy - childInterior.dy);

      // It's also possible to zoom out and view beyond the child because there
      // is no boundary.
      final Offset scaleStart1 = childInterior;
      final Offset scaleStart2 = Offset(childInterior.dx + 20.0, childInterior.dy);
      final Offset scaleEnd1 = Offset(childInterior.dx + 5.0, childInterior.dy);
      final Offset scaleEnd2 = Offset(childInterior.dx - 5.0, childInterior.dy);
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
      expect(transformationController.value.getMaxScaleOnAxis(), minScale);
    });

    testWidgets('alignPanAxis allows panning in one direction only for diagonal gesture', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                alignPanAxis: true,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                transformationController: transformationController,
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      expect(transformationController.value, equals(Matrix4.identity()));

      // Perform a diagonal drag gesture.
      final Offset childOffset = tester.getTopLeft(find.byType(Container));
      final Offset childInterior = Offset(
        childOffset.dx + 20.0,
        childOffset.dy + 20.0,
      );
      final TestGesture gesture = await tester.startGesture(childInterior);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(childOffset);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Translation has only happened along the y axis (the default axis when
      // a gesture is perfectly at 45 degrees to the axes).
      final Vector3 translation = transformationController.value.getTranslation();
      expect(translation.x, 0.0);
      expect(translation.y, childOffset.dy - childInterior.dy);
    });

    testWidgets('alignPanAxis allows panning in one direction only for horizontal leaning gesture', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                alignPanAxis: true,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                transformationController: transformationController,
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      expect(transformationController.value, equals(Matrix4.identity()));

      // Perform a horizontally leaning diagonal drag gesture.
      final Offset childOffset = tester.getTopLeft(find.byType(Container));
      final Offset childInterior = Offset(
        childOffset.dx + 20.0,
        childOffset.dy + 10.0,
      );
      final TestGesture gesture = await tester.startGesture(childInterior);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(childOffset);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Translation happened only along the x axis because that's the axis that
      // had the greatest movement.
      final Vector3 translation = transformationController.value.getTranslation();
      expect(translation.x, childOffset.dx - childInterior.dx);
      expect(translation.y, 0.0);
    });

    testWidgets('inertia fling and boundary sliding', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      const double boundaryMargin = 50.0;
      const double minScale = 0.8;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(boundaryMargin),
                minScale: minScale,
                transformationController: transformationController,
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      // Fling the child.
      final Offset childOffset = tester.getTopLeft(find.byType(Container));
      const Offset flingEnd = Offset(20.0, 15.0);
      await tester.flingFrom(childOffset, flingEnd, 1000.0);
      await tester.pump();

      // Immediately after the gesture, the child has moved to exactly follow
      // the gesture.
      Vector3 translation = transformationController.value.getTranslation();
      expect(translation.x, flingEnd.dx);
      expect(translation.y, flingEnd.dy);

      // A short time after the gesture was released, it continues to move with
      // inertia.
      await tester.pump(const Duration(milliseconds: 10));
      translation = transformationController.value.getTranslation();
      expect(translation.x, greaterThan(flingEnd.dx));
      expect(translation.y, greaterThan(flingEnd.dy));
      expect(translation.x, lessThan(boundaryMargin));
      expect(translation.y, lessThan(boundaryMargin));

      // It hits the boundary in the x direction first.
      await tester.pump(const Duration(milliseconds: 60));
      translation = transformationController.value.getTranslation();
      expect(translation.x, moreOrLessEquals(boundaryMargin, epsilon: 1e-9));
      expect(translation.y, lessThan(boundaryMargin));
      final double yWhenXHits = translation.y;

      // x is held to the boundary while y slides along.
      await tester.pump(const Duration(milliseconds: 40));
      translation = transformationController.value.getTranslation();
      expect(translation.x, moreOrLessEquals(boundaryMargin, epsilon: 1e-9));
      expect(translation.y, greaterThan(yWhenXHits));
      expect(translation.y, lessThan(boundaryMargin));

      // Eventually it ends up in the corner.
      await tester.pumpAndSettle();
      translation = transformationController.value.getTranslation();
      expect(translation.x, moreOrLessEquals(boundaryMargin, epsilon: 1e-9));
      expect(translation.y, moreOrLessEquals(boundaryMargin, epsilon: 1e-9));
    });

    testWidgets('inertia fling and boundary sliding with rotation', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      const double boundaryMargin = 50.0;
      const double minScale = 0.8;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(boundaryMargin),
                minScale: minScale,
                scaleEnabled: false,
                transformationController: transformationController,
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      // Pinch to rotate a bit.
      final Offset childOffset = tester.getTopLeft(find.byType(Container));
      final Offset childCenter = Offset(
        childOffset.dx + 100.0,
        childOffset.dy + 100.0,
      );
      const double radius = 20.0;
      final Offset rotateStart1 = Offset(childCenter.dx - radius, childCenter.dy);
      final Offset rotateStart2 = Offset(childCenter.dx + radius, childCenter.dy);
      final double value = radius * math.sin(math.pi / 4);
      final Offset rotateEnd1 = Offset(childCenter.dx - value, childCenter.dy - value);
      final Offset rotateEnd2 = Offset(childCenter.dx + value, childCenter.dy + value);
      final TestGesture gesture = await tester.createGesture();
      addTearDown(gesture.removePointer);
      final TestGesture gesture2 = await tester.createGesture();
      addTearDown(gesture2.removePointer);
      await gesture.down(rotateStart1);
      await gesture2.down(rotateStart2);
      await tester.pump();
      await gesture.moveTo(rotateEnd1);
      await gesture2.moveTo(rotateEnd2);
      await tester.pump();
      await gesture.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, isNot(equals(Matrix4.identity())));
      expect(transformationController.value.getMaxScaleOnAxis(), equals(1.0));
      final Matrix3 rotationMatrix = transformationController.value.getRotation();
      final double rotation = math.atan2(rotationMatrix.row1.x, rotationMatrix.row0.x);
      expect(rotation, moreOrLessEquals(math.pi / 8, epsilon: 1e-9));

      // Fling the child.
      const Offset flingEnd = Offset(20.0, 15.0);
      final Vector3 translationAfterRotate = transformationController.value.getTranslation();
      await tester.flingFrom(childOffset, flingEnd, 2000.0);
      await tester.pump();

      // Immediately after the gesture, the child has moved to exactly follow
      // the gesture.
      final Vector3 translationAtRelease = transformationController.value.getTranslation();
      expect(translationAtRelease.x, moreOrLessEquals(translationAfterRotate.x + flingEnd.dx));
      expect(translationAtRelease.y, moreOrLessEquals(translationAfterRotate.y + flingEnd.dy));

      // A short time after the gesture was released, it continues to move with
      // inertia, and hasn't hit the boundary yet.
      await tester.pump(const Duration(milliseconds: 10));
      final Vector3 translationAfterRelease = transformationController.value.getTranslation();
      expect(translationAfterRelease.x, greaterThan(translationAtRelease.x));
      expect(translationAfterRelease.y, greaterThan(translationAtRelease.y));

      // It hits the boundary in the y direction first. The y coordinate has
      // been increasing up to this point but will now start decreasing.
      await tester.pump(const Duration(milliseconds: 161));
      final Vector3 translationWhenYHitsBounds = transformationController.value.getTranslation();
      expect(translationWhenYHitsBounds.x, greaterThan(translationAfterRelease.x));
      expect(translationWhenYHitsBounds.y, greaterThan(translationAfterRelease.y));

      // x slides along while y is held to the boundary at the rotated angle,
      // which causes it to decrease.
      await tester.pump(const Duration(milliseconds: 40));
      final Vector3 translationSliding = transformationController.value.getTranslation();
      expect(translationSliding.x, greaterThan(translationWhenYHitsBounds.x));
      expect(translationSliding.y, lessThan(translationWhenYHitsBounds.y));

      // Eventually it stops.
      await tester.pump(const Duration(milliseconds: 40));
      final Vector3 translationEnd = transformationController.value.getTranslation();
      expect(translationEnd.x, greaterThan(translationSliding.x));
      expect(translationEnd.y, lessThan(translationSliding.y));
      await tester.pumpAndSettle();
      final Vector3 translationAfterEnd = transformationController.value.getTranslation();
      expect(translationAfterEnd.x, equals(translationEnd.x));
      expect(translationAfterEnd.y, equals(translationEnd.y));
    });

    testWidgets('Scaling automatically causes a centering translation', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      const double boundaryMargin = 50.0;
      const double minScale = 0.1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(boundaryMargin),
                minScale: minScale,
                transformationController: transformationController,
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      Vector3 translation = transformationController.value.getTranslation();
      expect(translation.x, 0.0);
      expect(translation.y, 0.0);

      // Pan into the corner of the boundaries.
      final Offset childOffset = tester.getTopLeft(find.byType(Container));
      const Offset flingEnd = Offset(20.0, 15.0);
      await tester.flingFrom(childOffset, flingEnd, 1000.0);
      await tester.pumpAndSettle();
      translation = transformationController.value.getTranslation();
      expect(translation.x, moreOrLessEquals(boundaryMargin, epsilon: 1e-9));
      expect(translation.y, moreOrLessEquals(boundaryMargin, epsilon: 1e-9));

      // Zoom out so the entire child is visible. The child will also be
      // translated in order to keep it inside the boundaries.
      final Offset childCenter = tester.getCenter(find.byType(Container));
      Offset scaleStart1 = Offset(childCenter.dx - 40.0, childCenter.dy);
      Offset scaleStart2 = Offset(childCenter.dx + 40.0, childCenter.dy);
      Offset scaleEnd1 = Offset(childCenter.dx - 10.0, childCenter.dy);
      Offset scaleEnd2 = Offset(childCenter.dx + 10.0, childCenter.dy);
      TestGesture gesture = await tester.createGesture();
      TestGesture gesture2 = await tester.createGesture();
      await gesture.down(scaleStart1);
      await gesture2.down(scaleStart2);
      await tester.pump();
      await gesture.moveTo(scaleEnd1);
      await gesture2.moveTo(scaleEnd2);
      await tester.pump();
      await gesture.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      expect(transformationController.value.getMaxScaleOnAxis(), lessThan(1.0));
      translation = transformationController.value.getTranslation();
      expect(translation.x, lessThan(boundaryMargin));
      expect(translation.y, lessThan(boundaryMargin));
      expect(translation.x, greaterThan(0.0));
      expect(translation.y, greaterThan(0.0));
      expect(translation.x, moreOrLessEquals(translation.y, epsilon: 1e-9));

      // Zoom in on a point that's not the center, and see that it remains at
      // roughly the same location in the viewport after the zoom.
      scaleStart1 = Offset(childCenter.dx - 50.0, childCenter.dy);
      scaleStart2 = Offset(childCenter.dx - 30.0, childCenter.dy);
      scaleEnd1 = Offset(childCenter.dx - 51.0, childCenter.dy);
      scaleEnd2 = Offset(childCenter.dx - 29.0, childCenter.dy);
      final Offset viewportFocalPoint = Offset(
        childCenter.dx - 40.0 - childOffset.dx,
        childCenter.dy - childOffset.dy,
      );
      final Offset sceneFocalPoint = transformationController.toScene(viewportFocalPoint);
      gesture = await tester.createGesture();
      gesture2 = await tester.createGesture();
      await gesture.down(scaleStart1);
      await gesture2.down(scaleStart2);
      await tester.pump();
      await gesture.moveTo(scaleEnd1);
      await gesture2.moveTo(scaleEnd2);
      await tester.pump();
      await gesture.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      final Offset newSceneFocalPoint = transformationController.toScene(viewportFocalPoint);
      expect(newSceneFocalPoint.dx, moreOrLessEquals(sceneFocalPoint.dx, epsilon: 1.0));
      expect(newSceneFocalPoint.dy, moreOrLessEquals(sceneFocalPoint.dy, epsilon: 1.0));
    });

    testWidgets('Scaling automatically causes a centering translation even when alignPanAxis is set', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      const double boundaryMargin = 50.0;
      const double minScale = 0.1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                alignPanAxis: true,
                boundaryMargin: const EdgeInsets.all(boundaryMargin),
                minScale: minScale,
                transformationController: transformationController,
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      Vector3 translation = transformationController.value.getTranslation();
      expect(translation.x, 0.0);
      expect(translation.y, 0.0);

      // Pan into the corner of the boundaries in two gestures, since
      // alignPanAxis prevents diagonal panning.
      final Offset childOffset1 = tester.getTopLeft(find.byType(Container));
      const Offset flingEnd1 = Offset(20.0, 0.0);
      await tester.flingFrom(childOffset1, flingEnd1, 1000.0);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      final Offset childOffset2 = tester.getTopLeft(find.byType(Container));
      const Offset flingEnd2 = Offset(0.0, 15.0);
      await tester.flingFrom(childOffset2, flingEnd2, 1000.0);
      await tester.pumpAndSettle();
      translation = transformationController.value.getTranslation();
      expect(translation.x, moreOrLessEquals(boundaryMargin, epsilon: 1e-9));
      expect(translation.y, moreOrLessEquals(boundaryMargin, epsilon: 1e-9));

      // Zoom out so the entire child is visible. The child will also be
      // translated in order to keep it inside the boundaries.
      final Offset childCenter = tester.getCenter(find.byType(Container));
      Offset scaleStart1 = Offset(childCenter.dx - 40.0, childCenter.dy);
      Offset scaleStart2 = Offset(childCenter.dx + 40.0, childCenter.dy);
      Offset scaleEnd1 = Offset(childCenter.dx - 10.0, childCenter.dy);
      Offset scaleEnd2 = Offset(childCenter.dx + 10.0, childCenter.dy);
      TestGesture gesture = await tester.createGesture();
      TestGesture gesture2 = await tester.createGesture();
      await gesture.down(scaleStart1);
      await gesture2.down(scaleStart2);
      await tester.pump();
      await gesture.moveTo(scaleEnd1);
      await gesture2.moveTo(scaleEnd2);
      await tester.pump();
      await gesture.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      expect(transformationController.value.getMaxScaleOnAxis(), lessThan(1.0));
      translation = transformationController.value.getTranslation();
      expect(translation.x, lessThan(boundaryMargin));
      expect(translation.y, lessThan(boundaryMargin));
      expect(translation.x, greaterThan(0.0));
      expect(translation.y, greaterThan(0.0));
      expect(translation.x, moreOrLessEquals(translation.y, epsilon: 1e-9));

      // Zoom in on a point that's not the center, and see that it remains at
      // roughly the same location in the viewport after the zoom.
      scaleStart1 = Offset(childCenter.dx - 50.0, childCenter.dy);
      scaleStart2 = Offset(childCenter.dx - 30.0, childCenter.dy);
      scaleEnd1 = Offset(childCenter.dx - 51.0, childCenter.dy);
      scaleEnd2 = Offset(childCenter.dx - 29.0, childCenter.dy);
      final Offset viewportFocalPoint = Offset(
        childCenter.dx - 40.0 - childOffset1.dx,
        childCenter.dy - childOffset1.dy,
      );
      final Offset sceneFocalPoint = transformationController.toScene(viewportFocalPoint);
      gesture = await tester.createGesture();
      gesture2 = await tester.createGesture();
      await gesture.down(scaleStart1);
      await gesture2.down(scaleStart2);
      await tester.pump();
      await gesture.moveTo(scaleEnd1);
      await gesture2.moveTo(scaleEnd2);
      await tester.pump();
      await gesture.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      final Offset newSceneFocalPoint = transformationController.toScene(viewportFocalPoint);
      expect(newSceneFocalPoint.dx, moreOrLessEquals(sceneFocalPoint.dx, epsilon: 1.0));
      expect(newSceneFocalPoint.dy, moreOrLessEquals(sceneFocalPoint.dy, epsilon: 1.0));
    });

    testWidgets('Can scale with mouse', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                transformationController: transformationController,
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      final Offset center = tester.getCenter(find.byType(InteractiveViewer));
      await scrollAt(center, tester, const Offset(0.0, -20.0));
      await tester.pumpAndSettle();

      expect(transformationController.value.getMaxScaleOnAxis(), greaterThan(1.0));
    });

    testWidgets('Cannot scale with mouse when scale is disabled', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                transformationController: transformationController,
                scaleEnabled: false,
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      final Offset center = tester.getCenter(find.byType(InteractiveViewer));
      await scrollAt(center, tester, const Offset(0.0, -20.0));
      await tester.pumpAndSettle();

      expect(transformationController.value.getMaxScaleOnAxis(), equals(1.0));
    });

    testWidgets('Scale with mouse returns onInteraction properties', (WidgetTester tester) async{
      final TransformationController transformationController = TransformationController();
      late final Offset focalPoint;
      late final Offset localFocalPoint;
      late final double scaleChange;
      late final Velocity currentVelocity;
      late final bool calledStart;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                transformationController: transformationController,
                onInteractionStart: (ScaleStartDetails details){
                  calledStart = true;
                },
                onInteractionUpdate: (ScaleUpdateDetails details){
                  scaleChange = details.scale;
                  focalPoint = details.focalPoint;
                  localFocalPoint = details.localFocalPoint;
                },
                onInteractionEnd: (ScaleEndDetails details){
                  currentVelocity = details.velocity;
                },
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      final Offset center = tester.getCenter(find.byType(InteractiveViewer));
      await scrollAt(center, tester, const Offset(0.0, -20.0));
      await tester.pumpAndSettle();
      const Velocity noMovement = Velocity.zero;
      final double afterScaling = transformationController.value.getMaxScaleOnAxis();

      expect(scaleChange, greaterThan(1.0));
      expect(afterScaling, scaleChange);
      expect(currentVelocity, equals(noMovement));
      expect(calledStart, equals(true));
      // Focal points are given in coordinates outside of InteractiveViewer,
      // with local being in relation to the viewport.
      expect(focalPoint, center);
      expect(localFocalPoint, const Offset(100, 100));

      // The scene point is the same as localFocalPoint because the center of
      // the scene is at the center of the viewport.
      final Offset scenePoint = transformationController.toScene(localFocalPoint);
      expect(scenePoint, const Offset(100, 100));
    });

     testWidgets('Scaling amount is equal forth and back with a mouse scroll', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
              body: Center(
            child: InteractiveViewer(
              constrained: false,
              maxScale: 100000,
              minScale: 0.01,
              transformationController: transformationController,
              child: Container(width: 1000.0, height: 1000.0),
            ),
          )),
        ),
      );

      final Offset center = tester.getCenter(find.byType(InteractiveViewer));
      await scrollAt(center, tester, const Offset(0.0, -200.0));
      await tester.pumpAndSettle();
      expect(transformationController.value.getMaxScaleOnAxis(), math.exp(200 / 200));
      await scrollAt(center, tester, const Offset(0.0, -200.0));
      await tester.pumpAndSettle();
      // math.exp round the number too short compared to the one in transformationController.
      expect(transformationController.value.getMaxScaleOnAxis(), closeTo(math.exp(400 / 200), 0.000000000000001));
      await scrollAt(center, tester, const Offset(0.0, 200.0));
      await scrollAt(center, tester, const Offset(0.0, 200.0));
      await tester.pumpAndSettle();
      expect(transformationController.value.getMaxScaleOnAxis(), 1.0);
    });

    testWidgets('onInteraction can be used to get scene point', (WidgetTester tester) async{
      final TransformationController transformationController = TransformationController();
      late final Offset focalPoint;
      late final Offset localFocalPoint;
      late final double scaleChange;
      late final Velocity currentVelocity;
      late final bool calledStart;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                transformationController: transformationController,
                onInteractionStart: (ScaleStartDetails details){
                  calledStart = true;
                },
                onInteractionUpdate: (ScaleUpdateDetails details){
                  scaleChange = details.scale;
                  focalPoint = details.focalPoint;
                  localFocalPoint = details.localFocalPoint;
                },
                onInteractionEnd: (ScaleEndDetails details){
                  currentVelocity = details.velocity;
                },
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      final Offset center = tester.getCenter(find.byType(InteractiveViewer));
      final Offset offCenter = Offset(center.dx - 20.0, center.dy - 20.0);
      await scrollAt(offCenter, tester, const Offset(0.0, -20.0));
      await tester.pumpAndSettle();
      const Velocity noMovement = Velocity.zero;
      final double afterScaling = transformationController.value.getMaxScaleOnAxis();

      expect(scaleChange, greaterThan(1.0));
      expect(afterScaling, scaleChange);
      expect(currentVelocity, equals(noMovement));
      expect(calledStart, equals(true));
      // Focal points are given in coordinates outside of InteractiveViewer,
      // with local being in relation to the viewport.
      expect(focalPoint, offCenter);
      expect(localFocalPoint, const Offset(80, 80));

      // The top left corner of the viewport is not at the top left corner of
      // the scene.
      final Offset scenePoint = transformationController.toScene(Offset.zero);
      expect(scenePoint.dx, greaterThan(0.0));
      expect(scenePoint.dy, greaterThan(0.0));
    });

    testWidgets('viewport changes size', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                transformationController: transformationController,
                child: Container(),
              ),
            ),
          ),
        ),
      );

      expect(transformationController.value, equals(Matrix4.identity()));

      // Attempting to drag to pan doesn't work because the child fits inside
      // the viewport and has a tight boundary.
      final Offset childOffset = tester.getTopLeft(find.byType(Container));
      final Offset childInterior = Offset(
        childOffset.dx + 20.0,
        childOffset.dy + 20.0,
      );
      TestGesture gesture = await tester.startGesture(childInterior);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(childOffset);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, equals(Matrix4.identity()));

      // Shrink the size of the screen.
      tester.binding.window.physicalSizeTestValue = const Size(100.0, 100.0);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      await tester.pump();

      // Attempting to drag to pan still doesn't work, because the image has
      // resized itself to fit the new screen size, and InteractiveViewer has
      // updated its measurements to take that into consideration.
      gesture = await tester.startGesture(childInterior);
      await tester.pump();
      await gesture.moveTo(childOffset);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, equals(Matrix4.identity()));
    });

    testWidgets('gesture can start as pan and become scale', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      const double boundaryMargin = 50.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(boundaryMargin),
                transformationController: transformationController,
                child: Container(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      Vector3 translation = transformationController.value.getTranslation();
      expect(translation.x, 0.0);
      expect(translation.y, 0.0);

      // Start a pan gesture.
      final Offset childCenter = tester.getCenter(find.byType(Container));
      final TestGesture gesture = await tester.createGesture();
      await gesture.down(childCenter);
      await tester.pump();
      await gesture.moveTo(Offset(
        childCenter.dx + 5.0,
        childCenter.dy + 5.0,
      ));
      await tester.pump();
      translation = transformationController.value.getTranslation();
      expect(translation.x, greaterThan(0.0));
      expect(translation.y, greaterThan(0.0));

      // Put another finger down and turn it into a scale gesture.
      final TestGesture gesture2 = await tester.createGesture();
      await gesture2.down(Offset(
        childCenter.dx - 5.0,
        childCenter.dy - 5.0,
      ));
      await tester.pump();
      await gesture.moveTo(Offset(
        childCenter.dx + 25.0,
        childCenter.dy + 25.0,
      ));
      await gesture2.moveTo(Offset(
        childCenter.dx - 25.0,
        childCenter.dy - 25.0,
      ));
      await tester.pump();
      await gesture.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      expect(transformationController.value.getMaxScaleOnAxis(), greaterThan(1.0));
    });

    // Regression test for https://github.com/flutter/flutter/issues/65304
    testWidgets('can view beyond boundary when necessary for a small child', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                constrained: false,
                minScale: 1.0,
                maxScale: 1.0,
                transformationController: transformationController,
                child: const SizedBox(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      expect(transformationController.value, equals(Matrix4.identity()));

      // Pinch to zoom does nothing because minScale and maxScale are 1.0.
      final Offset center = tester.getCenter(find.byType(SizedBox));
      final Offset scaleStart1 = Offset(center.dx - 10.0, center.dy - 10.0);
      final Offset scaleStart2 = Offset(center.dx + 10.0, center.dy + 10.0);
      final Offset scaleEnd1 = Offset(center.dx - 20.0, center.dy - 20.0);
      final Offset scaleEnd2 = Offset(center.dx + 20.0, center.dy + 20.0);
      final TestGesture gesture = await tester.createGesture();
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
      expect(transformationController.value, equals(Matrix4.identity()));
    });

    testWidgets('scale does not jump when wrapped in GestureDetector', (WidgetTester tester) async {
      final TransformationController transformationController = TransformationController();
      double? initialScale;
      double? scale;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GestureDetector(
                onTapUp: (TapUpDetails details) {},
                child: InteractiveViewer(
                  onInteractionUpdate: (ScaleUpdateDetails details) {
                    initialScale ??= details.scale;
                    scale = details.scale;
                  },
                  transformationController: transformationController,
                  child: Container(width: 200.0, height: 200.0),
                ),
              ),
            ),
          ),
        ),
      );

      expect(transformationController.value, equals(Matrix4.identity()));
      expect(initialScale, null);
      expect(scale, null);

      // Pinch to zoom isn't immediately detected for a small amount of
      // movement due to the GestureDetector.
      final Offset childOffset = tester.getTopLeft(find.byType(Container));
      final Offset childInterior = Offset(
        childOffset.dx + 20.0,
        childOffset.dy + 20.0,
      );
      final Offset scaleStart1 = childInterior;
      final Offset scaleStart2 = Offset(childInterior.dx + 10.0, childInterior.dy);
      Offset scaleEnd1 = Offset(childInterior.dx - 10.0, childInterior.dy);
      Offset scaleEnd2 = Offset(childInterior.dx + 20.0, childInterior.dy);
      TestGesture gesture = await tester.createGesture();
      TestGesture gesture2 = await tester.createGesture();
      addTearDown(gesture.removePointer);
      addTearDown(gesture2.removePointer);
      await gesture.down(scaleStart1);
      await gesture2.down(scaleStart2);
      await tester.pump();
      await gesture.moveTo(scaleEnd1);
      await gesture2.moveTo(scaleEnd2);
      await tester.pump();
      await gesture.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      expect(transformationController.value, equals(Matrix4.identity()));
      expect(initialScale, null);
      expect(scale, null);

      // Pinch to zoom for a larger amount is detected. It starts smoothly at
      // 1.0 despite the fact that the gesture has already moved a bit.
      scaleEnd1 = Offset(childInterior.dx - 38.0, childInterior.dy);
      scaleEnd2 = Offset(childInterior.dx + 48.0, childInterior.dy);
      gesture = await tester.createGesture();
      gesture2 = await tester.createGesture();
      addTearDown(gesture.removePointer);
      addTearDown(gesture2.removePointer);
      await gesture.down(scaleStart1);
      await gesture2.down(scaleStart2);
      await tester.pump();
      await gesture.moveTo(scaleEnd1);
      await gesture2.moveTo(scaleEnd2);
      await tester.pump();
      await gesture.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      expect(initialScale, 1.0);
      expect(scale, greaterThan(1.0));
      expect(transformationController.value.getMaxScaleOnAxis(), greaterThan(1.0));
    });

    testWidgets('Check if ClipRect is present in the tree', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                constrained: false,
                clipBehavior: Clip.none,
                minScale: 1.0,
                maxScale: 1.0,
                child: const SizedBox(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byType(ClipRect),
        findsNothing,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveViewer(
                constrained: false,
                minScale: 1.0,
                maxScale: 1.0,
                child: const SizedBox(width: 200.0, height: 200.0),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byType(ClipRect),
        findsOneWidget,
      );
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

      expect(InteractiveViewer.pointIsInside(point, quad), true);
    });

    test('outside', () {
      final Quad quad = Quad.points(
        Vector3(0.0, 0.0, 0.0),
        Vector3(0.0, 10.0, 0.0),
        Vector3(10.0, 10.0, 0.0),
        Vector3(10.0, 0.0, 0.0),
      );
      final Vector3 point = Vector3(12.0, 0.0, 0.0);

      expect(InteractiveViewer.pointIsInside(point, quad), false);
    });

    test('on the edge', () {
      final Quad quad = Quad.points(
        Vector3(0.0, 0.0, 0.0),
        Vector3(0.0, 10.0, 0.0),
        Vector3(10.0, 10.0, 0.0),
        Vector3(10.0, 0.0, 0.0),
      );
      final Vector3 point = Vector3(0.0, 0.0, 0.0);

      expect(InteractiveViewer.pointIsInside(point, quad), true);
    });
  });

  group('LineSegment', () {
    group('contains', () {
      test('vertical line', () {
        const LineSegment lineSegment = LineSegment(
          Offset(0.0, 0.0),
          Offset(0.0, 100.0),
        );

        expect(lineSegment.contains(const Offset(0.0, 0.0)), isTrue);
        expect(lineSegment.contains(const Offset(0.0, 100.0)), isTrue);
        expect(lineSegment.contains(const Offset(1.0, 0.0)), isFalse);
        expect(lineSegment.contains(const Offset(0.0, -1.0)), isFalse);
        expect(lineSegment.contains(const Offset(0.0, 101.0)), isFalse);
        expect(lineSegment.contains(const Offset(0.0, 50.0)), isTrue);
      });

      test('horizontal line', () {
        const LineSegment lineSegment = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 0.0),
        );

        expect(lineSegment.contains(const Offset(0.0, 0.0)), isTrue);
        expect(lineSegment.contains(const Offset(100.0, 0.0)), isTrue);
        expect(lineSegment.contains(const Offset(-1.0, 0.0)), isFalse);
        expect(lineSegment.contains(const Offset(0.0, -1.0)), isFalse);
        expect(lineSegment.contains(const Offset(1.0, 0.0)), isTrue);
        expect(lineSegment.contains(const Offset(101.0, 0.0)), isFalse);
        expect(lineSegment.contains(const Offset(50.0, 0.0)), isTrue);
      });

      test('sloped line', () {
        const LineSegment lineSegment = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );

        expect(lineSegment.contains(const Offset(0.0, 0.0)), isTrue);
        expect(lineSegment.contains(const Offset(100.0, 100.0)), isTrue);
        expect(lineSegment.contains(const Offset(-1.0, 0.0)), isFalse);
        expect(lineSegment.contains(const Offset(0.0, -1.0)), isFalse);
        expect(lineSegment.contains(const Offset(1.0, 1.0)), isTrue);
        expect(lineSegment.contains(const Offset(101.0, 0.0)), isFalse);
        expect(lineSegment.contains(const Offset(50.0, 50.0)), isTrue);
      });
    });

    group('intersects', () {
      test('same slopes not overlapping', () {
        const LineSegment a = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );
        const LineSegment b = LineSegment(
          Offset(101.0, 101.0),
          Offset(201.0, 201.0),
        );
        expect(a.intersects(b), isFalse);
      });

      test('same slopes overlapping', () {
        const LineSegment a = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );
        const LineSegment b = LineSegment(
          Offset(100.0, 100.0),
          Offset(200.0, 200.0),
        );
        expect(a.intersects(b), isTrue);
      });

      test('different slopes not intersecting', () {
        const LineSegment a = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );
        const LineSegment b = LineSegment(
          Offset(0.0, 100.0),
          Offset(49.0, 51.0),
        );
        expect(a.intersects(b), isFalse);
      });

      test('different slopes intersecting', () {
        const LineSegment a = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );
        const LineSegment b = LineSegment(
          Offset(0.0, 100.0),
          Offset(100.0, 0.0),
        );
        expect(a.intersects(b), isTrue);
      });

      test('one is vertical and they intersect', () {
        const LineSegment a = LineSegment(
          Offset(50.0, 0.0),
          Offset(50.0, 100.0),
        );
        const LineSegment b = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );
        expect(a.intersects(b), isTrue);
        expect(b.intersects(a), isTrue);
      });

      test('one is vertical and they do not intersect', () {
        const LineSegment a = LineSegment(
          Offset(101.0, 0.0),
          Offset(101.0, 100.0),
        );
        const LineSegment b = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );
        expect(a.intersects(b), isFalse);
        expect(b.intersects(a), isFalse);
      });

      test('one is horizontal and they intersect', () {
        const LineSegment a = LineSegment(
          Offset(0.0, 50.0),
          Offset(100.0, 50.0),
        );
        const LineSegment b = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );
        expect(a.intersects(b), isTrue);
        expect(b.intersects(a), isTrue);
      });

      test('one is horizontal and they do not intersect', () {
        const LineSegment a = LineSegment(
          Offset(0.0, 101.0),
          Offset(100.0, 101.0),
        );
        const LineSegment b = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );
        expect(a.intersects(b), isFalse);
        expect(b.intersects(a), isFalse);
      });

      test('one is vertical and one is horizontal and they intersect', () {
        const LineSegment a = LineSegment(
          Offset(50.0, 0.0),
          Offset(50.0, 100.0),
        );
        const LineSegment b = LineSegment(
          Offset(0.0, 50.0),
          Offset(100.0, 50.0),
        );
        expect(a.intersects(b), isTrue);
        expect(b.intersects(a), isTrue);
      });

      test('one is vertical and one is horizontal and they do not intersect', () {
        const LineSegment a = LineSegment(
          Offset(101.0, 0.0),
          Offset(101.0, 100.0),
        );
        const LineSegment b = LineSegment(
          Offset(0.0, 50.0),
          Offset(100.0, 50.0),
        );
        expect(a.intersects(b), isFalse);
        expect(b.intersects(a), isFalse);
      });
    });

    group('findClosestToOffset', () {
      test('vertical line', () {
        const LineSegment lineSegment = LineSegment(
          Offset(0.0, 0.0),
          Offset(0.0, 100.0),
        );

        expect(
          lineSegment.findClosestToOffset(const Offset(0.0, -10.0)),
          const Offset(0.0, 0.0),
        );
        expect(
          lineSegment.findClosestToOffset(const Offset(0.0, 110.0)),
          const Offset(0.0, 100.0),
        );
        expect(
          lineSegment.findClosestToOffset(const Offset(0.0, 50.0)),
          const Offset(0.0, 50.0),
        );
        expect(
          lineSegment.findClosestToOffset(const Offset(50.0, 50.0)),
          const Offset(0.0, 50.0),
        );
      });

      test('horizontal line', () {
        const LineSegment lineSegment = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 0.0),
        );

        expect(
          lineSegment.findClosestToOffset(const Offset(-10.0, 0.0)),
          const Offset(0.0, 0.0),
        );
        expect(
          lineSegment.findClosestToOffset(const Offset(110.0, 0.0)),
          const Offset(100.0, 0.0),
        );
        expect(
          lineSegment.findClosestToOffset(const Offset(50.0, 0.0)),
          const Offset(50.0, 0.0),
        );
        expect(
          lineSegment.findClosestToOffset(const Offset(50.0, 50.0)),
          const Offset(50.0, 0.0),
        );
      });

      test('sloped line', () {
        const LineSegment lineSegment = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );

        expect(
          lineSegment.findClosestToOffset(const Offset(0.0, -10.0)),
          const Offset(0.0, 0.0),
        );
        expect(
          lineSegment.findClosestToOffset(const Offset(-10.0, -10.0)),
          const Offset(0.0, 0.0),
        );
        expect(
          lineSegment.findClosestToOffset(const Offset(0.0, 100.0)),
          const Offset(50.0, 50.0),
        );
        expect(
          lineSegment.findClosestToOffset(const Offset(110.0, 110.0)),
          const Offset(100.0, 100.0),
        );
        expect(
          lineSegment.findClosestToOffset(const Offset(50.0, 50.0)),
          const Offset(50.0, 50.0),
        );
        expect(
          lineSegment.findClosestToOffset(const Offset(0.0, 50.0)),
          const Offset(25.0, 25.0),
        );
      });

      test('real example', () {
        const Offset offset = Offset(-436.9, 433.6);
        const LineSegment lineSegment = LineSegment(
          Offset(-1114.0, -60.3),
          Offset(288.8, 432.7),
        );

        final Offset closest = lineSegment.findClosestToOffset(offset);
        expect(closest.dx, moreOrLessEquals(-356.8, epsilon: 0.1));
        expect(closest.dy, moreOrLessEquals(205.8, epsilon: 0.1));
      });
    });

    group('findClosestOffsetOnLineSegmentToPointOnLine', () {
      test('at an angle', () {
        const LineSegment lineSegment = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );

        expect(
          lineSegment.findClosestOffsetOnLineSegmentToOffsetOnLine(const Offset(0.0, 0.0)),
          const Offset(0.0, 0.0),
        );
        expect(
          lineSegment.findClosestOffsetOnLineSegmentToOffsetOnLine(const Offset(10.0, 10.0)),
          const Offset(10.0, 10.0),
        );
        expect(
          lineSegment.findClosestOffsetOnLineSegmentToOffsetOnLine(const Offset(110.0, 110.0)),
          const Offset(100.0, 100.0),
        );
      });

      test('horizontal', () {
        const LineSegment lineSegment = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 0.0),
        );

        expect(
          lineSegment.findClosestOffsetOnLineSegmentToOffsetOnLine(const Offset(0.0, 0.0)),
          const Offset(0.0, 0.0),
        );
        expect(
          lineSegment.findClosestOffsetOnLineSegmentToOffsetOnLine(const Offset(-10.0, 0.0)),
          const Offset(0.0, 0.0),
        );
        expect(
          lineSegment.findClosestOffsetOnLineSegmentToOffsetOnLine(const Offset(110.0, 0.0)),
          const Offset(100.0, 0.0),
        );
      });

      test('vertical', () {
        const LineSegment lineSegment = LineSegment(
          Offset(0.0, 0.0),
          Offset(0.0, 100.0),
        );

        expect(
          lineSegment.findClosestOffsetOnLineSegmentToOffsetOnLine(const Offset(0.0, 0.0)),
          const Offset(0.0, 0.0),
        );
        expect(
          lineSegment.findClosestOffsetOnLineSegmentToOffsetOnLine(const Offset(0.0, -10.0)),
          const Offset(0.0, 0.0),
        );
        expect(
          lineSegment.findClosestOffsetOnLineSegmentToOffsetOnLine(const Offset(0.0, 110.0)),
          const Offset(0.0, 100.0),
        );
      });
    });

    group('findClosestPointsLineSegment', () {
      test('vertical and horizontal', () {
        const LineSegment a = LineSegment(
          Offset(0.0, 0.0),
          Offset(0.0, 100.0),
        );
        const LineSegment b = LineSegment(
          Offset(10.0, 0.0),
          Offset(110.0, 0.0),
        );

        final ClosestPoints pair = a.findClosestPointsLineSegment(b);
        expect(pair.a, const Offset(0.0, 0.0));
        expect(pair.b, const Offset(10.0, 0.0));
      });

      test('intersecting', () {
        const LineSegment a = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );
        const LineSegment b = LineSegment(
          Offset(100.0, 0.0),
          Offset(0.0, 100.0),
        );

        final ClosestPoints pair = a.findClosestPointsLineSegment(b);
        expect(pair.a, const Offset(50.0, 50.0));
        expect(pair.b, const Offset(50.0, 50.0));
      });

      test('parallel', () {
        const LineSegment a = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );
        const LineSegment b = LineSegment(
          Offset(10.0, 0.0),
          Offset(110.0, 100.0),
        );

        final ClosestPoints pair = a.findClosestPointsLineSegment(b);
        expect(pair.a, const Offset(0.0, 0.0));
        expect(pair.b, const Offset(10.0, 0.0));
      });

      test('at angles', () {
        const LineSegment a = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 100.0),
        );
        const LineSegment b = LineSegment(
          Offset(120.0, 0.0),
          Offset(100.0, 200.0),
        );

        final ClosestPoints pair = a.findClosestPointsLineSegment(b);
        expect(pair.a, const Offset(100.0, 100.0));
        expect(pair.b.dx, moreOrLessEquals(109.9, epsilon: 0.1));
        expect(pair.b.dy, moreOrLessEquals(101.0, epsilon: 0.1));
      });

      test("intersection isn't closest point", () {
        const LineSegment a = LineSegment(
          Offset(0.0, 0.0),
          Offset(100.0, 0.0),
        );
        const LineSegment b = LineSegment(
          Offset(90.0, 90.0),
          Offset(100.0, 100.0),
        );

        final ClosestPoints pair = a.findClosestPointsLineSegment(b);
        expect(pair.a, const Offset(90.0, 0.0));
        expect(pair.b, const Offset(90.0, 90.0));
      });

      test('real vertical example', () {
        const LineSegment a = LineSegment(
          Offset(307.0, 157.1),
          Offset(307.0, 90.2),
        );
        const LineSegment b = LineSegment(
          Offset(300.0, 0.0),
          Offset(300.0, 300.0),
        );

        final ClosestPoints pair = a.findClosestPointsLineSegment(b);
        expect(pair.a, const Offset(307.0, 157.1));
        expect(pair.b, const Offset(300.0, 157.1));
      });
    });

    group('findClosestPointsRect', () {
      test('vertical and horizontal', () {
        const LineSegment vertical = LineSegment(
          Offset(310.0, 0.0),
          Offset(310.0, 100.0),
        );
        const LineSegment horizontal = LineSegment(
          Offset(0.0, 310.0),
          Offset(100.0, 310.0),
        );
        const Rect rect = Rect.fromLTWH(0.0, 0.0, 300.0, 300.0);

        final ClosestPoints closestPointsVertical = vertical.findClosestPointsRect(rect);
        expect(closestPointsVertical.a, const Offset(310.0, 0.0));
        expect(closestPointsVertical.b, const Offset(300.0, 0.0));

        final ClosestPoints closestPointsHorizontal = horizontal.findClosestPointsRect(rect);
        expect(closestPointsHorizontal.a, const Offset(0.0, 310.0));
        expect(closestPointsHorizontal.b, const Offset(0.0, 300.0));
      });

      test('at an angle, middle of line segment nearset to a corner', () {
        const LineSegment a = LineSegment(
          Offset(-30.0, 280.0),
          Offset(10.0, 320.0),
        );
        const Rect rect = Rect.fromLTWH(0.0, 0.0, 300.0, 300.0);

        final ClosestPoints closestPoints = a.findClosestPointsRect(rect);
        expect(closestPoints.a, const Offset(-5.0, 305.0));
        expect(closestPoints.b, const Offset(0.0, 300.0));
      });

      test('horizontal, real example', () {
        const LineSegment a = LineSegment(
          Offset(306.7, 26.0),
          Offset(497.1, 26.0),
        );
        const Rect rect = Rect.fromLTWH(0.0, 0.0, 300.0, 300.0);

        final ClosestPoints closestPoints = a.findClosestPointsRect(rect);
        expect(closestPoints.a, const Offset(306.7, 26.0));
        expect(closestPoints.b, const Offset(300.0, 26.0));
      });
    });

    group('intersectsRect', () {
      test('contained in rect', () {
        const LineSegment lineSegment = LineSegment(
          Offset(25.0, 25.0),
          Offset(75.0, 75.0),
        );
        const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);

        expect(lineSegment.intersectsRect(rect), isTrue);
      });

      test('just touches rect', () {
        const LineSegment lineSegment = LineSegment(
          Offset(50.0, 100.0),
          Offset(150.0, 100.0),
        );
        const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);

        expect(lineSegment.intersectsRect(rect), isTrue);
      });

      test('just touches rect, real example horizontal', () {
        const LineSegment lineSegment = LineSegment(
          Offset(-18.7, 300.0),
          Offset(281.3, 300.0),
        );
        const Rect rect = Rect.fromLTWH(0.0, 0.0, 300.0, 300.0);

        expect(lineSegment.intersectsRect(rect), isTrue);
      });

      test('just touches rect, real example vertical', () {
        const LineSegment lineSegment = LineSegment(
          Offset(300.0, 84.7),
          Offset(300.0, 165.8),
        );
        const Rect rect = Rect.fromLTWH(0.0, 0.0, 300.0, 300.0);

        expect(lineSegment.intersectsRect(rect), isTrue);
      });

      test('just touches rect, tolerance', () {
        const LineSegment lineSegment = LineSegment(
          Offset(300.00000000000006, 84.7),
          Offset(300.00000000000006, 165.8),
        );
        const Rect rect = Rect.fromLTWH(0.0, 0.0, 300.0, 300.0);

        expect(lineSegment.intersectsRect(rect), isTrue);
      });
    });

    group('linesIntersectAt', () {
      test('returns null for line segments with Infinity and -Infinity slopes', () {
        const LineSegment a = LineSegment(
          Offset(307.0, 157.1),
          Offset(307.0, 90.2),
        );
        const LineSegment b = LineSegment(
          Offset(300.0, 0.0),
          Offset(300.0, 300.0),
        );

        final Offset? lineIntersection = a.linesIntersectAt(b);
        expect(lineIntersection, null);
      });
    });
  });
}
