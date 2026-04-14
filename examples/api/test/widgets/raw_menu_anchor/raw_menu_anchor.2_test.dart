// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/raw_menu_anchor/raw_menu_anchor.2.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Menu opens and closes', (WidgetTester tester) async {
    await tester.pumpWidget(const example.RawMenuAnchorAnimationApp());

    // Open the menu.
    await tester.tap(find.text('Open'));
    await tester.pump();

    final Finder message = find
        .ancestor(
          of: find.textContaining('ANIMATION STATUS:'),
          matching: find.byType(Material),
        )
        .first;

    expect(find.text('Open'), findsNothing);
    expect(find.text('Close'), findsOneWidget);
    expect(message, findsOneWidget);
    expect(
      tester.getRect(message),
      const Rect.fromLTRB(400.0, 328.0, 400.0, 328.0),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester.getRect(message),
      rectMoreOrLessEquals(
        const Rect.fromLTRB(325.0, 328.0, 475.0, 528.0),
        epsilon: 0.1,
      ),
    );

    await tester.pump(const Duration(milliseconds: 1100));

    expect(
      tester.getRect(message),
      rectMoreOrLessEquals(
        const Rect.fromLTRB(325.0, 328.0, 475.0, 528.0),
        epsilon: 0.1,
      ),
    );

    // Close the menu.
    await tester.tap(find.text('Close'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 150));

    expect(
      tester.getRect(message),
      rectMoreOrLessEquals(
        const Rect.fromLTRB(362.5, 353.0, 437.5, 403.0),
        epsilon: 0.1,
      ),
    );

    await tester.pump(const Duration(milliseconds: 920));

    expect(find.widgetWithText(Material, 'ANIMATION STATUS:'), findsNothing);
    expect(find.text('Close'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('Panel text contains the animation status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.RawMenuAnchorAnimationApp());

    // Open the menu.
    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(find.textContaining('forward'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));

    expect(find.textContaining('completed'), findsOneWidget);

    await tester.tapAt(Offset.zero);
    await tester.pump();

    expect(find.textContaining('reverse'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 920));

    // The panel text should be removed when the animation is dismissed.
    expect(find.textContaining('reverse'), findsNothing);
  });

  testWidgets('Menu closes on outside tap', (WidgetTester tester) async {
    await tester.pumpWidget(const example.RawMenuAnchorAnimationApp());

    // Open the menu.
    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(find.text('Close'), findsOneWidget);

    // Tap outside the menu to close it.
    await tester.tapAt(Offset.zero);
    await tester.pump();

    expect(find.text('Close'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });
}
