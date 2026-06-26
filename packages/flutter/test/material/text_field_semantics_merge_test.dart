// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('Semantics label merges with editable text field semantics', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Semantics(
            label: 'Login_email',
            textField: true,
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Email'),
            ),
          ),
        ),
      ),
    );

    final Iterable<SemanticsNode> textFields = tester.semantics
        .simulatedAccessibilityTraversal()
        .where((SemanticsNode node) => node.getSemanticsData().hasFlag(SemanticsFlag.isTextField));

    expect(textFields, hasLength(1));
    expect(
      textFields.single.getSemanticsData(),
      matchesSemantics(
        label: 'Login_email\nEmail',
        isTextField: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
        hasSetTextAction: kIsWeb,
        inputType: ui.SemanticsInputType.text,
        textDirection: TextDirection.ltr,
      ),
    );

    semantics.dispose();
  });
}
