// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/input_decorator/input_decoration.floating_label_style_error.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InputDecorator label uses errorColor', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MyApp(),
    );

    tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    final AnimatedDefaultTextStyle label = tester.widget(find.byType(AnimatedDefaultTextStyle).last);
    expect(label.style.color, Colors.red);
  });
}
