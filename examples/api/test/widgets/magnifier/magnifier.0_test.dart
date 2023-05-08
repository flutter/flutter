// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/magnifier/magnifier.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should update magnifier position on drag', (WidgetTester tester) async {
    await tester.pumpWidget(const example.MagnifierExampleApp());

    Matcher isPositionedAt(Offset at) {
      return isA<Positioned>().having(
        (Positioned positioned) => Offset(positioned.left!, positioned.top!),
        'magnifier position',
        at,
      );
    }

    expect(
      tester.widget(find.byType(Positioned)),
      isPositionedAt(Offset.zero),
    );

    final Offset centerOfFlutterLogo = tester.getCenter(find.byType(Positioned));
    final Offset topLeftOfFlutterLogo = tester.getTopLeft(find.byType(FlutterLogo));

    const Offset dragDistance = Offset(10, 10);

    await tester.dragFrom(centerOfFlutterLogo, dragDistance);
    await tester.pump();

    expect(
      tester.widget(find.byType(Positioned)),
      // Need to adjust by the topleft since the position is local.
      isPositionedAt((centerOfFlutterLogo - topLeftOfFlutterLogo) + dragDistance),
    );
  });

  testWidgets('should match golden', (WidgetTester tester) async {
    await tester.pumpWidget(const example.MagnifierExampleApp());

    final Offset centerOfFlutterLogo = tester.getCenter(find.byType(Positioned));
    const Offset dragDistance = Offset(10, 10);

    await tester.dragFrom(centerOfFlutterLogo, dragDistance);
    await tester.pump();

    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('magnifier.0_test.png'),
    );
  });
}
