// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/text_field/text_field.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TextField is obscured and has "Password" as labelText', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.TextFieldExampleApp());

    expect(find.byType(TextField), findsOneWidget);

    final TextField textField = tester.widget<TextField>(
      find.byType(TextField),
    );
    expect(textField.obscureText, isTrue);
    expect(textField.decoration!.labelText, 'Password');
  });
}
