// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const kOrange = Color(0xFFFF9800);
  const kOrangeAccent = Color(0xFFFFAB40);

  testWidgets('Fails correctly with configured screen size - small', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.2;
    tester.view.physicalSize = const Size(250, 300);
    addTearDown(tester.view.reset);

    const Widget invalidButton = ColoredBox(
      color: kOrangeAccent,
      child: Text('Button', style: TextStyle(color: kOrange)),
    );
    await tester.pumpWidget(const TestWidgetsApp(home: SizedBox.expand(child: invalidButton)));

    final Evaluation result = await textContrastGuideline.evaluate(tester);
    expect(result.passed, false);
  });

  testWidgets('Fails correctly with configured screen size - large', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 4.2;
    tester.view.physicalSize = const Size(2500, 3000);
    addTearDown(tester.view.reset);

    const Widget invalidButton = ColoredBox(
      color: kOrangeAccent,
      child: Text('Button', style: TextStyle(color: kOrange)),
    );
    await tester.pumpWidget(const TestWidgetsApp(home: SizedBox.expand(child: invalidButton)));

    final Evaluation result = await textContrastGuideline.evaluate(tester);
    expect(result.passed, false);
  });
}
