// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/carousel/carousel.2.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('Carousel auto-plays and pauses on interaction (unweighted)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.CarouselAutoPlayExampleApp());

    expect(find.byType(CarouselView), findsOneWidget);
    await tester.pumpAndSettle();

    final ScrollableState scrollable = tester.state(
      find.descendant(
        of: find.byType(CarouselView),
        matching: find.byType(Scrollable),
      ),
    );
    final double offset0 = scrollable.position.pixels;

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(offset0));
    final double offset1 = scrollable.position.pixels;

    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(CarouselView)));
    await tester.pump();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, offset1);

    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.removePointer();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(offset1));
  });

  testWidgets('Carousel auto-plays and pauses on interaction (weighted)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.CarouselAutoPlayExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Weighted'));
    await tester.pumpAndSettle();

    final ScrollableState scrollable = tester.state(
      find.descendant(
        of: find.byType(CarouselView),
        matching: find.byType(Scrollable),
      ),
    );
    final double offset0 = scrollable.position.pixels;

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(offset0));
    final double offset1 = scrollable.position.pixels;

    final TestGesture touchGesture = await tester.startGesture(
      tester.getCenter(find.byType(CarouselView)),
    );
    await touchGesture.moveBy(const Offset(-50, 0));
    await tester.pump();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, lessThan(offset1 + 100));

    await touchGesture.up();
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(offset1 + 50));
  });
}
