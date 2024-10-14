// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/material_state/material_state_property.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Finder findForegroundColor(Color color) {
    return find.byWidgetPredicate((Widget widget) {
      if (widget is! Material) {
        return false;
      }
      final TextStyle? textStyle = widget.textStyle;
      return textStyle?.color == color;
    });
  }

  testWidgets(
    'The foreground color of the TextButton should be red by default',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const example.MaterialStatePropertyExampleApp(),
      );

      expect(findForegroundColor(Colors.red), findsOne);
    },
  );

  testWidgets(
    'The foreground color of the TextButton should blue when hovered',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const example.MaterialStatePropertyExampleApp(),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(find.byType(TextButton)));
      await tester.pump();

      expect(findForegroundColor(Colors.blue), findsOne);
    },
  );
}
