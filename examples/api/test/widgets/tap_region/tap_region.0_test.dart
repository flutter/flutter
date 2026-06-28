// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/tap_region/tap_region.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TapRegion shows initial status message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.TapRegionExampleApp());

    expect(
      find.text('Tap inside or outside the outlined area.'),
      findsOneWidget,
    );
    expect(find.text('Tap Region'), findsOneWidget);
  });

  testWidgets('TapRegion updates status on inside and outside taps', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.TapRegionExampleApp());

    await tester.tap(find.byType(TapRegion));
    await tester.pump();

    expect(find.text('Tapped inside!'), findsOneWidget);

    await tester.tapAt(Offset.zero);
    await tester.pump();

    expect(find.text('Tapped outside!'), findsOneWidget);
  });
}
