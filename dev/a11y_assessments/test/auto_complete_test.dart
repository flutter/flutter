// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/auto_complete.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('text field label is visible', (WidgetTester tester) async {
    await pumpsUseCase(tester, AutoCompleteUseCase());
    expect(find.text('Fruit'), findsOneWidget);
  });

  testWidgets('auto complete can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, AutoCompleteUseCase());
    await tester.enterText(find.byType(TextFormField), 'a');
    await tester.pumpAndSettle();

    expect(find.text('apple'), findsOneWidget);
  });

  testWidgets('auto complete has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, AutoCompleteUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel(RegExp('AutoComplete Demo'));
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });

  testWidgets('The text is used as semantics label for the text field', (
    WidgetTester tester,
  ) async {
    await pumpsUseCase(tester, AutoCompleteUseCase());
    await tester.pumpAndSettle();

    const kOptions = <String>['apple', 'banana', 'lemon'];
    const label = 'Fruit';
    final message = 'Type below to autocomplete the following possible results: $kOptions.\n$label';

    final SemanticsNode node = tester.semantics.find(find.bySemanticsLabel(message));
    expect(node.flagsCollection.isTextField, isTrue);
  });
}
