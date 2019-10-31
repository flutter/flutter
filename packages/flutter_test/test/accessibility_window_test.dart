// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Fails correctly with configured screen size - small', (WidgetTester tester) async {
    tester.binding.window.devicePixelRatioTestValue = 1.2;
    tester.binding.window.physicalSizeTestValue = const Size(250, 300);

    final RaisedButton invalidButton = RaisedButton(
      onPressed: () {},
      child: const Text('Button'),
      textColor: Colors.orange,
      color: Colors.orangeAccent,
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: invalidButton)));

    final Evaluation result = await textContrastGuideline.evaluate(tester);
    expect(result.passed, false);
  });

  testWidgets('Fails correctly with configured screen size - large', (WidgetTester tester) async {
    tester.binding.window.devicePixelRatioTestValue = 4.2;
    tester.binding.window.physicalSizeTestValue = const Size(2500, 3000);

    final RaisedButton invalidButton = RaisedButton(
      onPressed: () {},
      child: const Text('Button'),
      textColor: Colors.orange,
      color: Colors.orangeAccent,
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: invalidButton)));

    final Evaluation result = await textContrastGuideline.evaluate(tester);
    expect(result.passed, false);
  });
}