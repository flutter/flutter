// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/slider/slider.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sliders can change its value', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SliderApp(),
    );

    expect(find.byType(Slider), findsNWidgets(2));

    Finder sliderFinder = find.byType(Slider).first;

    Slider slider = tester.widget(sliderFinder);
    expect(slider.value, 60.0);

    // Tap on the regular slider to change its value.
    Offset center = tester.getCenter(sliderFinder);
    await tester.tapAt(Offset(center.dx + 100, center.dy));
    await tester.pump();

    slider = tester.widget(sliderFinder);
    expect(slider.value, closeTo(63.2, 0.1));

    // Tap on the disabled slider to change its value.
    sliderFinder = find.byType(Slider).last;
    slider = tester.widget(sliderFinder);
    expect(slider.value, 20.0);

    center = tester.getCenter(sliderFinder);
    await tester.tapAt(Offset(center.dx + 100, center.dy));
    await tester.pump();

    slider = tester.widget(sliderFinder);
    expect(slider.value, 60.0);
  });
}
