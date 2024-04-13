// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/implicit_animations/sliver_animated_opacity.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'SilverAnimatedOpacity animates on FloatingActionButton tap',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const example.SliverAnimatedOpacityExampleApp(),
      );

      SliverFadeTransition fadeTransition = tester.widget(
        find.descendant(
          of: find.byType(SliverAnimatedOpacity),
          matching: find.byType(SliverFadeTransition),
        ),
      );
      expect(fadeTransition.opacity.value, 1);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      fadeTransition = tester.widget(
        find.descendant(
          of: find.byType(SliverAnimatedOpacity),
          matching: find.byType(SliverFadeTransition),
        ),
      );
      expect(fadeTransition.opacity.value, 1);

      // Advance animation to the end by the 500ms duration specified in
      // the example app.
      await tester.pump(const Duration(milliseconds: 500));

      fadeTransition = tester.widget(
        find.descendant(
          of: find.byType(SliverAnimatedOpacity),
          matching: find.byType(SliverFadeTransition),
        ),
      );
      expect(fadeTransition.opacity.value, 0);
    },
  );
}
