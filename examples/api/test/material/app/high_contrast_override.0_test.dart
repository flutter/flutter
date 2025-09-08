// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/app/high_contrast_override.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp high contrast override affects theme selection', (WidgetTester tester) async {
    await tester.pumpWidget(const example.HighContrastOverrideExampleApp());
    await tester.pumpAndSettle();

    // Initially high contrast should be disabled
    expect(find.text('High contrast is disabled'), findsOneWidget);
    
    // Get the initial theme data (should be standard theme)
    final BuildContext context = tester.element(find.byType(Scaffold));
    final ThemeData initialTheme = Theme.of(context);
    
    // Tap the button to enable high contrast
    await tester.tap(find.text('Enable High Contrast'));
    await tester.pumpAndSettle();
    
    // Now high contrast should be enabled
    expect(find.text('High contrast is enabled'), findsOneWidget);
    
    // Get the updated theme data (should be high contrast theme)
    final BuildContext newContext = tester.element(find.byType(Scaffold));
    final ThemeData newTheme = Theme.of(newContext);
    
    // Verify that the theme actually changed to high contrast version
    // The high contrast theme should have different color scheme due to contrastLevel: 1.0
    expect(newTheme.colorScheme.primary, isNot(equals(initialTheme.colorScheme.primary)));
    
    // Verify MediaQuery high contrast value is properly set
    expect(MediaQuery.highContrastOf(newContext), isTrue);
    
    // Tap again to disable high contrast
    await tester.tap(find.text('Disable High Contrast'));
    await tester.pumpAndSettle();
    
    // Should be back to disabled state
    expect(find.text('High contrast is disabled'), findsOneWidget);
    
    // Verify MediaQuery high contrast value is back to false
    final BuildContext finalContext = tester.element(find.byType(Scaffold));
    expect(MediaQuery.highContrastOf(finalContext), isFalse);
    
    // Verify theme is back to standard
    final ThemeData finalTheme = Theme.of(finalContext);
    expect(finalTheme.colorScheme.primary, equals(initialTheme.colorScheme.primary));
  });

  testWidgets('MediaQuery high contrast override affects MaterialApp theme selection', (WidgetTester tester) async {
    // Test that the MediaQuery override actually affects the MaterialApp theme selection
    bool highContrastValue = false;
    late ThemeData capturedTheme;
    
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MediaQuery(
            data: MediaQueryData.fromView(View.of(context)).copyWith(
              highContrast: highContrastValue,
            ),
            child: MaterialApp(
              theme: ThemeData.light(),
              highContrastTheme: ThemeData.light().copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.red, // Different color to verify theme change
                  brightness: Brightness.light,
                  contrastLevel: 1.0,
                ),
              ),
              home: Builder(
                builder: (BuildContext context) {
                  capturedTheme = Theme.of(context);
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          highContrastValue = !highContrastValue;
                        });
                      },
                      child: Text('High contrast is ${highContrastValue ? "enabled" : "disabled"}'),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Capture initial theme (standard theme)
    final ThemeData standardTheme = capturedTheme;
    expect(find.text('High contrast is disabled'), findsOneWidget);
    
    // Toggle high contrast
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    
    // Capture high contrast theme
    final ThemeData highContrastTheme = capturedTheme;
    expect(find.text('High contrast is enabled'), findsOneWidget);
    
    // Verify that the themes are actually different (theme selection worked)
    expect(standardTheme.colorScheme.primary, isNot(equals(highContrastTheme.colorScheme.primary)));
    
    // Verify MediaQuery values
    final BuildContext context = tester.element(find.byType(Scaffold));
    expect(MediaQuery.highContrastOf(context), isTrue);
    
    // Toggle back to standard
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    
    // Verify we're back to standard theme
    final ThemeData finalTheme = capturedTheme;
    expect(finalTheme.colorScheme.primary, equals(standardTheme.colorScheme.primary));
    expect(MediaQuery.highContrastOf(context), isFalse);
  });
}
