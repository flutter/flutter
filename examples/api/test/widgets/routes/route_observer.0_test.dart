// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/routes/route_observer.0.dart' as example;
import 'package:flutter_api_samples/widgets/routes/route_observer.0.dart' show RouteObserverExample;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('RouteObserver notifies RouteAware widget', (WidgetTester tester) async {
    await tester.pumpWidget(const example.RouteObserverApp());

    // Check the initial RouteObserver logs.
    expect(find.text('didPush'), findsOneWidget);

    // Tap on the button to push a new route.
    await tester.tap(find.text('Go to next page'));
    await tester.pumpAndSettle();

    // Tap on the button to go back to the previous route.
    await tester.tap(find.text('Go back to RouteAware page'));
    await tester.pumpAndSettle();

    // Check the RouteObserver logs after the route is popped.
    expect(find.text('didPush'), findsOneWidget);
    expect(find.text('didPopNext'), findsOneWidget);

    // Tap on the button to push a new route again.
    await tester.tap(find.text('Go to next page'));
    await tester.pumpAndSettle();

    // Tap on the button to go back to the previous route again.
    await tester.tap(find.text('Go back to RouteAware page'));
    await tester.pumpAndSettle();

    // Check the RouteObserver logs after the route is popped again.
    expect(find.text('didPush'), findsOneWidget);
    expect(find.text('didPopNext'), findsNWidgets(2));

    // Check if any overflow or layout exceptions occurred.
    expect(tester.takeException(), isNull);
  });

  testWidgets('RouteObserver example renders without overflow on small screen', (
    WidgetTester tester,
  ) async {
    // Set the screen size to a smaller value (e.g., 300x600).
    tester.binding.window.physicalSizeTestValue = const Size(300, 600);
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    // Rebuild the widget tree with the new window size.
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

    // Build the RouteObserver example widget
    await tester.pumpWidget(
      const MaterialApp(
        home: RouteObserverExample(),
      ),
    );

    // Allow layout to settle
    await tester.pumpAndSettle();

    // Verify there are no layout exceptions (like RenderFlex overflow)
    expect(tester.takeException(), isNull);
  });
}
