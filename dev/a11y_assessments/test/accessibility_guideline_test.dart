// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/main.dart';
import 'package:a11y_assessments/use_cases/use_cases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final UseCase useCase in useCases) {
    testWidgets('testing accessibility guideline for ${useCase.name}', (WidgetTester tester) async {
      await tester.pumpWidget(const App());

      // Tap on the switch to show all use-cases, not just the core ones.
      await tester.tap(find.byTooltip('Show additional use cases'));
      await tester.pumpAndSettle();

      final ScrollController controller = tester
          .state<HomePageState>(find.byType(HomePage))
          .scrollController;
      while (find.byKey(Key(useCase.name)).evaluate().isEmpty) {
        controller.jumpTo(controller.offset + 400);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(Key(useCase.name)));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      // After checking the guideline for the main page.
      // Tap every tappable target except the back button to show more use cases in the app.
      // This is a simple implementation assuming the latter tappable target will not dispear after
      // tapping the former tap targets, which is true in the a11y assessment app.
      final SemanticsFinder tappables = find.semantics.byAction(SemanticsAction.tap);
      final int tappableCount = tappables.evaluate().length;

      for (int i = 0; i < tappableCount; i++) {
        final FinderBase<SemanticsNode> tappable = tappables.at(i);
        final SemanticsNode? node = tappable.evaluate().firstOrNull;

        // We do not want to tap the back button, as that will pop the page.
        if (node == null || node.tooltip == 'Back') {
          continue;
        }
        tester.semantics.tap(tappable);
        await tester.pumpAndSettle();

        // Check the guidelines again after the tap.
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        // Skip tap tagert size 48*48 check for date picker.
        if (useCase.name != 'DatePicker') {
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        }
      }
    });
  }
}
