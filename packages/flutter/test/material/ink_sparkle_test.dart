// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

void main() {

  // TODO(clocksmith): Mock math.Random().nextDouble() to return 0.1337.
  Mock

  // From InkSparkle._animationDuration.
  const double animationDurationMicros = 617 * 1000;

  // Animation progress is captured at 0, 50, and 100.
  // Change this to 25, or another factor of 100, for more granular tests.
  const int testIntervalPercent = 50;

  testWidgets('InkSparkle renders with sparkles', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Theme(
            data: ThemeData(splashFactory: InkSparkle.splashFactory),
            child: ElevatedButton(
              child: const Text('Sparkle!'),
              onPressed: () { },
            ),
          ),
        ),
      ),
    ));
    final Finder buttonFinder = find.text('Sparkle!');
    await tester.tap(buttonFinder);

    // Warm up shader. Compilation is of the order of 10 milliseconds and 
    // Animation is < 1000 milliseconds. Use 2000 milliseconds as a safety
    // net to prevent flakiness.
    await tester.pumpAndSettle(const Duration(milliseconds: 2000));

    final Offset topLeft = tester.getTopLeft(buttonFinder);
    final Offset bottomRight = tester.getBottomRight(buttonFinder);

    // Test tapping the top left quadrant of the button.
    final Offset topLeftTarget = topLeft + (bottomRight - topLeft) * 0.2;
    await tester.tapAt(topLeftTarget);
    for (int i = 0; i <= 100; i += testIntervalPercent) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('ink_sparkle_top_left_$i.png'),
      );
      await tester.pump(Duration(microseconds: (testIntervalPercent * animationDurationMicros).round()));
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));

    // Test tapping the center of the button.
    final Offset centerTarget = topLeft + (bottomRight - topLeft) * 0.5;
    await tester.tapAt(centerTarget);
    for (int i = 0; i <= 100; i += testIntervalPercent) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('ink_sparkle_center_$i.png'),
      );
      await tester.pump(Duration(microseconds: (testIntervalPercent * animationDurationMicros).round()));
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));

    // Test tapping the bottom right quadrant of the button.
    final Offset bottomRightTarget = topLeft + (bottomRight - topLeft) * 0.8;
    await tester.tapAt(bottomRightTarget);
    for (int i = 0; i <= 100; i += testIntervalPercent) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('ink_sparkle_center_bottom_right_$i.png'),
      );
      await tester.pump(Duration(microseconds: (testIntervalPercent * animationDurationMicros).round()));
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
  });
}
