// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/foundation/change_notifier/change_notifier.0.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test for MyApp', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(CounterBody), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Current counter value:'), findsOneWidget);
  });

  testWidgets('Counter update', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Initial state of the counter
    expect(find.text('0'), findsOneWidget);

    // Tapping the increase button
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Counter should be at 1
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });
}
