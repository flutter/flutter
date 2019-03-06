// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Continuous rectangle border scale and lerp', () {
    const ContinuousRectangleBorder c10 = ContinuousRectangleBorder(cornerRadius: 100.0);
    const ContinuousRectangleBorder c15 = ContinuousRectangleBorder(cornerRadius: 150.0);
    const ContinuousRectangleBorder c20 = ContinuousRectangleBorder(cornerRadius: 200.0);
    expect(c10.dimensions, const EdgeInsets.all(10.0));
    expect(c10.scale(2.0), c20);
    expect(c20.scale(0.5), c10);
    expect(ShapeBorder.lerp(c10, c20, 0.0), c10);
    expect(ShapeBorder.lerp(c10, c20, 0.5), c15);
    expect(ShapeBorder.lerp(c10, c20, 1.0), c20);
  });

  testWidgets('Golden test medium sized rectangle, medium radius', (WidgetTester tester) async {
    await tester.pumpWidget(
      RepaintBoundary(
        child: Container(
          alignment: Alignment.center,
          child: Material(
            color: Colors.blueAccent[400],
            shape: const ContinuousRectangleBorder(
              cornerRadius: 28.0,
            ),
            child: const SizedBox(
              height: 100,
              width: 100,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('continuous_rectangle_border.golden_test_medium_medium.png'),
      skip: !Platform.isLinux,
    );
  });

  testWidgets('Golden test small sized rectangle, medium radius', (WidgetTester tester) async {
    await tester.pumpWidget(
      RepaintBoundary(
        child: Container(
          alignment: Alignment.center,
          child: Material(
            color: Colors.blueAccent[400],
            shape: const ContinuousRectangleBorder(
              cornerRadius: 28.0,
            ),
            child: const SizedBox(
              height: 10,
              width: 100,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('continuous_rectangle_border.golden_test_small_medium.png'),
      skip: !Platform.isLinux,
    );
  });

  testWidgets('Golden test very small rectangle, medium radius', (WidgetTester tester) async {
    await tester.pumpWidget(
      RepaintBoundary(
        child: Container(
          alignment: Alignment.center,
          child: Material(
            color: Colors.blueAccent[400],
            shape: const ContinuousRectangleBorder(
              cornerRadius: 28.0,
            ),
            child: const SizedBox(
              height: 5,
              width: 100,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('continuous_rectangle_border.golden_test_vsmall_medium.png'),
      skip: !Platform.isLinux,
    );
  });

  testWidgets('Golden test large rectangle, large radius', (WidgetTester tester) async {
    await tester.pumpWidget(
      RepaintBoundary(
        child: Container(
          alignment: Alignment.center,
          child: Material(
            color: Colors.blueAccent[400],
            shape: const ContinuousRectangleBorder(
              cornerRadius: 50.0,
            ),
            child: const SizedBox(
              height: 300,
              width: 300,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('continuous_rectangle_border.golden_test_large_large.png'),
      skip: !Platform.isLinux,
    );
  });
}
