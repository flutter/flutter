// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Activity indicator animate property works', (WidgetTester tester) async {
    await tester.pumpWidget(buildCupertinoActivityIndicator());
    expect(SchedulerBinding.instance.transientCallbackCount, equals(1));

    await tester.pumpWidget(buildCupertinoActivityIndicator(false));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));

    await tester.pumpWidget(Container());

    await tester.pumpWidget(buildCupertinoActivityIndicator(false));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));

    await tester.pumpWidget(buildCupertinoActivityIndicator());
    expect(SchedulerBinding.instance.transientCallbackCount, equals(1));
  });

  testWidgets('Activity indicator dark mode', (WidgetTester tester) async {
    final Key key = UniqueKey();
    await tester.pumpWidget(
      Center(
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RepaintBoundary(
            key: key,
            child: const ColoredBox(
              color: CupertinoColors.white,
              child: CupertinoActivityIndicator(animating: false, radius: 35),
            ),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(key), matchesGoldenFile('activityIndicator.paused.light.png'));

    await tester.pumpWidget(
      Center(
        child: MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: RepaintBoundary(
            key: key,
            child: const ColoredBox(
              color: CupertinoColors.black,
              child: CupertinoActivityIndicator(animating: false, radius: 35),
            ),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(key), matchesGoldenFile('activityIndicator.paused.dark.png'));
  });

  testWidgets('Activity indicator 0% in progress', (WidgetTester tester) async {
    final Key key = UniqueKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: const ColoredBox(
            color: CupertinoColors.white,
            child: CupertinoActivityIndicator.partiallyRevealed(progress: 0),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(key), matchesGoldenFile('activityIndicator.inprogress.0.0.png'));
  });

  testWidgets('Activity indicator 30% in progress', (WidgetTester tester) async {
    final Key key = UniqueKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: const ColoredBox(
            color: CupertinoColors.white,
            child: CupertinoActivityIndicator.partiallyRevealed(progress: 0.5),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(key), matchesGoldenFile('activityIndicator.inprogress.0.3.png'));
  });

  testWidgets('Activity indicator 100% in progress', (WidgetTester tester) async {
    final Key key = UniqueKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: const ColoredBox(
            color: CupertinoColors.white,
            child: CupertinoActivityIndicator.partiallyRevealed(),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(key), matchesGoldenFile('activityIndicator.inprogress.1.0.png'));
  });

  // Regression test for https://github.com/flutter/flutter/issues/41345.
  testWidgets('has the correct corner radius', (WidgetTester tester) async {
    await tester.pumpWidget(const CupertinoActivityIndicator(animating: false, radius: 100));

    // An earlier implementation for the activity indicator started drawing
    // the ticks at 9 o'clock, however, in order to support partially revealed
    // indicator (https://github.com/flutter/flutter/issues/29159), the
    // first tick was changed to be at 12 o'clock.
    expect(
      find.byType(CupertinoActivityIndicator),
      paints..rrect(rrect: const RRect.fromLTRBXY(-10, -100 / 3, 10, -100, 10, 10)),
    );
  });

  testWidgets('Can specify color', (WidgetTester tester) async {
    final Key key = UniqueKey();
    const color = Color(0xFF5D3FD3);
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: const ColoredBox(
            color: CupertinoColors.white,
            child: CupertinoActivityIndicator(animating: false, color: color, radius: 100),
          ),
        ),
      ),
    );

    expect(
      find.byType(CupertinoActivityIndicator),
      paints..rrect(
        rrect: const RRect.fromLTRBXY(-10, -100 / 3, 10, -100, 10, 10),
        // The value of 47 comes from the alpha that is applied to the first
        // tick.
        color: color.withAlpha(47),
      ),
    );
  });

  test('tickCount defaults to 8', () {
    expect(const CupertinoActivityIndicator().tickCount, 8);
    expect(const CupertinoActivityIndicator.partiallyRevealed().tickCount, 8);
  });

  for (final tickCount in <int>[8, 12, 16]) {
    testWidgets('Can specify $tickCount ticks', (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(child: CupertinoActivityIndicator(animating: false, tickCount: tickCount)),
      );

      expect(
        find.byType(CupertinoActivityIndicator),
        paintsExactlyCountTimes(#drawRRect, tickCount),
      );
      expect(
        tester
            .widget<CupertinoActivityIndicator>(find.byType(CupertinoActivityIndicator))
            .tickCount,
        tickCount,
      );
    });
  }

  testWidgets('Partially revealed activity indicator honors tickCount', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Center(
        child: CupertinoActivityIndicator.partiallyRevealed(progress: 0.5, tickCount: 16),
      ),
    );

    expect(find.byType(CupertinoActivityIndicator), paintsExactlyCountTimes(#drawRRect, 8));
  });

  test('tickCount must be positive', () {
    expect(() => CupertinoActivityIndicator(tickCount: 0), throwsAssertionError);
    expect(() => CupertinoActivityIndicator.partiallyRevealed(tickCount: 0), throwsAssertionError);
  });

  group('CupertinoLinearActivityIndicator', () {
    testWidgets('draws the linear activity indicator', (WidgetTester tester) async {
      await tester.pumpWidget(const Center(child: CupertinoLinearActivityIndicator(progress: 0.2)));

      expect(
        find.byType(CupertinoLinearActivityIndicator),
        paints
          ..rrect(
            color: CupertinoColors.systemFill,
            rrect: RRect.fromRectAndRadius(
              const Rect.fromLTWH(0.0, 0.0, 800, 4.5),
              const Radius.circular(2.25),
            ),
          )
          ..rrect(
            color: CupertinoColors.activeBlue,
            rrect: RRect.fromRectAndRadius(
              const Rect.fromLTWH(0.0, 0.0, 160, 4.5),
              const Radius.circular(2.25),
            ),
          ),
      );
    });

    testWidgets('draws the linear activity indicator with a custom height and color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const Center(
          child: CupertinoLinearActivityIndicator(
            progress: 0.5,
            height: 10,
            color: CupertinoColors.activeGreen,
          ),
        ),
      );

      expect(
        find.byType(CupertinoLinearActivityIndicator),
        paints
          ..rrect(
            color: CupertinoColors.systemFill,
            rrect: RRect.fromRectAndRadius(
              const Rect.fromLTWH(0.0, 0.0, 800, 10),
              const Radius.circular(5),
            ),
          )
          ..rrect(
            color: CupertinoColors.activeGreen,
            rrect: RRect.fromRectAndRadius(
              const Rect.fromLTWH(0.0, 0.0, 400, 10),
              const Radius.circular(5),
            ),
          ),
      );
    });
  });

  testWidgets('CupertinoActivityIndicator does not crash at zero area', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(child: SizedBox.shrink(child: CupertinoActivityIndicator())),
      ),
    );
    expect(tester.getSize(find.byType(CupertinoActivityIndicator)), Size.zero);
  });

  testWidgets('CupertinoLinearActivityIndicator does not crash at zero area', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: SizedBox.shrink(child: CupertinoLinearActivityIndicator(progress: 0.5)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(CupertinoLinearActivityIndicator)), Size.zero);
  });
}

Widget buildCupertinoActivityIndicator([bool? animating]) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: CupertinoActivityIndicator(animating: animating ?? true),
  );
}
