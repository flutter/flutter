// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/widget_state/widget_state_property.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Color?> getTextColor(WidgetTester tester) async {
    final BuildContext context = tester.element(find.text('TextButton'));
    final TextStyle textStyle = DefaultTextStyle.of(context).style;

    return textStyle.color;
  }

  testWidgets('displays red colored text by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.WidgetStatePropertyExampleApp(),
    );

    expect(
      await getTextColor(tester),
      equals(Colors.red),
    );
  });

  testWidgets('displays blue colored text when button is hovered', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.WidgetStatePropertyExampleApp(),
    );

    expect(
      await getTextColor(tester),
      equals(Colors.red),
    );

    // Hover over the TextButton.
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(tester.getCenter(find.byType(TextButton)));

    await tester.pumpAndSettle();

    expect(
      await getTextColor(tester),
      equals(Colors.blue),
    );
  });

  testWidgets('displays blue colored text when button is pressed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.WidgetStatePropertyExampleApp(),
    );

    expect(
      await getTextColor(tester),
      equals(Colors.red),
    );

    // Press on the TextButton.
    final TestGesture gesture = await tester.createGesture();
    await gesture.down(tester.getCenter(find.byType(TextButton)));

    await tester.pumpAndSettle();

    expect(
      await getTextColor(tester),
      equals(Colors.blue),
    );
  });

  testWidgets('displays blue colored text when button is focused', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.WidgetStatePropertyExampleApp(),
    );

    expect(
      await getTextColor(tester),
      equals(Colors.red),
    );

    // Focus on the TextButton.
    FocusScope.of(tester.element(find.byType(TextButton))).nextFocus();

    await tester.pumpAndSettle();

    expect(
      await getTextColor(tester),
      equals(Colors.blueAccent),
    );
  });
}
