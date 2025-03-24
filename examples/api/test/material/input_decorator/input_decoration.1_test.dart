// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/input_decorator/input_decoration.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TextField is decorated', (WidgetTester tester) async {
    await tester.pumpWidget(const example.InputDecorationExampleApp());
    expect(find.text('InputDecoration Sample'), findsOneWidget);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Hint Text'), findsOneWidget);

    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration?.contentPadding,
      EdgeInsets.zero,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration?.border,
      const OutlineInputBorder(),
    );
  });
}
