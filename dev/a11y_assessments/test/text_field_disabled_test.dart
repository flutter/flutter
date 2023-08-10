// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/text_field_disabled.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('text field disabled can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, TextFieldDisabledUseCase());
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('abc'), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bde');
    await tester.pumpAndSettle();
    expect(find.text('abc'), findsOneWidget);
  });
}
