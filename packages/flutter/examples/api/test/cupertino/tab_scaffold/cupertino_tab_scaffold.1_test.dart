// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_api_samples/cupertino/tab_scaffold/cupertino_tab_scaffold.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Re-tapping active tab pops to root and scrolls to top', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.RepeatTapTabScaffoldApp());

    // Initially at the root of the Home tab.
    expect(find.text('Tab Home'), findsOneWidget);
    expect(find.text('Push Sub-Page'), findsOneWidget);

    // 1. Push a secondary sub-page on the current tab.
    await tester.tap(find.text('Push Sub-Page'));
    await tester.pumpAndSettle();
    expect(find.text('Sub-Page'), findsOneWidget);
    expect(find.text('Deep Route Content'), findsOneWidget);

    // 2. Re-tapping the active Home tab pops back to the root of the tab.
    await tester.tap(find.byIcon(CupertinoIcons.home));
    await tester.pumpAndSettle();
    expect(find.text('Sub-Page'), findsNothing);
    expect(find.text('Push Sub-Page'), findsOneWidget);

    // 3. Scroll down the list on the root page.
    await tester.drag(find.text('Push Sub-Page'), const Offset(0.0, -400.0));
    await tester.pumpAndSettle();
    expect(find.text('Push Sub-Page'), findsNothing);

    // 4. Re-tapping the active Home tab scrolls back to the top of the list.
    await tester.tap(find.byIcon(CupertinoIcons.home));
    await tester.pumpAndSettle();
    expect(find.text('Push Sub-Page'), findsOneWidget);

    // 5. Tapping an inactive tab switches to that tab.
    await tester.tap(find.byIcon(CupertinoIcons.search));
    await tester.pumpAndSettle();
    expect(find.text('Tab Search'), findsOneWidget);
  });
}

