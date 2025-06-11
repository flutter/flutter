// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/cupertino/expansion_tile/cupertino_expansion_tile.0.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CupertinoExpansionTile transition modes test', (WidgetTester tester) async {
    await tester.pumpWidget(const CupertinoExpansionTileApp());

    // Check initial labels
    expect(find.text('Fade Transition - Tap to expand'), findsOneWidget);
    expect(find.text('Scroll Transition - Tap to expand'), findsOneWidget);

    // Tap Fade Transition tile
    await tester.tap(find.text('Fade Transition - Tap to expand'));
    await tester.pumpAndSettle();

    // Check Fade is expanded
    expect(find.text('Fade Transition - Collapse me'), findsOneWidget);
    expect(find.textContaining('expanded content of the fade transition'), findsOneWidget);

    // Collapse Fade Transition tile
    await tester.tap(find.text('Fade Transition - Collapse me'));
    await tester.pumpAndSettle();

    // Ensure Fade collapsed
    expect(find.textContaining('expanded content of the fade transition'), findsNothing);

    // Tap Scroll Transition tile
    await tester.tap(find.text('Scroll Transition - Tap to expand'));
    await tester.pumpAndSettle();

    // Check Scroll is expanded
    expect(find.text('Scroll Transition - Collapse me'), findsOneWidget);
    expect(find.textContaining('expanded content of the scroll transition'), findsOneWidget);

    // Collapse Scroll Transition tile
    await tester.tap(find.text('Scroll Transition - Collapse me'));
    await tester.pumpAndSettle();

    // Ensure Scroll collapsed
    expect(find.textContaining('expanded content of the scroll transition'), findsNothing);
  });
}
