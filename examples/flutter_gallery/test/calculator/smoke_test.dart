// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/calculator_demo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  if (binding is LiveTestWidgetsFlutterBinding)
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  // We press the "1" and the "2" buttons and check that the display
  // reads "12".
  testWidgets('Flutter calculator app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CalculatorDemo()));

    final Finder oneButton = find.widgetWithText(InkResponse, '1');
    expect(oneButton, findsOneWidget);

    final Finder twoButton = find.widgetWithText(InkResponse, '2');
    expect(twoButton, findsOneWidget);

    await tester.tap(oneButton);
    await tester.pump();
    await tester.tap(twoButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait until it has finished.

    final Finder display = find.widgetWithText(Expanded, '12');
    expect(display, findsOneWidget);
  });
}
