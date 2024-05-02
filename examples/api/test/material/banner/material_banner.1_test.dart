// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/banner/material_banner.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows all elements when needed', (WidgetTester tester) async {
    await tester.pumpWidget(const example.MaterialBannerExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('The MaterialBanner is below'), findsOneWidget);
    expect(find.text('Show MaterialBanner'), findsOneWidget);
    expect(find.byType(MaterialBanner), findsNothing);
    expect(find.text('DISMISS'), findsNothing);
    expect(find.byIcon(Icons.agriculture_outlined), findsNothing);

    await tester.tap(find.text('Show MaterialBanner'));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text('DISMISS'), findsOneWidget);
    expect(find.byIcon(Icons.agriculture_outlined), findsOneWidget);
  });

  testWidgets('the banner is below the text saying so', (WidgetTester tester) async {
    await tester.pumpWidget(const example.MaterialBannerExampleApp());
    await tester.tap(find.text('Show MaterialBanner'));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text('The MaterialBanner is below'), findsOneWidget);
    final double bannerY = tester.getCenter(find.byType(MaterialBanner)).dy;
    final double textY = tester.getCenter(find.text('The MaterialBanner is below')).dy;
    expect(bannerY, greaterThan(textY));
  });
}
