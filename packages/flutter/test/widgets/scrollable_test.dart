// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Future<Null> pumpTest(WidgetTester tester, TargetPlatform platform) async {
  await tester.pumpWidget(new MaterialApp(
    theme: new ThemeData(
      platform: platform,
    ),
    home: new CustomScrollView(
      slivers: <Widget>[
        const SliverToBoxAdapter(child: const SizedBox(height: 2000.0)),
      ],
    ),
  ));
  await tester.pump(const Duration(seconds: 5)); // to let the theme animate
  return null;
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
    expect(getScrollOffset(tester), dragOffset);
    await tester.pump(); // trigger fling
    expect(getScrollOffset(tester), dragOffset);
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
    final double position = getScrollOffset(tester);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    expect(await tester.pumpAndSettle(), 1);
    expect(getScrollOffset(tester), position);
    await gesture.up();
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
}
