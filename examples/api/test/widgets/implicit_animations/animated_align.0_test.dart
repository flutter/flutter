// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/implicit_animations/animated_align.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AnimatedAlign animates on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.AnimatedAlignExampleApp(),
    );

    Align align = tester.widget(
      find.descendant(
        of: find.byType(AnimatedAlign),
        matching: find.byType(Align),
      ),
    );
    expect(align.alignment, Alignment.bottomLeft);

    await tester.tap(find.byType(AnimatedAlign));
    await tester.pump();

    align = tester.widget(
      find.descendant(
        of: find.byType(AnimatedAlign),
        matching: find.byType(Align),
      ),
    );
    expect(align.alignment, Alignment.bottomLeft);

    // Advance animation to the end by the 1-second duration specified in
    // the example app.
    await tester.pump(const Duration(seconds: 1));

    align = tester.widget(
      find.descendant(
        of: find.byType(AnimatedAlign),
        matching: find.byType(Align),
      ),
    );
    expect(align.alignment, Alignment.topRight);
  });
}
