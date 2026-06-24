// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_view/main.dart' as platform_view;

void main() {
  const channel = MethodChannel('samples.flutter.io/platform_view');

  setUp(() {
    // The example invokes `switchView` on a method channel and expects an
    // integer reply. Provide a mock handler so the widget test can exercise
    // that path without a native counterpart.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall call) async {
        if (call.method == 'switchView') {
          return call.arguments as int?;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  testWidgets('PlatformView smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const platform_view.PlatformView());

    // The counter starts at zero.
    expect(find.text('Button tapped 0 times.'), findsOneWidget);
    // The app bar title is rendered.
    expect(find.text('Platform View'), findsOneWidget);
    // The Flutter label is rendered.
    expect(find.text('Flutter'), findsOneWidget);
  });

  testWidgets('tapping the FAB increments the counter', (WidgetTester tester) async {
    await tester.pumpWidget(const platform_view.PlatformView());

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('Button tapped 1 time.'), findsOneWidget);
  });

  testWidgets('tapping the continue button updates the counter from the platform response', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const platform_view.PlatformView());

    // Increment locally first so the value passed to the platform is non-zero.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('Button tapped 1 time.'), findsOneWidget);

    // The platform mock echoes back the received counter value.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('Button tapped 1 time.'), findsOneWidget);
  });
}
