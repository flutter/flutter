// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/slider/slider.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Slider can change its value', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SliderApp(),
    );

    expect(find.byType(Slider), findsOneWidget);

    final Finder sliderFinder = find.byType(Slider);

    Slider slider = tester.widget(sliderFinder);
    expect(slider.value, 20);

    final Offset center = tester.getCenter(sliderFinder);
    await tester.tapAt(Offset(center.dx + 100, center.dy));
    await tester.pump();

    slider = tester.widget(sliderFinder);
    expect(slider.value, 60.0);
  });
}
