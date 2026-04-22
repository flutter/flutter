// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/toggle_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('toggle buttons can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, ToggleButtonsUseCase());
    expect(find.byType(ToggleButtons), findsOneWidget);
  });

  testWidgets('toggle buttons can toggle state', (WidgetTester tester) async {
    await pumpsUseCase(tester, ToggleButtonsUseCase());
    final Finder findBold = find.bySemanticsLabel('Bold');
    expect(findBold, findsOneWidget);

    final Finder findToggleButtons = find.byType(ToggleButtons);
    expect(findToggleButtons, findsOneWidget);

    ToggleButtons widget = tester.widget(findToggleButtons);
    expect(widget.isSelected[0], isTrue);

    await tester.tap(findBold);
    await tester.pumpAndSettle();

    widget = tester.widget(findToggleButtons);
    expect(widget.isSelected[0], isFalse);
  });
}
