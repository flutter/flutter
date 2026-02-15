// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/carousel/carousel.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CarouselView.builder creates items lazily', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.CarouselBuilderExampleApp());

    expect(find.byType(CarouselView), findsOneWidget);

    expect(find.text('Item 0'), findsOneWidget);

    expect(find.text('Item 999'), findsNothing);

    final Finder carousel = find.byType(CarouselView);
    await tester.drag(carousel, const Offset(-350, 0));
    await tester.pumpAndSettle();

    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 0'), findsNothing);

    for (int i = 0; i < 5; i++) {
      await tester.drag(carousel, const Offset(-350, 0));
      await tester.pumpAndSettle();
    }

    expect(find.text('Item 6'), findsOneWidget);
  });
}
