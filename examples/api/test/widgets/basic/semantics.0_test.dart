// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_api_samples/widgets/basic/semantics.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Finder semanticsButton() {
    return find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics && widget.properties.button == true,
    );
  }

  testWidgets('custom button has button semantics', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const example.SemanticsExampleApp());

      expect(
        tester.getSemantics(semanticsButton()),
        matchesSemantics(
          label: 'Count: 0',
          hasTapAction: true,
          hasFocusAction: true,
          isButton: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('custom button responds to tap and keyboard activation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.SemanticsExampleApp());

    expect(find.text('Count: 0'), findsOneWidget);

    await tester.tap(find.text('Count: 0'));
    await tester.pump();

    expect(find.text('Count: 1'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.text('Count: 2'), findsOneWidget);
  });
}
