// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/carousel/carousel.3.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('Carousel auto-plays and pauses on interaction', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.CarouselAutoPlayExampleApp());

    expect(find.byType(CarouselView), findsOneWidget);

    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    // initialItem is 1. The offset for item 1 in a weighted carousel depends on screen width.
    // We just capture the initial offset.
    final double offset0 = scrollable.position.pixels;

    // Timer is 2 seconds. Wait for it to trigger.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Should have auto-scrolled to the next item.
    expect(scrollable.position.pixels, greaterThan(offset0));
    final double offset1 = scrollable.position.pixels;

    // Test pause on hover.
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(CarouselView)));
    await tester.pump();

    // Wait for what would be the next interval.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Should not have auto-scrolled because the mouse is hovering.
    expect(scrollable.position.pixels, offset1);

    // Exit hover.
    await gesture.moveTo(Offset.zero);
    await tester.pump();

    // Wait for the next interval.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Should have auto-scrolled to the next item.
    expect(scrollable.position.pixels, greaterThan(offset1));
    final double offset2 = scrollable.position.pixels;

    // Test pause on pan.
    final TestGesture touchGesture = await tester.startGesture(
      tester.getCenter(find.byType(CarouselView)),
    );
    await touchGesture.moveBy(
      const Offset(-50, 0),
    ); // Move enough to break touch slop
    await tester.pump();

    // Wait for interval.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Should not have auto-scrolled because it is being panned (touched).
    // The position will be around offset2 + (50 - touch slop).
    // We just check it hasn't jumped completely to the next item.
    expect(scrollable.position.pixels, lessThan(offset2 + 100));

    // End pan.
    await touchGesture.up();
    await tester.pumpAndSettle();

    // Wait for interval.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Should have auto-scrolled again.
    expect(scrollable.position.pixels, greaterThan(offset2 + 50));
  });
}
