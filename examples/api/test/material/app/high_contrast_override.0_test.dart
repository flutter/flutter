// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/material/app/high_contrast_override.0.dart';

void main() {
  testWidgets('High contrast override example test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HighContrastOverrideExample());

    // Verify that the app loads with expected elements
    expect(find.text('High Contrast Override Demo'), findsOneWidget);
    expect(find.text('Force High Contrast'), findsOneWidget);
    expect(find.text('High Contrast Status'), findsOneWidget);

    // Find the switch and verify initial state
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    
    // Initially high contrast should be false
    expect(find.textContaining('Override Active: false'), findsOneWidget);

    // Tap the switch to enable high contrast override
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verify that override is now active
    expect(find.textContaining('Override Active: true'), findsOneWidget);
    expect(find.textContaining('Effective High Contrast: true'), findsOneWidget);

    // Verify UI elements are still present
    expect(find.text('Elevated Button'), findsOneWidget);
    expect(find.text('Filled Button'), findsOneWidget);
    expect(find.text('Outlined Button'), findsOneWidget);
  });

  testWidgets('MediaQuery override affects theme selection', (WidgetTester tester) async {
    // Test that MediaQuery override actually works
    bool capturedHighContrast = false;
    
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              highContrast: true, // Force high contrast
            ),
            child: Builder(
              builder: (context) {
                capturedHighContrast = MediaQuery.highContrastOf(context);
                return const Scaffold(
                  body: Center(child: Text('Test')),
                );
              },
            ),
          );
        },
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Verify MediaQuery override works
    expect(capturedHighContrast, isTrue);
    expect(find.text('Test'), findsOneWidget);
  });
}
