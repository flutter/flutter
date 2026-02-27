// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/cupertino/expansion_tile/cupertino_expansion_tile.0.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CupertinoExpansionTile transition modes test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CupertinoExpansionTileApp());

    // Check initial labels.
    expect(find.text('Fade Transition - Tap to expand'), findsOneWidget);
    expect(find.text('Scroll Transition - Tap to expand'), findsOneWidget);

    // Tap to expand the Fade Transition tile.
    await tester.tap(find.text('Fade Transition - Tap to expand'));
    await tester.pumpAndSettle();

    // Check Fade is expanded.
    expect(find.text('Fade Transition - Collapse me'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap to collapse the Fade Transition tile.
    await tester.tap(find.text('Fade Transition - Collapse me'));
    await tester.pumpAndSettle();

    // Ensure Fade is collapsed.
    expect(find.text('Profile'), findsNothing);
    expect(find.text('Messages'), findsNothing);
    expect(find.text('Settings'), findsNothing);

    // Tap to expand Scroll Transition tile.
    await tester.tap(find.text('Scroll Transition - Tap to expand'));
    await tester.pumpAndSettle();

    // Check Scroll is expanded.
    expect(find.text('Scroll Transition - Collapse me'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap to collapse the Scroll Transition tile.
    await tester.tap(find.text('Scroll Transition - Collapse me'));
    await tester.pumpAndSettle();

    // Ensure Scroll is collapsed.
    expect(find.text('Profile'), findsNothing);
    expect(find.text('Messages'), findsNothing);
    expect(find.text('Settings'), findsNothing);
  });
}
