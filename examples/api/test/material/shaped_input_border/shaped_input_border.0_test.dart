// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/shaped_input_border/shaped_input_border.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ShapedInputBorder example', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ExampleApp());

    // Verify that we have four TextField widgets with different ShapedInputBorder shapes
    expect(find.byType(TextField), findsNWidgets(4));

    // Verify the labels are present
    expect(find.text('Superellipse Border'), findsOneWidget);
    expect(find.text('Stadium Border'), findsOneWidget);
    expect(find.text('Beveled Border'), findsOneWidget);
    expect(find.text('Filled with Superellipse'), findsOneWidget);

    // Verify that the widgets render without errors
    expect(tester.takeException(), isNull);
  });
}
