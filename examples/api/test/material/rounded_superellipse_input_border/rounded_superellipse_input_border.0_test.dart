// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/rounded_superellipse_input_border/rounded_superellipse_input_border.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RoundedSuperellipseInputBorder example', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ExampleApp());

    // Verify that we have three TextField widgets with RoundedSuperellipseInputBorder
    expect(find.byType(TextField), findsNWidgets(3));

    // Verify the labels are present
    expect(find.text('Rounded Superellipse Border'), findsOneWidget);
    expect(find.text('Filled with Superellipse Border'), findsOneWidget);
    expect(find.text('Custom Radius'), findsOneWidget);

    // Verify that the widgets render without errors
    expect(tester.takeException(), isNull);
  });
}
