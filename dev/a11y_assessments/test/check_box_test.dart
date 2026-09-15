// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/check_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('check box use case renders check boxes and toggles state', (
    WidgetTester tester,
  ) async {
    await pumpsUseCase(tester, CheckBoxUseCase());
    expect(find.byType(Checkbox), findsNWidgets(2));

    Checkbox checkbox = tester.widget(find.byType(Checkbox).first);
    expect(checkbox.value, isFalse);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    checkbox = tester.widget(find.byType(Checkbox).first);
    expect(checkbox.value, isTrue);
  });
}
