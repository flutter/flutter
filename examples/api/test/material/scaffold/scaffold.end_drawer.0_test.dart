// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/scaffold/scaffold.end_drawer.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('The page should contain an end drawer than can be opened and closed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.EndDrawerExampleApp());

    expect(find.byType(Drawer), findsNothing);

    // Open the drawer by tapping the button at the center of the screen.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Open End Drawer'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOne);
    expect(
      tester.getCenter(find.byType(Drawer)).dx,
      greaterThan(400),
      reason: 'The drawer should be on the right side of the screen',
    );
    expect(find.text('This is the Drawer'), findsOne);

    // Close the drawer by tapping the button inside the drawer.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Close Drawer'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);

    // Open the drawer by tapping the drawer button in the app bar.
    expect(
      tester.getCenter(find.byType(EndDrawerButton)).dx,
      greaterThan(400),
      reason: 'The drawer button should be on the right side of the app bar',
    );
    await tester.tap(find.byType(EndDrawerButton));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOne);
    expect(find.text('This is the Drawer'), findsOne);

    // Close the drawer by tapping outside the drawer.
    final Rect drawerRect = tester.getRect(find.byType(Drawer));
    final Offset outsideDrawer = drawerRect.centerLeft - const Offset(50, 0);
    await tester.tapAt(outsideDrawer);
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);
  });
}
