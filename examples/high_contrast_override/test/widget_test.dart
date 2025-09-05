// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:high_contrast_override/main.dart';

void main() {
  testWidgets('High contrast override example smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HighContrastOverrideExample());
    await tester.pumpAndSettle();

    // Verify that key elements are present
    expect(find.text('High Contrast Override Demo'), findsOneWidget);
    expect(find.text('Force High Contrast'), findsOneWidget);
    expect(find.text('High Contrast Status'), findsOneWidget);
    expect(find.text('System High Contrast'), findsOneWidget);
    expect(find.text('Override Active'), findsOneWidget);
    expect(find.text('Effective High Contrast'), findsOneWidget);
    
    // Verify control elements
    expect(find.text('Controls'), findsOneWidget);
    expect(find.text('Sample UI Elements'), findsOneWidget);
    expect(find.text('Elevated Button'), findsOneWidget);
    expect(find.text('Filled Button'), findsOneWidget);
    expect(find.text('Outlined Button'), findsOneWidget);
    
    // Test basic interaction - toggle switch
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    
    // Tap the switch to toggle high contrast
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    
    // The app should still be working after toggle
    expect(find.text('High Contrast Override Demo'), findsOneWidget);
  });
  
  testWidgets('MediaQuery override functionality test', (WidgetTester tester) async {
    // Test that our MediaQuery override actually works
    bool? capturedHighContrast;
    
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
