// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/text_button/text_button.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TextButton Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.TextButtonExampleApp(),
    );
    expect(find.widgetWithText(AppBar, 'TextButton Sample'), findsOneWidget);

    final Finder disabledButton = find.widgetWithText(TextButton, 'Disabled');
    expect(disabledButton, findsOneWidget);
    expect(tester.widget<TextButton>(disabledButton).onPressed, isNull);

    final Finder enabledButton = find.widgetWithText(TextButton, 'Enabled');
    expect(enabledButton, findsOneWidget);
    expect(tester.widget<TextButton>(enabledButton).onPressed, isA<VoidCallback>());

    final Finder gradientButton = find.widgetWithText(TextButton, 'Gradient');
    expect(gradientButton, findsOneWidget);
    expect(tester.widget<TextButton>(gradientButton).onPressed, isA<VoidCallback>());
  });
}
