// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/21506.
  testWidgets('InkSplash receives textDirection', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
      appBar: AppBar(title: const Text('Button Border Test')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Test'),
          onPressed: () { },
        ),
      ),
    )));
    await tester.tap(find.text('Test'));
    // start ink animation which asserts for a textDirection.
    await tester.pumpAndSettle(const Duration(milliseconds: 30));
    expect(tester.takeException(), isNull);
  });
}
