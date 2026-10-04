// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/widgets/tap_region/tap_region.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TapRegion group shows initial status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.TapRegionGroupExampleApp());

    expect(find.text('Box 1: -'), findsOneWidget);
    expect(find.text('Box 2: -'), findsOneWidget);
  });

  testWidgets('Tapping either box updates both statuses to inside', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.TapRegionGroupExampleApp());

    // Tap Box 1: both boxes report 'inside' because they share a groupId.
    await tester.tap(find.byType(TapRegion).first);
    await tester.pump();

    expect(find.text('Box 1: inside'), findsOneWidget);
    expect(find.text('Box 2: inside'), findsOneWidget);

    // Tap outside: both boxes report 'outside'.
    await tester.tapAt(Offset.zero);
    await tester.pump();

    expect(find.text('Box 1: outside'), findsOneWidget);
    expect(find.text('Box 2: outside'), findsOneWidget);

    // Tap Box 2: both boxes report 'inside' again.
    await tester.tap(find.byType(TapRegion).last);
    await tester.pump();

    expect(find.text('Box 1: inside'), findsOneWidget);
    expect(find.text('Box 2: inside'), findsOneWidget);
  });
}
