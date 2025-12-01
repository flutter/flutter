// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show Float64List;
import 'dart:ui';

import 'package:test/test.dart';

void main() {
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

  test('PathMetrics on a mutated path', () {
    final path = Path()
      ..lineTo(0, 30)
      ..lineTo(40, 30)
      ..moveTo(100, 0)
      ..lineTo(100, 30)
      ..lineTo(140, 30)
      ..close();
    final PathMetrics metrics = path.computeMetrics();
    expect(
      metrics.toString(),
      '(PathMetric(length: 70.0, isClosed: false, contourIndex: 0), '
      'PathMetric(length: 120.0, isClosed: true, contourIndex: 1))',
    );
  });

  test('RSuperellipse path is correct for a slim diagonal shape', () {
    // This test mirrors a similar test from "geometry_test.dart" and serves as
    // a smoke test.
    final rsuperellipse = RSuperellipse.fromLTRBAndCorners(
      -50,
      -50,
      50,
      50,
      topLeft: const Radius.circular(1.0),
      topRight: const Radius.circular(99.0),
      bottomLeft: const Radius.circular(99.0),
      bottomRight: const Radius.circular(1.0),
    );
    final path = Path()
      ..addRSuperellipse(rsuperellipse)
      ..close();

    expect(path.contains(Offset.zero), isTrue);
    expect(path.contains(const Offset(-49.999, -49.999)), isFalse);
    expect(path.contains(const Offset(-49.999, 49.999)), isFalse);
    expect(path.contains(const Offset(49.999, 49.999)), isFalse);
    expect(path.contains(const Offset(49.999, -49.999)), isFalse);

    // The pointy ends at the NE and SW corners
    checkPointWithOffset(path, const Offset(-49.70, -49.70), const Offset(-0.02, -0.02));
    checkPointWithOffset(path, const Offset(49.70, 49.70), const Offset(0.02, 0.02));

    // Checks two points symmetrical to the origin.
    void checkDiagonalPoints(Offset p) {
      checkPointWithOffset(path, p, const Offset(0.02, -0.02));
      checkPointWithOffset(path, Offset(-p.dx, -p.dy), const Offset(-0.02, 0.02));
    }

    // A few other points along the edge
    checkDiagonalPoints(const Offset(-40.0, -49.59));
    checkDiagonalPoints(const Offset(-20.0, -45.64));
    checkDiagonalPoints(const Offset(0.0, -37.01));
    checkDiagonalPoints(const Offset(20.0, -21.96));
    checkDiagonalPoints(const Offset(21.05, -20.92));
    checkDiagonalPoints(const Offset(40.0, 5.68));
  });
}

void checkPointWithOffset(Path path, Offset inPoint, Offset outwardOffset) {
  expect(path.contains(inPoint), isTrue);
  expect(path.contains(inPoint + outwardOffset), isFalse);
}
