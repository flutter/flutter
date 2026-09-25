// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'dart:ui' show PathMetric;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const Color _blueAccent400 = Color(0xFF2979FF);
const Color _green100 = Color(0xFFC8E6C9);
const Color _green200 = Color(0xFFA5D6A7);
const Color _green300 = Color(0xFF81C784);
const Color _green400 = Color(0xFF66BB6A);
const Color _green500 = Color(0xFF4CAF50);
const Color _redAccent400 = Color(0xFFFF1744);

/// Builds a repaint boundary for golden testing a [ContinuousRectangleBorder].
Widget _buildGoldenTest({required Color color, required BorderRadiusGeometry borderRadius}) {
  return RepaintBoundary(
    child: DecoratedBox(
      decoration: ShapeDecoration(
        color: color,
        shape: ContinuousRectangleBorder(borderRadius: borderRadius),
      ),
    ),
  );
}

// The total length of every contour in [path]. A contour that doubles back over
// itself is longer than the outline it is supposed to draw.
double _perimeterOf(Path path) {
  var length = 0.0;
  for (final PathMetric metric in path.computeMetrics()) {
    length += metric.length;
  }
  return length;
}

void main() {
  test('ContinuousRectangleBorder defaults', () {
    const border = ContinuousRectangleBorder();
    expect(border.side, BorderSide.none);
    expect(border.borderRadius, BorderRadius.zero);
  });

  test('ContinuousRectangleBorder copyWith, ==, hashCode', () {
    expect(const ContinuousRectangleBorder(), const ContinuousRectangleBorder().copyWith());
    expect(
      const ContinuousRectangleBorder().hashCode,
      const ContinuousRectangleBorder().copyWith().hashCode,
    );
    const side = BorderSide(width: 10.0, color: Color(0xff123456));
    const radius = BorderRadius.all(Radius.circular(16.0));
    const directionalRadius = BorderRadiusDirectional.all(Radius.circular(16.0));

    expect(
      const ContinuousRectangleBorder().copyWith(side: side, borderRadius: radius),
      const ContinuousRectangleBorder(side: side, borderRadius: radius),
    );

    expect(
      const ContinuousRectangleBorder().copyWith(side: side, borderRadius: directionalRadius),
      const ContinuousRectangleBorder(side: side, borderRadius: directionalRadius),
    );
  });

  test('ContinuousRectangleBorder scale and lerp', () {
    const c10 = ContinuousRectangleBorder(
      side: BorderSide(width: 10.0),
      borderRadius: BorderRadius.all(Radius.circular(100.0)),
    );
    const c15 = ContinuousRectangleBorder(
      side: BorderSide(width: 15.0),
      borderRadius: BorderRadius.all(Radius.circular(150.0)),
    );
    const c20 = ContinuousRectangleBorder(
      side: BorderSide(width: 20.0),
      borderRadius: BorderRadius.all(Radius.circular(200.0)),
    );
    expect(c10.dimensions, const EdgeInsets.all(10.0));
    expect(c10.scale(2.0), c20);
    expect(c20.scale(0.5), c10);
    expect(ShapeBorder.lerp(c10, c20, 0.0), c10);
    expect(ShapeBorder.lerp(c10, c20, 0.5), c15);
    expect(ShapeBorder.lerp(c10, c20, 1.0), c20);
  });

  test('ContinuousRectangleBorder BorderRadius.zero', () {
    const rect1 = Rect.fromLTRB(10.0, 20.0, 30.0, 40.0);
    final Matcher looksLikeRect1 = isPathThat(
      includes: const <Offset>[Offset(10.0, 20.0), Offset(20.0, 30.0)],
      excludes: const <Offset>[Offset(9.0, 19.0), Offset(31.0, 41.0)],
    );

    // Default border radius and border side are zero, i.e. just a rectangle.
    expect(const ContinuousRectangleBorder().getOuterPath(rect1), looksLikeRect1);
    expect(const ContinuousRectangleBorder().getInnerPath(rect1), looksLikeRect1);

    // Represents the inner path when borderSide.width = 4, which is just rect1
    // inset by 4 on all sides.
    final Matcher looksLikeInnerPath = isPathThat(
      includes: const <Offset>[Offset(14.0, 24.0), Offset(16.0, 26.0)],
      excludes: const <Offset>[Offset(9.0, 23.0), Offset(27.0, 37.0)],
    );

    const side = BorderSide(width: 4.0);
    expect(const ContinuousRectangleBorder(side: side).getOuterPath(rect1), looksLikeRect1);
    expect(const ContinuousRectangleBorder(side: side).getInnerPath(rect1), looksLikeInnerPath);
  });

  test('ContinuousRectangleBorder non-zero BorderRadius', () {
    const rect = Rect.fromLTRB(10.0, 20.0, 30.0, 40.0);
    final Matcher looksLikeRect = isPathThat(
      includes: const <Offset>[Offset(15.0, 25.0), Offset(20.0, 30.0)],
      excludes: const <Offset>[Offset(10.0, 20.0), Offset(30.0, 40.0)],
    );
    const border = ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0)));
    expect(border.getOuterPath(rect), looksLikeRect);
    expect(border.getInnerPath(rect), looksLikeRect);
  });

  test('ContinuousRectangleBorder non-zero BorderRadiusDirectional', () {
    const rect = Rect.fromLTRB(10.0, 20.0, 30.0, 40.0);
    final Matcher looksLikeRectLtr = isPathThat(
      includes: const <Offset>[Offset(15.0, 25.0), Offset(20.0, 30.0)],
      excludes: const <Offset>[Offset(10.0, 20.0), Offset(10.0, 40.0)],
    );
    const border = ContinuousRectangleBorder(
      borderRadius: BorderRadiusDirectional.only(
        topStart: Radius.circular(5.0),
        bottomStart: Radius.circular(5.0),
      ),
    );

    expect(border.getOuterPath(rect, textDirection: TextDirection.ltr), looksLikeRectLtr);
    expect(border.getInnerPath(rect, textDirection: TextDirection.ltr), looksLikeRectLtr);

    final Matcher looksLikeRectRtl = isPathThat(
      includes: const <Offset>[Offset(25.0, 35.0), Offset(25.0, 25.0)],
      excludes: const <Offset>[Offset(30.0, 20.0), Offset(30.0, 40.0)],
    );

    expect(border.getOuterPath(rect, textDirection: TextDirection.rtl), looksLikeRectRtl);
    expect(border.getInnerPath(rect, textDirection: TextDirection.rtl), looksLikeRectRtl);
  });

  // Regression test for https://github.com/flutter/flutter/issues/132947
  test('ContinuousRectangleBorder scales down radii that overflow the rect', () {
    const rect = Rect.fromLTWH(0.0, 0.0, 18.0, 18.0);

    // Two corner radii share each side, so a radius greater than half of the
    // shortest side has to be scaled down. Otherwise the outline overshoots
    // and doubles back on itself, which is invisible when the shape is filled
    // but is drawn as a self-intersecting outline when the shape is stroked.
    const overflowing = ContinuousRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24.0)),
    );
    const scaled = ContinuousRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
    );

    expect(
      overflowing.getOuterPath(rect),
      coversSameAreaAs(scaled.getOuterPath(rect), areaToCompare: rect.inflate(2.0)),
    );

    // Radii that already fit are left alone.
    const fitting = ContinuousRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
    );
    expect(
      fitting.getOuterPath(rect),
      coversSameAreaAs(
        ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ).getOuterPath(rect),
        areaToCompare: rect.inflate(2.0),
      ),
    );
    expect(
      fitting.getOuterPath(rect),
      isNot(coversSameAreaAs(scaled.getOuterPath(rect), areaToCompare: rect.inflate(2.0))),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/132947
  test('ContinuousRectangleBorder scales down elliptical radii that overflow a side', () {
    // This shape spends the x radii along the vertical sides and the y radii
    // along the horizontal ones, so an elliptical radius overflows the side it
    // is actually drawn along. Here the bottom side is 20.0 wide but is asked
    // for 15.0 from the bottom right corner and 15.0 from the bottom left one.
    const rect = Rect.fromLTWH(0.0, 0.0, 20.0, 100.0);
    const overflowing = ContinuousRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomRight: Radius.elliptical(0.0, 15.0),
        bottomLeft: Radius.elliptical(15.0, 0.0),
      ),
    );
    // 20.0 / (15.0 + 15.0) leaves 10.0 for each of the two corners.
    const scaled = ContinuousRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomRight: Radius.elliptical(0.0, 10.0),
        bottomLeft: Radius.elliptical(10.0, 0.0),
      ),
    );

    final Path overflowingPath = overflowing.getOuterPath(rect);
    expect(
      overflowingPath,
      coversSameAreaAs(scaled.getOuterPath(rect), areaToCompare: rect.inflate(2.0)),
    );
    // The two curves would otherwise overshoot and the straight segment between
    // them would run backwards, which covers the same area but makes the
    // stroked outline double back over itself.
    expect(_perimeterOf(overflowingPath), moreOrLessEquals(_perimeterOf(scaled.getOuterPath(rect))));
  });

  // Regression test for https://github.com/flutter/flutter/issues/132947
  test('ContinuousRectangleBorder treats a negative radius as zero while scaling', () {
    // The radii are scaled down by comparing the sum of the two radii drawn
    // along a side against the length of that side. A negative radius has to be
    // clamped to zero before that sum is taken, otherwise it cancels out part of
    // the radius of the corner it shares the side with and lets that corner
    // overflow.
    const rect = Rect.fromLTWH(0.0, 0.0, 20.0, 100.0);
    const mixed = ContinuousRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomRight: Radius.elliptical(0.0, 40.0),
        bottomLeft: Radius.elliptical(-15.0, 0.0),
      ),
    );
    const clamped = ContinuousRectangleBorder(
      borderRadius: BorderRadius.only(bottomRight: Radius.elliptical(0.0, 40.0)),
    );

    // A negative radius is documented to behave exactly like a zero radius.
    final Path mixedPath = mixed.getOuterPath(rect);
    expect(
      mixedPath,
      coversSameAreaAs(clamped.getOuterPath(rect), areaToCompare: rect.inflate(2.0)),
    );
    expect(_perimeterOf(mixedPath), moreOrLessEquals(_perimeterOf(clamped.getOuterPath(rect))));
    // The outline never leaves the rect it was given.
    expect(mixedPath.getBounds(), rect);
  });

  testWidgets('Golden test even radii', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildGoldenTest(
        color: _blueAccent400,
        borderRadius: const BorderRadius.all(Radius.circular(28.0)),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('continuous_rectangle_border.golden_test_even_radii.png'),
    );
  });

  testWidgets('Golden test varying radii', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildGoldenTest(
        color: _green100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.elliptical(100.0, 200.0),
          topRight: Radius.circular(350.0),
          bottomLeft: Radius.elliptical(2000.0, 100.0),
          bottomRight: Radius.circular(700.0),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('continuous_rectangle_border.golden_test_varying_radii.png'),
    );
  });

  testWidgets('Golden test topLeft radii', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildGoldenTest(
        color: _green200,
        borderRadius: const BorderRadius.only(topLeft: Radius.elliptical(100.0, 200.0)),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('continuous_rectangle_border.golden_test_topLeft_radii.png'),
    );
  });

  testWidgets('Golden test topRight radii', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildGoldenTest(
        color: _green300,
        borderRadius: const BorderRadius.only(topRight: Radius.circular(350.0)),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('continuous_rectangle_border.golden_test_topRight_radii.png'),
    );
  });

  testWidgets('Golden test bottomLeft radii', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildGoldenTest(
        color: _green400,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.elliptical(2000.0, 100.0)),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('continuous_rectangle_border.golden_test_bottomLeft_radii.png'),
    );
  });

  testWidgets('Golden test bottomRight radii', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildGoldenTest(
        color: _green500,
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(700.0)),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('continuous_rectangle_border.golden_test_bottomRight_radii.png'),
    );
  });

  testWidgets('Golden test large radii', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildGoldenTest(
        color: _redAccent400,
        borderRadius: const BorderRadius.all(Radius.circular(50.0)),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('continuous_rectangle_border.golden_test_large_radii.png'),
    );
  });
}
