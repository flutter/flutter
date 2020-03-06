// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:regular_integration_tests/text_editing_main.dart' as app;
import 'package:flutter/material.dart';

import 'package:e2e/e2e.dart';

void main() {
  E2EWidgetsFlutterBinding.ensureInitialized() as E2EWidgetsFlutterBinding;

  testWidgets('Focused text field creates a native input element',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // TODO(nurhan): https://github.com/flutter/flutter/issues/51885
    SystemChannels.textInput.setMockMethodCallHandler(null);

    // Focus on a TextFormField.
    final Finder finder = find.byKey(const Key('input'));
    expect(finder, findsOneWidget);
    await tester.tap(find.byKey(const Key('input')));

    // A native input element will be appended to the DOM.
    final List<Node> nodeList = document.getElementsByTagName('input');
    expect(nodeList.length, equals(1));
    final InputElement input =
        document.getElementsByTagName('input')[0] as InputElement;
    // The element's value will be the same as the textFormField's value.
    expect(input.value, 'Text1');

    // Change the value of the TextFormField.
    final TextFormField textFormField = tester.widget(finder);
    textFormField.controller.text = 'New Value';
    // DOM element's value also changes.
    expect(input.value, 'New Value');
  });
}
