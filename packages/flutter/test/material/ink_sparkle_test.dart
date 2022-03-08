// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

// From InkSparkle._animationDuration.
const double _animationDurationMicros = 617 * 1000;

// Animation progress is captured at 0, 25, 50, 75, and 100.
// This can be changed to another factor of 100: lower for more granular
// animation screenshots, and higher for less granular animation screenshots.
const int _testIntervalPercent = 25;

final Duration _betweenGoldenInterval = Duration(microseconds: (_testIntervalPercent / 100.0 * _animationDurationMicros).round());

void main() {
  testWidgets('InkSparkle in a Button with default splashFactory paints by calling drawRect', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(splashFactory: InkSparkle.splashFactory),
            child: const Text('Sparkle!'),
            onPressed: () { },
          ),
        ),
      ),
    ));
    final Finder buttonFinder = find.text('Sparkle!');
    await tester.tap(buttonFinder);
    await tester.pump();
    await tester.pumpAndSettle();
  });

  testWidgets('InkSparkle default splashFactory paints with drawRect when bounded', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: InkWell(
            splashFactory: InkSparkle.splashFactory,
            child: const Text('Sparkle!'),
            onTap: () { },
          ),
        ),
      ),
    ));
    final Finder buttonFinder = find.text('Sparkle!');
    await tester.tap(buttonFinder);
    await tester.pump();
    await tester.pumpAndSettle();

    final MaterialInkController material = Material.of(tester.element(buttonFinder))!;
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawRect, 1));
  });

    testWidgets('InkSparkle default splashFactory paints with drawPaint when unbounded', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: InkResponse(
            splashFactory: InkSparkle.splashFactory,
            child: const Text('Sparkle!'),
            onTap: () { },
          ),
        ),
      ),
    ));
    final Finder buttonFinder = find.text('Sparkle!');
    await tester.tap(buttonFinder);
    await tester.pump();
    await tester.pumpAndSettle();

    final MaterialInkController material = Material.of(tester.element(buttonFinder))!;
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawPaint, 1));
  });

  /////////////
  // Goldens //
  /////////////

  testWidgets('InkSparkle renders with sparkles when top left of button is tapped', (WidgetTester tester) async {
    await _runTest(tester, 'top_left', 0.2);
  });

  testWidgets('InkSparkle renders with sparkles when center of button is tapped', (WidgetTester tester) async {
    await _runTest(tester, 'center', 0.5);
  });


  testWidgets('InkSparkle renders with sparkles when bottom right of button is tapped', (WidgetTester tester) async {
    await _runTest(tester, 'bottom_right', 0.8);
  });
}

Future<void> _runTest(WidgetTester tester, String positionName, double distanceFromTopLeft) async {
   final Key repaintKey = UniqueKey();
   await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: repaintKey,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(splashFactory: InkSparkle.constantTurbulenceSeedSplashFactory),
              child: const Text('Sparkle!'),
              onPressed: () { },
            ),
          ),
        ),
      ),
    ));
    final Finder buttonFinder = find.text('Sparkle!');
    final Finder repaintFinder = find.byKey(repaintKey);

    await _warmUpShader(tester, buttonFinder);

    final Offset topLeft = tester.getTopLeft(buttonFinder);
    final Offset bottomRight = tester.getBottomRight(buttonFinder);

    final Offset target = topLeft + (bottomRight - topLeft) * distanceFromTopLeft;
    await tester.tapAt(target);
    await tester.pump();
    for (int i = 0; i <= 100; i += _testIntervalPercent) {
      await expectLater(
        repaintFinder,
        matchesGoldenFile('ink_sparkle.$positionName.$i.png'),
      );
      // TODO(clocksmith): make this proper fraction of total animation time.
      await tester.pump(const Duration(milliseconds: 100));
    }
}

Future<void> _warmUpShader(WidgetTester tester, Finder buttonFinder) async {
    // Warm up shader. Compilation is of the order of 10 milliseconds and
    // Animation is < 1000 milliseconds. Use 2000 milliseconds as a safety
    // net to prevent flakiness.
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle(const Duration(milliseconds: 2000));
}
