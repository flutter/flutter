// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/carousel/carousel.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Carousel Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.CarouselExampleApp(),
    );
    expect(find.byType(CarouselView), findsOneWidget);

    expect(find.widgetWithText(example.UncontainedLayoutCard, 'Item 0'), findsOneWidget);
    expect(find.widgetWithText(example.UncontainedLayoutCard, 'Item 1'), findsOneWidget);
  });
}
