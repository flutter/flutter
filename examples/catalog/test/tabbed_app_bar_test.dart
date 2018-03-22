// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_catalog/tabbed_app_bar.dart' as tabbed_app_bar_sample;

final int choiceCount = tabbed_app_bar_sample.choices.length;
IconData iconAt(int index) => tabbed_app_bar_sample.choices[index].icon;

Finder findChoiceCard(IconData icon) {
  return find.descendant(of: find.byType(Card), matching: find.byIcon(icon));
}

Finder findTab(IconData icon) {
  return find.descendant(of: find.byType(Tab), matching: find.byIcon(icon));
}

void main() {
  testWidgets('tabbed_app_bar sample smoke test', (WidgetTester tester) async {
    tabbed_app_bar_sample.main();
    await tester.pump();

    // Tap on each tab, verify that a Card with the expected icon appears.
    for (int i = 0; i < choiceCount; i += 1) {
      await tester.tap(findTab(iconAt(i)));
      await tester.pumpAndSettle();
      expect(findChoiceCard(iconAt(i)), findsOneWidget);
      // Scroll the tabBar by about one tab width
      await tester.drag(find.byType(TabBar), const Offset(-24.0, 0.0));
      await tester.pumpAndSettle();
    }
  });
}
