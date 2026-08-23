// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
// Import the sample app.
import 'package:flutter_api_samples/cupertino/menu_anchor/menu_anchor.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Menu opens and displays a Menu Item', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.CupertinoMenuAnchorApp());

    // The button should be present with initial label.
    expect(
      find.byIcon(CupertinoIcons.ellipsis_vertical_circle),
      findsOneWidget,
    );

    // Tap the button to open the menu.
    await tester.tap(find.byIcon(CupertinoIcons.ellipsis_vertical_circle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Menu item should be visible.
    expect(find.text('Menu Item'), findsOneWidget);
    expect(find.text('Subtitle'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.star), findsOneWidget);
  });

  testWidgets('Menu toggles open and close', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CupertinoMenuAnchorApp());

    await tester.tap(find.byIcon(CupertinoIcons.ellipsis_vertical_circle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Menu Item'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.ellipsis_vertical_circle));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Menu Item'), findsNothing);
  });
}
