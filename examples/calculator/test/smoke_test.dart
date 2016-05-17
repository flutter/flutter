// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:calculator/main.dart' as calculator;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

void main() {
  // We press the "1" and the "2" buttons and check that the display
  // reads "12".
  testWidgets('Flutter calculator app smoke test', (WidgetTester tester)  {
    calculator.main(); // builds the app and schedules a frame but doesn't trigger one
    tester.flushMicrotasks(); // see https://github.com/flutter/flutter/issues/1865
    tester.pump(); // see https://github.com/flutter/flutter/issues/1865
    tester.pump(); // triggers a frame

    Finder oneButton = find.widgetWithText(InkResponse, '1');
    expect(oneButton, findsOneWidget);

    Finder twoButton = find.widgetWithText(InkResponse, '2');
    expect(twoButton, findsOneWidget);

    tester.tap(oneButton);
    tester.pump();
    tester.tap(twoButton);
    tester.pump();
    tester.pump(const Duration(seconds: 1)); // Wait until it has finished.

    Finder display = find.widgetWithText(Flexible, '12');
    expect(display, findsOneWidget);
  });
}
