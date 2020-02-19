// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_catalog/app_bar_bottom.dart' as app_bar_bottom_sample;

final int choiceCount = app_bar_bottom_sample.choices.length;
IconData iconAt(int index) => app_bar_bottom_sample.choices[index].icon;

Finder findChoiceCard(IconData icon) {
  return find.descendant(of: find.byType(Card), matching: find.byIcon(icon));
}

void main() {
  testWidgets('app_bar_bottom sample smoke test', (WidgetTester tester) async {
    app_bar_bottom_sample.main();
    await tester.pump();

    // Cycle through the choices using the forward and backwards arrows.

    final Finder nextChoice = find.byTooltip('Next choice');
    for (int i = 0; i < choiceCount; i += 1) {
      expect(findChoiceCard(iconAt(i)), findsOneWidget);
      await tester.tap(nextChoice);
      await tester.pumpAndSettle();
    }

    final Finder previousChoice = find.byTooltip('Previous choice');
    for (int i = choiceCount - 1; i >= 0; i -= 1) {
      expect(findChoiceCard(iconAt(i)), findsOneWidget);
      await tester.tap(previousChoice);
      await tester.pumpAndSettle();
    }
  });
}
