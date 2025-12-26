// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import '../common/test_initialization.dart';

// Tests for `RSuperellipse.contains` are placed in the canvaskit folder instead
// of the engine folder because `RSuperellipse.contains` is implemented with
// paths, which needs a renderer.
//
// Some of the numbers slightly deviate from round_superellipse_unittests
// because it uses Bezier path approximation.

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('RSuperellipse.contains', () {
    setUpUnitTests();

    tearDown(() {
      renderer.debugClear();
    });

    test('RSuperellipse.contains is correct with no corners', () {
      // RSuperellipse of bounds with no corners contains corners just barely.
      const RSuperellipse rse = RSuperellipse.fromLTRBXY(-50, -50, 50, 50, 0, 0);

      expect(rse.contains(const Offset(-50, -50)), isTrue);
      // Rectangles have half-in, half-out containment so we need
      // to be careful about testing containment of right/bottom corners.
      expect(rse.contains(const Offset(-50, 49.99)), isTrue);
      expect(rse.contains(const Offset(49.99, -50)), isTrue);
      expect(rse.contains(const Offset(49.99, 49.99)), isTrue);
      expect(rse.contains(const Offset(-50.01, -50)), isFalse);
      expect(rse.contains(const Offset(-50, -50.01)), isFalse);
      expect(rse.contains(const Offset(-50.01, 50)), isFalse);
      expect(rse.contains(const Offset(-50, 50.01)), isFalse);
      expect(rse.contains(const Offset(50.01, -50)), isFalse);
      expect(rse.contains(const Offset(50, -50.01)), isFalse);
      expect(rse.contains(const Offset(50.01, 50)), isFalse);
      expect(rse.contains(const Offset(50, 50.01)), isFalse);
    });

    test('RSuperellipse.contains is correct with tiny corners', () {
      // RSuperellipse of bounds with even the tiniest corners does not contain corners.
      const RSuperellipse rse = RSuperellipse.fromLTRBXY(-50, -50, 50, 50, 0.01, 0.01);

      expect(rse.contains(const Offset(-50, -50)), isFalse);
      expect(rse.contains(const Offset(-50, 50)), isFalse);
      expect(rse.contains(const Offset(50, -50)), isFalse);
      expect(rse.contains(const Offset(50, 50)), isFalse);
    });

    test('RSuperellipse.contains is correct with uniform corners', () {
      const RSuperellipse rse = RSuperellipse.fromLTRBXY(-50, -50, 50, 50, 5.0, 5.0);

      void checkPointAndMirrors(Offset p) {
        checkPointWithOffset(rse, Offset(p.dx, p.dy), const Offset(0.02, 0.02));
        checkPointWithOffset(rse, Offset(p.dx, -p.dy), const Offset(0.02, -0.02));
        checkPointWithOffset(rse, Offset(-p.dx, p.dy), const Offset(-0.02, 0.02));
        checkPointWithOffset(rse, Offset(-p.dx, -p.dy), const Offset(-0.02, -0.02));
      }

      checkPointAndMirrors(const Offset(0, 49.995)); // Top
      checkPointAndMirrors(const Offset(44.15, 49.95)); // Top curve start
      checkPointAndMirrors(const Offset(45.72, 49.87)); // Top joint
      checkPointAndMirrors(const Offset(48.53, 48.53)); // Circular arc mid
      checkPointAndMirrors(const Offset(49.87, 45.72)); // Right joint
      checkPointAndMirrors(const Offset(49.95, 44.15)); // Right curve start
      checkPointAndMirrors(const Offset(49.995, 0)); // Right
    });

    test('RSuperellipse.contains is correct with uniform elliptical corners', () {
      const RSuperellipse rse = RSuperellipse.fromLTRBXY(-50, -50, 50, 50, 5.0, 10.0);

      void checkPointAndMirrors(Offset p) {
        checkPointWithOffset(rse, Offset(p.dx, p.dy), const Offset(0.02, 0.02));
        checkPointWithOffset(rse, Offset(p.dx, -p.dy), const Offset(0.02, -0.02));
        checkPointWithOffset(rse, Offset(-p.dx, p.dy), const Offset(-0.02, 0.02));
        checkPointWithOffset(rse, Offset(-p.dx, -p.dy), const Offset(-0.02, -0.02));
      }

      checkPointAndMirrors(const Offset(0, 49.995)); // Top
      checkPointAndMirrors(const Offset(43.90, 49.911)); // Top curve start
      checkPointAndMirrors(const Offset(45.69, 49.75)); // Top joint
      checkPointAndMirrors(const Offset(48.51, 47.07)); // Circular arc mid
      checkPointAndMirrors(const Offset(49.87, 41.44)); // Right joint
      checkPointAndMirrors(const Offset(49.95, 38.49)); // Right curve start
      checkPointAndMirrors(const Offset(49.995, 0)); // Right
    });

    test('RSuperellipse.contains is correct with uniform corners and unequal height and width', () {
      // The bounds is not centered at the origin and has unequal height and width.
      const RSuperellipse rse = RSuperellipse.fromLTRBXY(0, 0, 50, 100, 23.0, 30.0);

      final Offset center = rse.outerRect.center;
      void checkPointAndMirrors(Offset globalPoint) {
        final Offset p = globalPoint - center;
        checkPointWithOffset(rse, Offset(p.dx, p.dy) + center, const Offset(0.02, 0.02));
        checkPointWithOffset(rse, Offset(p.dx, -p.dy) + center, const Offset(0.02, -0.02));
        checkPointWithOffset(rse, Offset(-p.dx, p.dy) + center, const Offset(-0.02, 0.02));
        checkPointWithOffset(rse, Offset(-p.dx, -p.dy) + center, const Offset(-0.02, -0.02));
      }

      checkPointAndMirrors(const Offset(24.99, 99.99)); // Bottom mid-edge
      checkPointAndMirrors(const Offset(29.99, 99.64));
      checkPointAndMirrors(const Offset(34.99, 98.06));
      checkPointAndMirrors(const Offset(39.99, 94.73));
      checkPointAndMirrors(const Offset(44.13, 89.99));
      checkPointAndMirrors(const Offset(48.46, 79.99));
      checkPointAndMirrors(const Offset(49.68, 69.99));
      checkPointAndMirrors(const Offset(49.97, 59.99));
      checkPointAndMirrors(const Offset(49.99, 49.99)); // Right mid-edge
    });

    test('RSuperellipse.contains is correct for a slim diagonal shape', () {
      // This shape has large radii on one diagonal and tiny radii on the other,
      // resulting in a almond-like shape placed diagonally (NW to SE).
      final RSuperellipse rse = RSuperellipse.fromLTRBAndCorners(
        -50,
        -50,
        50,
        50,
        topLeft: const Radius.circular(1.0),
        topRight: const Radius.circular(99.0),
        bottomLeft: const Radius.circular(99.0),
        bottomRight: const Radius.circular(1.0),
      );

      expect(rse.contains(Offset.zero), isTrue);
      expect(rse.contains(const Offset(-49.999, -49.999)), isFalse);
      expect(rse.contains(const Offset(-49.999, 49.999)), isFalse);
      expect(rse.contains(const Offset(49.999, 49.999)), isFalse);
      expect(rse.contains(const Offset(49.999, -49.999)), isFalse);

      // The pointy ends at the NE and SW corners
      checkPointWithOffset(rse, const Offset(-49.70, -49.70), const Offset(-0.02, -0.02));
      checkPointWithOffset(rse, const Offset(49.70, 49.70), const Offset(0.02, 0.02));

      // Checks two points symmetrical to the origin.
      void checkDiagonalPoints(Offset p) {
        checkPointWithOffset(rse, p, const Offset(0.02, -0.02));
        checkPointWithOffset(rse, Offset(-p.dx, -p.dy), const Offset(-0.02, 0.02));
      }

      // A few other points along the edge
      checkDiagonalPoints(const Offset(-40.0, -49.59));
      checkDiagonalPoints(const Offset(-20.0, -45.64));
      checkDiagonalPoints(const Offset(0.0, -37.01));
      checkDiagonalPoints(const Offset(20.0, -21.96));
      checkDiagonalPoints(const Offset(21.05, -20.92));
      checkDiagonalPoints(const Offset(40.0, 5.68));
    });
  });
}

void checkPointWithOffset(RSuperellipse rse, Offset inPoint, Offset outwardOffset) {
  expect(rse.contains(inPoint), isTrue);
  expect(rse.contains(inPoint + outwardOffset), isFalse);
}
