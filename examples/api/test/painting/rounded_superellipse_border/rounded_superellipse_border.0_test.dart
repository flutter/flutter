// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

import 'package:flutter_api_samples/painting/rounded_superellipse_border/rounded_superellipse_border.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const example.RoundedSuperellipseBorderExample());
    expect(
      find.byType(example.RoundedSuperellipseBorderExample),
      findsOneWidget,
    );

    final RenderObject borderBox = tester.renderObject(
      find.byKey(example.RoundedSuperellipseBorderExample.kBorderBoxKey),
    );
    expect(borderBox, paints..rsuperellipse());

    // Test tapping switches
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();
    expect(borderBox, paints..rrect());

    final Finder radiusSlider = find.descendant(
      of: find.byKey(example.RoundedSuperellipseBorderExample.kRadiusSliderKey),
      matching: find.byType(CupertinoSlider),
    );
    expect(radiusSlider, findsOne);
    final Finder thicknessSlider = find.descendant(
      of: find.byKey(
        example.RoundedSuperellipseBorderExample.kThicknessSliderKey,
      ),
      matching: find.byType(CupertinoSlider),
    );
    expect(thicknessSlider, findsOne);
    // Preferrably we should test the interaction between the sliders and the
    // drawn box, but it seems very hard if the slider thumb doesn't start at
    // the left-most position.
  });
}
