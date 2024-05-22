// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/editable_text/text_editing_controller.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Forces text to be lower case and places cursor at the end of the text field', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.TextEditingControllerExampleApp(),
    );

    const String input = 'Almost Everything Is a WIDGET! 💙';

    await tester.enterText(find.byType(TextFormField), input);
    await tester.pump();

    final TextFormField textField = tester.widget(find.byType(TextFormField));
    final TextEditingController controller = textField.controller!;

    expect(find.text(input.toLowerCase()), findsOneWidget);
    expect(controller.text, input.toLowerCase());
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: input.length),
    );
  });
}
