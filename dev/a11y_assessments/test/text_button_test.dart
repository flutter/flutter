// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('text button can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, TextButtonUseCase());
    final SemanticsFinder finder = find.semantics.byLabel('Press me');
    expect(
      finder.at(0),
      matchesSemantics(
        hasTapAction: true,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
      ),
    );
  });

  testWidgets('text button must not contain "button" in their text', (WidgetTester tester) async {
    await pumpsUseCase(tester, TextButtonUseCase());
    final List<Text> texts = tester.widgetList<Text>(
      find.descendant(of: find.byType(TextButton), matching: find.byType(Text)),
    ).toList();
    for (final Text text in texts) {
      expect(text.data!.contains('button'), isFalse);
    }
  });
}
