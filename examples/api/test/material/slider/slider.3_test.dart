// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/slider/slider.3.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SliderThemeData.use2024SliderShapes is true',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const example.SliderExampleApp(),
      );

      final ThemeData theme = Theme.of(tester.element(find.byType(Slider).first));
      expect(theme.sliderTheme.use2024SliderShapes, equals(true));
  });

  testWidgets('Can update theme brightness', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SliderExampleApp(),
    );

    ThemeData theme = Theme.of(tester.element(find.byType(Slider).first));
    expect(theme.brightness, equals(Brightness.light));

    // Tap on the button to change the brightness.
    await tester.tap(find.byIcon(Icons.wb_sunny_outlined));
    await tester.pumpAndSettle();

    theme = Theme.of(tester.element(find.byType(Slider).first));
      expect(theme.brightness, equals(Brightness.dark));
  });

  testWidgets('Can adjust Slider value', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SliderExampleApp(),
    );

    final Finder sliderFinder = find.byType(Slider).at(0);
    Slider slider = tester.widget(sliderFinder);
    expect(slider.value, 4.0);

    final TestGesture gesture = await tester.startGesture(tester.getCenter(sliderFinder));
    await gesture.moveBy(const Offset(100, 0));
    await gesture.up();
    await tester.pump();

    slider = tester.widget(sliderFinder);
    expect(slider.value, closeTo(6.6, 0.1));

    slider = tester.widget(find.byType(Slider).at(1));
    expect(slider.value, 60);

    await gesture.down(tester.getCenter(find.byType(Slider).at(1)));
    await gesture.moveBy(const Offset(150, 0));
    await gesture.up();
    await tester.pump();

    slider = tester.widget(find.byType(Slider).at(1));
    expect(slider.value, closeTo(70.2, 0.1));

    slider = tester.widget(find.byType(Slider).at(2));
    expect(slider.value, 800);

    await gesture.down(tester.getCenter(find.byType(Slider).at(2)));
    await gesture.moveBy(const Offset(-150, 0));
    await gesture.up();
    await tester.pump();

    slider = tester.widget(find.byType(Slider).at(2));
    expect(slider.value, closeTo(301.2, 0.1));
  });
}
