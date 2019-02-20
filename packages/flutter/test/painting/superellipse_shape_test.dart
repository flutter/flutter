// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('SuperellipseShape scale and lerp', () {
    final SuperellipseShape c10 = SuperellipseShape(side: const BorderSide(width: 10.0), borderRadius: BorderRadius.circular(100.0));
    final SuperellipseShape c15 = SuperellipseShape(side: const BorderSide(width: 15.0), borderRadius: BorderRadius.circular(150.0));
    final SuperellipseShape c20 = SuperellipseShape(side: const BorderSide(width: 20.0), borderRadius: BorderRadius.circular(200.0));
    expect(c10.dimensions, const EdgeInsets.all(10.0));
    expect(c10.scale(2.0), c20);
    expect(c20.scale(0.5), c10);
    expect(ShapeBorder.lerp(c10, c20, 0.0), c10);
    expect(ShapeBorder.lerp(c10, c20, 0.5), c15);
    expect(ShapeBorder.lerp(c10, c20, 1.0), c20);
  });

  test('SuperellipseShape BorderRadius.zero', () {
    final Rect rect1 = Rect.fromLTRB(10.0, 20.0, 30.0, 40.0);
    final Matcher looksLikeRect1 = isPathThat(
      includes: const <Offset>[ Offset(10.0, 20.0), Offset(20.0, 30.0) ],
      excludes: const <Offset>[ Offset(9.0, 19.0), Offset(31.0, 41.0) ],
    );

    // Default border radius and border side are zero, i.e. just a rectangle.
    expect(const SuperellipseShape().getOuterPath(rect1), looksLikeRect1);
    expect(const SuperellipseShape().getInnerPath(rect1), looksLikeRect1);

    // Represents the inner path when borderSide.width = 4, which is just rect1
    // inset by 4 on all sides.
    final Matcher looksLikeInnerPath = isPathThat(
      includes: const <Offset>[ Offset(14.0, 24.0), Offset(16.0, 26.0) ],
      excludes: const <Offset>[ Offset(9.0, 23.0), Offset(27.0, 37.0) ],
    );

    const BorderSide side = BorderSide(width: 4.0);
    expect(const SuperellipseShape(side: side).getOuterPath(rect1), looksLikeRect1);
    expect(const SuperellipseShape(side: side).getInnerPath(rect1), looksLikeInnerPath);
  });

  test('SuperellipseShape non-zero BorderRadius', () {
    final Rect rect = Rect.fromLTRB(10.0, 20.0, 30.0, 40.0);
    final Matcher looksLikeRect = isPathThat(
      includes: const <Offset>[ Offset(15.0, 25.0), Offset(20.0, 30.0) ],
      excludes: const <Offset>[ Offset(10.0, 20.0), Offset(30.0, 40.0) ],
    );
    const SuperellipseShape border = SuperellipseShape(
      borderRadius: BorderRadius.all(Radius.circular(5.0))
    );
    expect(border.getOuterPath(rect), looksLikeRect);
    expect(border.getInnerPath(rect), looksLikeRect);
  });

  testWidgets('Golden test even radii', (WidgetTester tester) async {
    await tester.pumpWidget(RepaintBoundary(
      child: Material(
        color: Colors.blueAccent[400],
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(28.0),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('superellipse_shape.golden_test_even_radii.png'),
      skip: !Platform.isLinux,
    );
  });

  testWidgets('Golden test varying radii', (WidgetTester tester) async {
    await tester.pumpWidget(RepaintBoundary(
      child: Material(
        color: Colors.greenAccent[400],
        shape: const SuperellipseShape(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28.0),
            bottomRight: Radius.circular(14.0),
          ),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('superellipse_shape.golden_test_varying_radii.png'),
      skip: !Platform.isLinux,
    );
  });

  testWidgets('Golden test large radii', (WidgetTester tester) async {
    await tester.pumpWidget(RepaintBoundary(
      child: Material(
        color: Colors.redAccent[400],
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(50.0),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('superellipse_shape.golden_test_large_radii.png'),
      skip: !Platform.isLinux,
    );
  });

}
