// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/gestures/pointer_signal_resolver/pointer_signal_resolver.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget visibility and interactions', () {
    testWidgets('Widgets visibility', (WidgetTester tester) async {
      // Build the app and trigger a frame
      await tester.pumpWidget(const example.PointerSignalResolverExampleApp());

      // There is a ColorChanger on the Stack twice
      expect(
          find.descendant(
              of: find.byType(Stack),
              matching: find.byType(example.ColorChanger)),
          findsExactly(2));

      // There is one nested ColorChanger inside the other ColorChanger
      expect(
          find.descendant(
              of: find.byType(example.ColorChanger),
              matching: find.byType(example.ColorChanger)),
          findsOneWidget);

      // There is a Switch on the Stack
      expect(
          find.descendant(
              of: find.byType(Stack), matching: find.byType(Switch)),
          findsOneWidget);
    });

    testWidgets('Widget interactions', (WidgetTester tester) async {
      // Build the app and trigger a frame
      await tester.pumpWidget(const example.PointerSignalResolverExampleApp());

      // Verify the Switch is off
      final Switch switchWidget = tester.widget(find.byType(Switch));
      expect(switchWidget.value, isFalse);

      // Toggle the Switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verify the Switch state has changed
      final Switch switchedWidget = tester.widget(find.byType(Switch));
      expect(switchedWidget.value, isTrue);
    });
  });
}
