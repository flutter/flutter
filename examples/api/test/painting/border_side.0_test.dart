// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/painting/borders/border_side.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Finds the expected TestBox', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: example.BorderSideExample(),
      ),
    );

    expect(find.byType(example.BorderSideExample), findsOneWidget);
    expect(find.byType(example.TestBox), findsNWidgets(8));
  });
}
