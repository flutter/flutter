// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/implicit_animations/animated_positioned.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'AnimatedPositioned animates on tap',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const example.AnimatedPositionedExampleApp(),
      );

      Positioned positioned = tester.widget(
        find.descendant(
          of: find.byType(AnimatedPositioned),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.width, 50.0);
      expect(positioned.height, 200.0);
      expect(positioned.top, 150.0);

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      positioned = tester.widget(
        find.descendant(
          of: find.byType(AnimatedPositioned),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.width, 50.0);
      expect(positioned.height, 200.0);
      expect(positioned.top, 150.0);

      // Advance animation to the end by the 2-second duration specified in
      // the example app.
      await tester.pump(const Duration(seconds: 2));

      positioned = tester.widget(
        find.descendant(
          of: find.byType(AnimatedPositioned),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.width, 200.0);
      expect(positioned.height, 50.0);
      expect(positioned.top, 50.0);
    },
  );
}
