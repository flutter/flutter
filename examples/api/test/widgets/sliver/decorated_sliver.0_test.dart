// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/sliver/decorated_sliver.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Verify the texts are displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const example.SliverDecorationExampleApp());

    final Finder moonText = find.text('A moon on a night sky');
    expect(moonText, findsOneWidget);

    final Finder blueSkyText = find.text('A blue sky');
    expect(blueSkyText, findsOneWidget);
  });

  testWidgets('Verify the DecoratedSliver has a LinearGradient', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.SliverDecorationExampleApp());

    final DecoratedSliver decoratedSliver = tester.widget<DecoratedSliver>(
      find.byType(DecoratedSliver),
    );
    expect(
      decoratedSliver.decoration,
      const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF111133),
            Color(0xFF1A237E),
            Color(0xFF283593),
            Color(0xFF3949AB),
            Color(0xFF3F51B5),
            Color(0xFF1976D2),
            Color(0xFF1E88E5),
            Color(0xFF42A5F5),
          ],
        ),
      ),
    );
  });

  testWidgets('Verify the moon section has a RadialGradient', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.SliverDecorationExampleApp());

    final Container moonContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('A moon on a night sky'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      moonContainer.decoration,
      const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.5, -0.6),
          radius: 0.15,
          colors: <Color>[Color(0xFFEEEEEE), Color(0xFF111133)],
          stops: <double>[0.4, 0.8],
        ),
      ),
    );
  });

  testWidgets('Verify that SliverMainAxisGroup is used to group the slivers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.SliverDecorationExampleApp());

    expect(find.byType(SliverMainAxisGroup), findsOneWidget);
  });
}
