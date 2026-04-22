// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/segmented_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('segmented button can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, SegmentedButtonUseCase());
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
  });

  testWidgets('segmented button can change selection', (WidgetTester tester) async {
    await pumpsUseCase(tester, SegmentedButtonUseCase());

    final Finder findSegmentedButton = find.byType(SegmentedButton<String>);
    expect(findSegmentedButton, findsOneWidget);

    SegmentedButton<String> widget = tester.widget(findSegmentedButton);
    expect(widget.selected, contains('Day'));

    final Finder findWeekSegment = find.text('Week');
    expect(findWeekSegment, findsOneWidget);

    await tester.tap(findWeekSegment);
    await tester.pumpAndSettle();

    widget = tester.widget(findSegmentedButton);
    expect(widget.selected, contains('Week'));
  });
}
