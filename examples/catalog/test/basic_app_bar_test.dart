// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_catalog/basic_app_bar.dart' as basic_app_bar_sample;

int choiceCount = basic_app_bar_sample.choices.length;
IconData iconAt(int index) => basic_app_bar_sample.choices[index].icon;
String titleAt(int index) => basic_app_bar_sample.choices[index].title;

Finder findAppBarIcon(IconData icon) {
  return find.descendant(of: find.byType(AppBar), matching: find.byIcon(icon));
}

Finder findChoiceCard(IconData icon) {
  return find.descendant(of: find.byType(Card), matching: find.byIcon(icon));
}

void main() {
  testWidgets('basic_app_bar sample smoke test', (WidgetTester tester) async {
    basic_app_bar_sample.main();
    await tester.pump();

    // Tap on the two action buttons and all of the overflow menu items.
    // Verify that a Card with the expected icon appears.

    await tester.tap(findAppBarIcon(iconAt(0)));
    await tester.pumpAndSettle();
    expect(findChoiceCard(iconAt(0)), findsOneWidget);

    await tester.tap(findAppBarIcon(iconAt(1)));
    await tester.pumpAndSettle();
    expect(findChoiceCard(iconAt(1)), findsOneWidget);

    for (int i = 2; i < choiceCount; i += 1) {
      await tester.tap(findAppBarIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(titleAt(i)));
      await tester.pumpAndSettle();
      expect(findChoiceCard(iconAt(i)), findsOneWidget);
    }
  });
}
