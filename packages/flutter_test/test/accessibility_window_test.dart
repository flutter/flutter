// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Fails correctly with configured screen size - small', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.2;
    tester.view.physicalSize = const Size(250, 300);
    addTearDown(tester.view.reset);

    final Widget invalidButton = ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.orange,
        backgroundColor: Colors.orangeAccent,
      ),
      child: const Text('Button'),
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: invalidButton)));

    final Evaluation result = await textContrastGuideline.evaluate(tester);
    expect(result.passed, false);
  });

  testWidgets('Fails correctly with configured screen size - large', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 4.2;
    tester.view.physicalSize = const Size(2500, 3000);
    addTearDown(tester.view.reset);

    final Widget invalidButton = ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.orange,
        backgroundColor: Colors.orangeAccent,
      ),
      child: const Text('Button'),
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: invalidButton)));

    final Evaluation result = await textContrastGuideline.evaluate(tester);
    expect(result.passed, false);
  });
}
