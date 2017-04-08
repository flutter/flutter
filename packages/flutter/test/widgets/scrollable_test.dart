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

  testWidgets('Flings on different platforms', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.iOS);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    expect(getScrollOffset(tester), dragOffset);
    await tester.pump(); // trigger fling
    expect(getScrollOffset(tester), dragOffset);
    await tester.pump(const Duration(seconds: 5));
    final double result1 = getScrollOffset(tester);

    resetScrollOffset(tester);

    await pumpTest(tester, TargetPlatform.android);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    expect(getScrollOffset(tester), dragOffset);
    await tester.pump(); // trigger fling
    expect(getScrollOffset(tester), dragOffset);
    await tester.pump(const Duration(seconds: 5));
    final double result2 = getScrollOffset(tester);

    expect(result1, greaterThan(result2)); // iOS (result1) is slipperier than Android (result2)
  });
}
