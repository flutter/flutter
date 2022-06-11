// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/bottom_navigation_bar/bottom_navigation_bar.2.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BottomNavigationBar Updates Screen Content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MyApp(),
    );

    expect(find.widgetWithText(AppBar, 'BottomNavigationBar Sample'),
        findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.widgetWithText(Center, 'Item 0'), findsOneWidget);

    await tester.scrollUntilVisible(
        find.widgetWithText(Center, 'Item 49'), 100);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Center, 'Item 49'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_circle_up));
    await tester.pumpAndSettle();
    final Scrollable bodyScrollView = tester.widget(find.byType(Scrollable));
    expect(bodyScrollView.controller?.offset, 0.0);

    final Finder textFinder = find.text('Item 0');
    expect(
        tester.widget<Text>(textFinder).style?.fontWeight, FontWeight.normal);

    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(textFinder).style?.fontWeight, FontWeight.bold);

    await tester.tap(find.byIcon(Icons.format_clear));
    await tester.pumpAndSettle();
    expect(
        tester.widget<Text>(textFinder).style?.fontWeight, FontWeight.normal);
  });
}
