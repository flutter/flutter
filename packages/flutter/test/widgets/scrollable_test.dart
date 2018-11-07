// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Future<void> pumpTest(WidgetTester tester, TargetPlatform platform) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(
      platform: platform,
    ),
    home: const CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(child: SizedBox(height: 2000.0)),
      ],
    ),
  ));
  await tester.pump(const Duration(seconds: 5)); // to let the theme animate
}

const double dragOffset = 200.0;

double getScrollOffset(WidgetTester tester) {
  final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
  return viewport.offset.pixels;
}

double getScrollVelocity(WidgetTester tester) {
  final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
  final ScrollPosition position = viewport.offset;
  // Access for test only.
  return position.activity.velocity; // ignore: INVALID_USE_OF_PROTECTED_MEMBER
}

void resetScrollOffset(WidgetTester tester) {
  final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
  final ScrollPosition position = viewport.offset;
  position.jumpTo(0.0);
}

void main() {
  testWidgets('Flings on different platforms', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.android);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    expect(getScrollOffset(tester), dragOffset);
    await tester.pump(); // trigger fling
    expect(getScrollOffset(tester), dragOffset);
    await tester.pump(const Duration(seconds: 5));
    final double result1 = getScrollOffset(tester);

    resetScrollOffset(tester);

    await pumpTest(tester, TargetPlatform.iOS);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    // Scroll starts ease into the scroll on iOS.
    expect(getScrollOffset(tester), moreOrLessEquals(197.16666666666669));
    await tester.pump(); // trigger fling
    expect(getScrollOffset(tester), moreOrLessEquals(197.16666666666669));
    await tester.pump(const Duration(seconds: 5));
    final double result2 = getScrollOffset(tester);

    expect(result1, lessThan(result2)); // iOS (result2) is slipperier than Android (result1)
  });

  testWidgets('Holding scroll', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.iOS);
    await tester.drag(find.byType(Viewport), const Offset(0.0, 200.0));
    expect(getScrollOffset(tester), -200.0);
    await tester.pump(); // trigger ballistic
    await tester.pump(const Duration(milliseconds: 10));
    expect(getScrollOffset(tester), greaterThan(-200.0));
    expect(getScrollOffset(tester), lessThan(0.0));
    final double heldPosition = getScrollOffset(tester);
    // Hold and let go while in overscroll.
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    expect(await tester.pumpAndSettle(), 1);
    expect(getScrollOffset(tester), heldPosition);
    await gesture.up();
    // Once the hold is let go, it should still snap back to origin.
    expect(await tester.pumpAndSettle(const Duration(minutes: 1)), 2);
    expect(getScrollOffset(tester), 0.0);
  });

  testWidgets('Repeated flings builds momentum on iOS', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.iOS);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    await tester.pump(); // trigger fling
    await tester.pump(const Duration(milliseconds: 10));
    // Repeat the exact same motion.
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    await tester.pump();
    // On iOS, the velocity will be larger than the velocity of the last fling by a
    // non-trivial amount.
    expect(getScrollVelocity(tester), greaterThan(1100.0));

    resetScrollOffset(tester);

    await pumpTest(tester, TargetPlatform.android);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    await tester.pump(); // trigger fling
    await tester.pump(const Duration(milliseconds: 10));
    // Repeat the exact same motion.
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    await tester.pump();
    // On Android, there is no momentum build. The final velocity is the same as the
    // velocity of the last fling.
    expect(getScrollVelocity(tester), moreOrLessEquals(1000.0));
  });

  testWidgets('No iOS momentum build with flings in opposite directions', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.iOS);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    await tester.pump(); // trigger fling
    await tester.pump(const Duration(milliseconds: 10));
    // Repeat the exact same motion in the opposite direction.
    await tester.fling(find.byType(Viewport), const Offset(0.0, dragOffset), 1000.0);
    await tester.pump();
    // The only applied velocity to the scrollable is the second fling that was in the
    // opposite direction.
    expect(getScrollVelocity(tester), greaterThan(-1000.0));
    expect(getScrollVelocity(tester), lessThan(0.0));
  });

  testWidgets('No iOS momentum kept on hold gestures', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.iOS);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    await tester.pump(); // trigger fling
    await tester.pump(const Duration(milliseconds: 10));
    expect(getScrollVelocity(tester), greaterThan(0.0));
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.up();
    // After a hold longer than 2 frames, previous velocity is lost.
    expect(getScrollVelocity(tester), 0.0);
  });

  testWidgets('Drags creeping unaffected on Android', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.android);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    await gesture.moveBy(const Offset(0.0, -0.5));
    expect(getScrollOffset(tester), 0.5);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 10));
    expect(getScrollOffset(tester), 1.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 20));
    expect(getScrollOffset(tester), 1.5);
  });

  testWidgets('Drags creeping must break threshold on iOS', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.iOS);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    await gesture.moveBy(const Offset(0.0, -0.5));
    expect(getScrollOffset(tester), 0.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 10));
    expect(getScrollOffset(tester), 0.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 20));
    expect(getScrollOffset(tester), 0.0);
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 30));
    // Now -2.5 in total.
    expect(getScrollOffset(tester), 0.0);
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 40));
    // Now -3.5, just reached threshold.
    expect(getScrollOffset(tester), 0.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 50));
    // -0.5 over threshold transferred.
    expect(getScrollOffset(tester), 0.5);
  });

  testWidgets('Big drag over threshold magnitude preserved on iOS', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.iOS);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    await gesture.moveBy(const Offset(0.0, -30.0));
    // No offset lost from threshold.
    expect(getScrollOffset(tester), 30.0);
  });

  testWidgets('Slow threshold breaks are attenuated on iOS', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.iOS);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    // This is a typical 'hesitant' iOS scroll start.
    await gesture.moveBy(const Offset(0.0, -10.0));
    expect(getScrollOffset(tester), moreOrLessEquals(1.1666666666666667));
    await gesture.moveBy(const Offset(0.0, -10.0), timeStamp: const Duration(milliseconds: 20));
    // Subsequent motions unaffected.
    expect(getScrollOffset(tester), moreOrLessEquals(11.16666666666666673));
  });

  testWidgets('Small continuing motion preserved on iOS', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.iOS);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    await gesture.moveBy(const Offset(0.0, -30.0)); // Break threshold.
    expect(getScrollOffset(tester), 30.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 20));
    expect(getScrollOffset(tester), 30.5);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 40));
    expect(getScrollOffset(tester), 31.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 60));
    expect(getScrollOffset(tester), 31.5);
  });

  testWidgets('Motion stop resets threshold on iOS', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.iOS);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    await gesture.moveBy(const Offset(0.0, -30.0)); // Break threshold.
    expect(getScrollOffset(tester), 30.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 20));
    expect(getScrollOffset(tester), 30.5);
    await gesture.moveBy(Offset.zero);
    // Stationary too long, threshold reset.
    await gesture.moveBy(Offset.zero, timeStamp: const Duration(milliseconds: 120));
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 140));
    expect(getScrollOffset(tester), 30.5);
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 150));
    expect(getScrollOffset(tester), 30.5);
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 160));
    expect(getScrollOffset(tester), 30.5);
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 170));
    // New threshold broken.
    expect(getScrollOffset(tester), 31.5);
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 180));
    expect(getScrollOffset(tester), 32.5);
  });
}
