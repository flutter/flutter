// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('dialog can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, DialogUseCase());
    expect(find.text('Show Dialog'), findsOneWidget);

    Future<void> invokeDialog() async {
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      expect(find.text('This is a typical dialog.'), findsOneWidget);
    }

    await invokeDialog();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('This is a typical dialog.'), findsNothing);

    await invokeDialog();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('This is a typical dialog.'), findsNothing);
  });

  testWidgets('ok button has autofocus when dialog opens', (WidgetTester tester) async {
    await pumpsUseCase(tester, DialogUseCase());

    Future<void> invokeDialog() async {
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
    }

    await invokeDialog();
    final Finder okButton = find.byKey(const Key('OK Button'));
    expect((okButton.evaluate().single.widget as TextButton).autofocus, true);
  });

  testWidgets('dialog has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, DialogUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('Dialog Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });
}
