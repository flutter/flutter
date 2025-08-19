// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/main.dart';
import 'package:a11y_assessments/use_cases/use_cases.dart';
import 'package:flutter/material.dart';
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
        controller.jumpTo(controller.offset + 600);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(Key(useCase.name)));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  }
}
