// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/main.dart';
import 'package:a11y_assessments/use_cases/date_picker.dart';
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

      // After checking the guideline for the main page,
      // iterate through all tappable semantic nodes on the current screen.
      // Tap each one (excluding the back button) to navigate deeper into the app
      // and re-run the accessibility checks. This assumes that tapping a target
      // does not remove other tappable targets from the screen, which is true
      // for the a11y assessment app's current structure.
      final SemanticsFinder tappables = find.semantics.byAction(SemanticsAction.tap);
      final int tappableCount = tappables.evaluate().length;

      for (int i = 0; i < tappableCount; i++) {
        final FinderBase<SemanticsNode> tappable = tappables.at(i);
        final SemanticsNode node = tappable.evaluate().first;

        // We do not want to tap the back button, as that will pop the page
        // and disrupt the current test flow.
        if (node.tooltip == 'Back') {
          continue;
        }
        tester.semantics.tap(tappable);
        await tester.pumpAndSettle();

        // Re-check the accessibility guidelines after the tap action.
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        // The DatePicker use case has known issues with tap target sizes
        // So we skip these checks for this use case .
        if (useCase.name != DatePickerUseCase().name) {
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        }
      }
    });
  }
}
