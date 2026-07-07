// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/radio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('radio use case renders radio group and radio buttons and toggles state', (
    WidgetTester tester,
  ) async {
    await pumpsUseCase(tester, RadioUseCase());
    expect(find.byType(RadioGroup<Option>), findsOneWidget);
    expect(find.byType(Radio<Option>), findsNWidgets(3));

    RadioGroup<Option> radioGroup = tester.widget(find.byType(RadioGroup<Option>));
    expect(radioGroup.groupValue, Option.option1);

    await tester.tap(find.byType(Radio<Option>).at(1));
    await tester.pumpAndSettle();

    radioGroup = tester.widget(find.byType(RadioGroup<Option>));
    expect(radioGroup.groupValue, Option.option2);
  });
}
