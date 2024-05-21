// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/snack_bar/snack_bar.2.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows correct static elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SnackBarExampleApp(),
    );

    expect(find.byType(SnackBar), findsNothing);
    expect(find.widgetWithText(AppBar, 'SnackBar Sample'), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Show Snackbar'), findsOneWidget);
    expect(find.text('Behavior'), findsOneWidget);
    expect(find.text('Fixed'), findsOneWidget);
    expect(find.text('Floating'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'Include close Icon'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'Multi Line Text'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'Include Action'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'Long Action Label'), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(Slider), 30);
    expect(find.text('Action new-line overflow threshold'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('Applies configurations to snackbar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SnackBarExampleApp(),
    );
    // Test default configuration
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Single Line Snack Bar'), findsNothing);
    expect(find.textContaining('spans across multiple lines'), findsNothing);
    expect(find.text('Long Action Text'), findsNothing);
    expect(find.text('Action'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.tap(find.text('Show Snackbar'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Single Line Snack Bar'), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(tester
      .widget<SnackBar>(find.byType(SnackBar))
      .behavior,
      SnackBarBehavior.floating);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    // Test options
    await tester.tap(find.text('Fixed'));
    await tester.tap(find.text('Multi Line Text'));
    await tester.tap(find.text('Long Action Label'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Snackbar'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('spans across multiple lines'), findsOneWidget);
    expect(find.text('Long Action Text'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(tester
      .widget<SnackBar>(find.byType(SnackBar))
      .behavior,
      SnackBarBehavior.fixed);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    // Test Action new-line overflow threshold
    // First moves the slider to the value null
    await tester.scrollUntilVisible(find.byType(Slider), 30);
    TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Slider)));
    await gesture.moveTo(tester.getBottomLeft(find.byType(Slider)));
    await gesture.up();
    await tester.tapAt(tester.getBottomLeft(find.byType(Slider)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Snackbar'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    final Size snackBarSize = tester.getSize(find.byType(SnackBar));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    gesture = await tester.startGesture(tester.getCenter(find.byType(Slider)));
    await gesture.moveTo(tester.getTopRight(find.byType(Slider)));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Snackbar'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.getSize(find.byType(SnackBar)).height,
      lessThan(snackBarSize.height));

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Test removing the action and close icon
    await tester.tap(find.text('Include close Icon'));
    await tester.tap(find.text('Include Action'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Snackbar'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('spans across multiple lines'), findsOneWidget);
    expect(find.byType(SnackBarAction), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('Disable unusable elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SnackBarExampleApp(),
    );

    expect(find.text('Long Action Label'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.ancestor(
      of: find.text('Long Action Label'),
      matching: find.byType(SwitchListTile),
    )).onChanged, isNotNull);

    await tester.tap(find.text('Include Action'));
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(find.ancestor(
      of: find.text('Long Action Label'),
      matching: find.byType(SwitchListTile),
    )).onChanged, isNull);
  });
}
