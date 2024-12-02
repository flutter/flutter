// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/action_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('action chip can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, ActionChipUseCase());
    expect(find.byType(ActionChip), findsExactly(2));
  });

  testWidgets('action chip has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, ActionChipUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel(RegExp('ActionChip Demo'));
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });
}
