// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('switch use case renders switch widgets and toggles state', (
    WidgetTester tester,
  ) async {
    await pumpsUseCase(tester, SwitchUseCase());
    expect(find.byType(Switch), findsNWidgets(2));

    Switch switchWidget = tester.widget(find.byType(Switch).first);
    expect(switchWidget.value, isFalse);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    switchWidget = tester.widget(find.byType(Switch).first);
    expect(switchWidget.value, isTrue);
  });
}
