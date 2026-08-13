// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show pi;
import 'dart:typed_data' show Float64List;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart';

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();
  test('path getBounds', () {
    const r = Rect.fromLTRB(1.0, 3.0, 5.0, 7.0);
    final p = Path()..addRect(r);
    expect(p.getBounds(), equals(r));
    p.lineTo(20.0, 15.0);
    expect(p.getBounds(), equals(const Rect.fromLTRB(1.0, 3.0, 20.0, 15.0)));
  });

  test('path combine rect', () {
    final c1 = Rect.fromCircle(center: const Offset(10.0, 10.0), radius: 10.0);
    final c2 = Rect.fromCircle(center: const Offset(5.0, 5.0), radius: 10.0);
    final Rect c1UnionC2 = c1.expandToInclude(c2);
    final Rect c1IntersectC2 = c1.intersect(c2);
    final pathCircle1 = Path()..addRect(c1);
    final pathCircle2 = Path()..addRect(c2);

    final Path difference = Path.combine(PathOperation.difference, pathCircle1, pathCircle2);
    expect(difference.getBounds(), equals(c1));

    final Path reverseDifference = Path.combine(
      PathOperation.reverseDifference,
      pathCircle1,
      pathCircle2,
    );
    expect(reverseDifference.getBounds(), equals(c2));

    final Path union = Path.combine(PathOperation.union, pathCircle1, pathCircle2);
    expect(union.getBounds(), equals(c1UnionC2));

    final Path intersect = Path.combine(PathOperation.intersect, pathCircle1, pathCircle2);
    expect(intersect.getBounds(), equals(c1IntersectC2));

    // the bounds on this will be the same as union - but would draw a missing inside piece.
    final Path xor = Path.combine(PathOperation.xor, pathCircle1, pathCircle2);
    expect(xor.getBounds(), equals(c1UnionC2));
  });

  test('path combine oval', () {
    final c1 = Rect.fromCircle(center: const Offset(10.0, 10.0), radius: 10.0);
    final c2 = Rect.fromCircle(center: const Offset(5.0, 5.0), radius: 10.0);
    final Rect c1UnionC2 = c1.expandToInclude(c2);
    final Rect c1IntersectC2 = c1.intersect(c2);
    final pathCircle1 = Path()..addOval(c1);
    final pathCircle2 = Path()..addOval(c2);

    final Path difference = Path.combine(PathOperation.difference, pathCircle1, pathCircle2);

    expect(difference.getBounds().top, closeTo(0.88, 0.01));

    final Path reverseDifference = Path.combine(
      PathOperation.reverseDifference,
      pathCircle1,
      pathCircle2,
    );
    expect(reverseDifference.getBounds().right, closeTo(14.11, 0.01));

    final Path union = Path.combine(PathOperation.union, pathCircle1, pathCircle2);
    expect(union.getBounds(), equals(c1UnionC2));

    final Path intersect = Path.combine(PathOperation.intersect, pathCircle1, pathCircle2);
    expect(intersect.getBounds(), equals(c1IntersectC2));

    // the bounds on this will be the same as union - but would draw a missing inside piece.
    final Path xor = Path.combine(PathOperation.xor, pathCircle1, pathCircle2);
    expect(xor.getBounds(), equals(c1UnionC2));
  });

  test('path clone', () {
    final p1 = Path()..lineTo(20.0, 20.0);
    final p2 = Path.from(p1);

    expect(p1.getBounds(), equals(p2.getBounds()));

    p1.lineTo(10.0, 30.0);
    expect(p1.getBounds().bottom, equals(p2.getBounds().bottom + 10));
  });

  test('shift tests', () {
    const bounds = Rect.fromLTRB(0.0, 0.0, 10.0, 10.0);
    final p = Path()..addRect(bounds);
    expect(p.getBounds(), equals(bounds));
    final Path shifted = p.shift(const Offset(10, 10));
    expect(shifted.getBounds(), equals(const Rect.fromLTRB(10, 10, 20, 20)));
  });

  test('transformation tests', () {
    const bounds = Rect.fromLTRB(0.0, 0.0, 10.0, 10.0);
    final p = Path()..addRect(bounds);
    final scaleMatrix = Float64List.fromList(<double>[
      2.5, 0.0, 0.0, 0.0, // first col
      0.0, 0.5, 0.0, 0.0, // second col
      0.0, 0.0, 1.0, 0.0, // third col
      0.0, 0.0, 0.0, 1.0, // fourth col
    ]);

    expect(p.getBounds(), equals(bounds));
    final Path pTransformed = p.transform(scaleMatrix);

    expect(pTransformed.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 10 * 2.5, 10 * 0.5)));

    final p2 = Path()..lineTo(10.0, 10.0);

    p.addPath(p2, const Offset(10.0, 10.0));
    expect(p.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 20.0, 20.0)));

    p.addPath(p2, const Offset(20.0, 20.0), matrix4: scaleMatrix);
    expect(p.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 20 + (10 * 2.5), 20 + (10 * .5))));

    p.extendWithPath(p2, Offset.zero);
    expect(p.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 45.0, 25.0)));

    p.extendWithPath(p2, const Offset(45.0, 25.0), matrix4: scaleMatrix);
    expect(p.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 70.0, 30.0)));
  });

  test('path metrics tests', () {
    final simpleHorizontalLine = Path()..lineTo(10.0, 0.0);

    // basic tests on horizontal line
    final PathMetrics simpleHorizontalMetrics = simpleHorizontalLine.computeMetrics();
    expect(() => simpleHorizontalMetrics.iterator.current, throwsRangeError);
    expect(simpleHorizontalMetrics.iterator.moveNext(), isTrue);
    expect(simpleHorizontalMetrics.iterator.current, isNotNull);
    expect(simpleHorizontalMetrics.iterator.current.length, equals(10.0));
    expect(simpleHorizontalMetrics.iterator.current.isClosed, isFalse);
    final Path simpleExtract = simpleHorizontalMetrics.iterator.current.extractPath(1.0, 9.0);
    expect(simpleExtract.getBounds(), equals(const Rect.fromLTRB(1.0, 0.0, 9.0, 0.0)));
    final Tangent posTan = simpleHorizontalMetrics.iterator.current.getTangentForOffset(1.0)!;
    expect(posTan.position, equals(const Offset(1.0, 0.0)));
    expect(posTan.angle, equals(0.0));

    expect(simpleHorizontalMetrics.iterator.moveNext(), isFalse);
    expect(() => simpleHorizontalMetrics.iterator.current, throwsRangeError);

    // test with forceClosed
    final PathMetrics simpleMetricsClosed = simpleHorizontalLine.computeMetrics(forceClosed: true);
    expect(() => simpleHorizontalMetrics.iterator.current, throwsRangeError);
    expect(simpleMetricsClosed.iterator.moveNext(), isTrue);
    expect(simpleMetricsClosed.iterator.current, isNotNull);
    expect(simpleMetricsClosed.iterator.current.length, equals(20.0)); // because we forced close
    expect(simpleMetricsClosed.iterator.current.isClosed, isTrue);
    final Path simpleExtract2 = simpleMetricsClosed.iterator.current.extractPath(1.0, 9.0);
    expect(simpleExtract2.getBounds(), equals(const Rect.fromLTRB(1.0, 0.0, 9.0, 0.0)));
    expect(simpleMetricsClosed.iterator.moveNext(), isFalse);

    // test getTangentForOffset with vertical line
    final simpleVerticalLine = Path()..lineTo(0.0, 10.0);
    final PathMetrics simpleMetricsVertical = simpleVerticalLine.computeMetrics()
      ..iterator.moveNext();
    final Tangent posTanVertical = simpleMetricsVertical.iterator.current.getTangentForOffset(5.0)!;
    expect(posTanVertical.position, equals(const Offset(0.0, 5.0)));
    expect(posTanVertical.angle, closeTo(-1.5708, .0001)); // 90 degrees

    // test getTangentForOffset with diagonal line
    final simpleDiagonalLine = Path()..lineTo(10.0, 10.0);
    final PathMetrics simpleMetricsDiagonal = simpleDiagonalLine.computeMetrics()
      ..iterator.moveNext();
    final double midPoint = simpleMetricsDiagonal.iterator.current.length / 2;
    final Tangent posTanDiagonal = simpleMetricsDiagonal.iterator.current.getTangentForOffset(
      midPoint,
    )!;
    expect(posTanDiagonal.position, equals(const Offset(5.0, 5.0)));
    expect(posTanDiagonal.angle, closeTo(-0.7853981633974483, .00001)); // ~45 degrees

    // test a multi-contour path
    final multiContour = Path()
      ..lineTo(0.0, 10.0)
      ..moveTo(10.0, 10.0)
      ..lineTo(10.0, 15.0);

    final PathMetrics multiContourMetric = multiContour.computeMetrics();
    expect(() => multiContourMetric.iterator.current, throwsRangeError);
    expect(multiContourMetric.iterator.moveNext(), isTrue);
    expect(multiContourMetric.iterator.current, isNotNull);
    expect(multiContourMetric.iterator.current.length, equals(10.0));
    expect(multiContourMetric.iterator.moveNext(), isTrue);
    expect(multiContourMetric.iterator.current, isNotNull);
    expect(multiContourMetric.iterator.current.length, equals(5.0));
    expect(multiContourMetric.iterator.moveNext(), isFalse);
    expect(() => multiContourMetric.iterator.current, throwsRangeError);
  });

  test('PathMetrics can remember lengths and isClosed', () {
    final path = Path()
      ..lineTo(0, 10)
      ..close()
      ..moveTo(0, 15)
      ..lineTo(10, 15);
    final List<PathMetric> metrics = path.computeMetrics().toList();
    expect(metrics.length, 2);
    expect(metrics[0].length, 20);
    expect(metrics[0].isClosed, true);
    expect(metrics[0].getTangentForOffset(4.0)!.vector, const Offset(0.0, 1.0));
    expect(metrics[0].extractPath(4.0, 10.0).computeMetrics().first.length, 6.0);
    expect(metrics[1].length, 10);
    expect(metrics[1].isClosed, false);
    expect(metrics[1].getTangentForOffset(4.0)!.vector, const Offset(1.0, 0.0));
    expect(metrics[1].extractPath(4.0, 6.0).computeMetrics().first.length, 2.0);
  });

  test('PathMetrics on a mutated path', () {
    final path = Path()..lineTo(0, 10);
    final PathMetrics metrics = path.computeMetrics();
    final PathMetric firstMetric = metrics.first;
    // We've consumed the iterator.
    expect(metrics, isEmpty);
    expect(firstMetric.length, 10);
    expect(firstMetric.isClosed, false);
    expect(firstMetric.getTangentForOffset(4.0)!.vector, const Offset(0.0, 1.0));
    expect(firstMetric.extractPath(4.0, 10.0).computeMetrics().first.length, 6.0);

    path
      ..lineTo(10, 10)
      ..lineTo(10, 0)
      ..close();
    // mutating the path shouldn't have added anything to the iterator.
    expect(metrics, isEmpty);
    expect(firstMetric.length, 10);
    expect(firstMetric.isClosed, false);
    expect(firstMetric.getTangentForOffset(4.0)!.vector, const Offset(0.0, 1.0));
    expect(firstMetric.extractPath(4.0, 10.0).computeMetrics().first.length, 6.0);

    // getting a new iterator should update us.
    final PathMetrics newMetrics = path.computeMetrics();
    final PathMetric newFirstMetric = newMetrics.first;
    expect(newMetrics, isEmpty);
    expect(newFirstMetric.length, 40);
    expect(newFirstMetric.isClosed, true);
    expect(newFirstMetric.getTangentForOffset(4.0)!.vector, const Offset(0.0, 1.0));
    expect(newFirstMetric.extractPath(4.0, 10.0).computeMetrics().first.length, 6.0);
  });

  group('path building', () {
    test('fillType', () {
      final p = Path();
      expect(p.fillType, equals(PathFillType.nonZero));
      p.fillType = PathFillType.evenOdd;
      expect(p.fillType, equals(PathFillType.evenOdd));
    });

    test('moveTo', () {
      final p = Path();
      p.moveTo(10, 10);
      p.lineTo(20, 10);
      expect(p.getBounds(), equals(const Rect.fromLTRB(10.0, 10.0, 20.0, 10.0)));
    });

    test('relativeMoveTo', () {
      final p = Path();
      p.relativeMoveTo(10, 10);
      p.lineTo(20, 10);
      expect(p.getBounds(), equals(const Rect.fromLTRB(10.0, 10.0, 20.0, 10.0)));
    });

    test('lineTo', () {
      final p = Path();
      p.lineTo(0, 10);
      expect(p.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 0.0, 10.0)));
    });

    test('path relativeLineTo', () {
      final p = Path();
      p.moveTo(100, 100);
      p.relativeLineTo(-50, -50);
      p.relativeLineTo(100, 0);
      p.relativeLineTo(-50, 50);
      expect(p.getBounds(), equals(const Rect.fromLTRB(50.0, 50.0, 150.0, 100.0)));
    });

    test('quadraticBezierTo', () {
      final p = Path();
      p.quadraticBezierTo(0, 10, 10, 0);
      expect(p.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)));
    });

    test('relativeQuadraticBezierTo', () {
      final p = Path();
      p.moveTo(10, 10);
      // Relative control (0,10), end (10,0) → absolute control (10,20), end (20,10).
      // getBounds() returns the control-polygon bbox: (10,10), (10,20), (20,10).
      p.relativeQuadraticBezierTo(0, 10, 10, 0);
      expect(p.getBounds(), equals(const Rect.fromLTRB(10.0, 10.0, 20.0, 20.0)));
    });

    test('cubicTo', () {
      final p = Path();
      // getBounds() returns the control-polygon bbox: (0,0), (0,10), (10,10), (10,0).
      p.cubicTo(0, 10, 10, 10, 10, 0);
      expect(p.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)));
    });

    test('relativeCubicTo', () {
      final p = Path();
      p.moveTo(5, 5);
      // Absolute control points: (5,15), (15,15), end (15,5).
      // getBounds() returns the control-polygon bbox: (5,5), (5,15), (15,15), (15,5).
      p.relativeCubicTo(0, 10, 10, 10, 10, 0);
      expect(p.getBounds(), equals(const Rect.fromLTRB(5.0, 5.0, 15.0, 15.0)));
    });

    test('conicTo', () {
      final p = Path();
      // Conic with w=1 is equivalent to a quadratic bezier.
      // getBounds() returns the control-polygon bbox: (0,0), (0,10), (10,0).
      p.conicTo(0, 10, 10, 0, 1);
      expect(p.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)));
    });

    test('relativeConicTo', () {
      final p = Path();
      p.moveTo(10, 10);
      // Relative conic with w=1: equivalent to relativeQuadraticBezierTo.
      // getBounds() returns the control-polygon bbox: (10,10), (10,20), (20,10).
      p.relativeConicTo(0, 10, 10, 0, 1);
      expect(p.getBounds(), equals(const Rect.fromLTRB(10.0, 10.0, 20.0, 20.0)));
    });

    test('arcTo', () {
      final p = Path();
      // Quarter-circle arc from (20,10) to (10,20), clockwise.
      // Control-polygon bbox spans the bottom-right quadrant of the oval.
      p.arcTo(const Rect.fromLTRB(0.0, 0.0, 20.0, 20.0), 0, pi / 2, true);
      expect(p.getBounds(), equals(const Rect.fromLTRB(10.0, 10.0, 20.0, 20.0)));
    });

    test('arcToPoint', () {
      final p = Path();
      p.moveTo(10, 0);
      // Small clockwise quarter-circle from (10,0) to (0,10) with radius 10.
      // Center at the origin; the arc spans the first quadrant.
      p.arcToPoint(const Offset(0, 10), radius: const Radius.circular(10));
      expect(p.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)));
    });

    test('relativeArcToPoint', () {
      final p = Path();
      p.moveTo(10, 0);
      // Relative (-10, 10) from (10, 0) = absolute endpoint (0, 10): same arc as arcToPoint.
      p.relativeArcToPoint(const Offset(-10, 10), radius: const Radius.circular(10));
      expect(p.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)));
    });

    test('addRect', () {
      final p = Path();
      p.addRect(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0));
      expect(p.getBounds(), equals(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0)));
    });

    test('addOval', () {
      final p = Path();
      p.addOval(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0));
      expect(p.getBounds(), equals(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0)));
    });

    test('addArc', () {
      final p = Path();
      p.addArc(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0), 0, 2 * pi);
      expect(p.getBounds(), equals(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0)));
    });

    test('addPolygon', () {
      final p = Path();
      p.addPolygon(const <Offset>[
        Offset(10.0, 20.0),
        Offset(30.0, 40.0),
        Offset(50.0, 60.0),
      ], true);
      expect(p.getBounds(), equals(const Rect.fromLTRB(10.0, 20.0, 50.0, 60.0)));
    });

    test('addRRect', () {
      final p = Path();
      p.addRRect(RRect.fromLTRBR(10.0, 20.0, 30.0, 40.0, const Radius.circular(5.0)));
      expect(p.getBounds(), equals(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0)));
    });

    test('addRSuperellipse', () {
      final p = Path();
      p.addRSuperellipse(
        RSuperellipse.fromLTRBR(10.0, 20.0, 30.0, 40.0, const Radius.circular(5.0)),
      );
      expect(p.getBounds(), equals(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0)));
    });

    test('addPath', () {
      final p1 = Path()..addRect(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0));
      final p2 = Path()..addRect(const Rect.fromLTRB(50.0, 60.0, 70.0, 80.0));
      p1.addPath(p2, const Offset(10.0, 10.0));
      expect(p1.getBounds(), equals(const Rect.fromLTRB(10.0, 20.0, 80.0, 90.0)));
    });

    test('extendWithPath', () {
      final p1 = Path()..addRect(const Rect.fromLTRB(10.0, 20.0, 30.0, 40.0));
      final p2 = Path()..addRect(const Rect.fromLTRB(50.0, 60.0, 70.0, 80.0));
      p1.extendWithPath(p2, const Offset(10.0, 10.0));
      expect(p1.getBounds(), equals(const Rect.fromLTRB(10.0, 20.0, 80.0, 90.0)));
    });

    test('close', () {
      final p = Path();
      p.lineTo(10.0, 10.0);
      expect(p.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)));
      p.close();
      expect(p.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)));
    });

    test('reset', () {
      final p = Path();
      p.lineTo(10.0, 10.0);
      expect(p.getBounds(), equals(const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)));
      p.reset();
      expect(p.getBounds(), equals(Rect.zero));
    });

    test('contains', () {
      final p = Path()..addRect(const Rect.fromLTRB(0, 0, 10, 10));
      expect(p.contains(const Offset(5, 5)), isTrue);
      expect(p.contains(const Offset(15, 5)), isFalse);
    });
  });

  test('path containing polygon with thousands of points', () {
    // Check that addPolygon works with a large point list that exceeds the
    // capacity of the Wasm stack.
    const pointCount = 10000;
    final points = List<Offset>.generate(pointCount + 1, (i) => Offset(i.toDouble(), i.toDouble()));
    final p = Path();
    p.addPolygon(points, false);
    expect(
      p.getBounds(),
      equals(Rect.fromLTRB(0, 0, pointCount.toDouble(), pointCount.toDouble())),
    );
  });
}
