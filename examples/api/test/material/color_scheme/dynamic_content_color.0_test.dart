// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/color_scheme/dynamic_content_color.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The app being tested loads images via HTTP which the test
  // framework defeats by default.
  setUp(() {
    HttpOverrides.global = null;
  });

  final List<ImageProvider> images = <NetworkImage>[
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_1.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_2.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_3.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_4.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_5.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_6.png'),
  ];

  testWidgets('DynamicColor smoke test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(example.DynamicColorExample());

      expect(find.byType(CircularProgressIndicator), findsOne);
      expect(find.widgetWithText(AppBar, 'Content Based Dynamic Color'), findsOne);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(find.text('Light ColorScheme'), findsOne);
      expect(find.text('Dark ColorScheme'), findsOne);

      for (final ImageProvider<Object> networkImage in images) {
        expect(
            find.descendant(
              of: find.byType(GestureDetector),
              matching: find.image(networkImage),
            ), findsOne);
      }

      Finder chipFinder(String label) =>
          find.byWidgetPredicate((Widget widget) => widget is example.ColorChip && widget.label == label);

      expect(chipFinder('primary'), findsNWidgets(2));
      expect(chipFinder('onPrimary'), findsNWidgets(2));
      expect(chipFinder('primaryContainer'), findsNWidgets(2));
      expect(chipFinder('onPrimaryContainer'), findsNWidgets(2));

      expect(chipFinder('secondary'), findsNWidgets(2));
      expect(chipFinder('onSecondary'), findsNWidgets(2));
      expect(chipFinder('secondaryContainer'), findsNWidgets(2));
      expect(chipFinder('onSecondaryContainer'), findsNWidgets(2));

      expect(chipFinder('tertiary'), findsNWidgets(2));
      expect(chipFinder('onTertiary'), findsNWidgets(2));
      expect(chipFinder('tertiaryContainer'), findsNWidgets(2));
      expect(chipFinder('onTertiaryContainer'), findsNWidgets(2));

      expect(chipFinder('surface'), findsNWidgets(2));
      expect(chipFinder('onSurface'), findsNWidgets(2));
      expect(chipFinder('onSurfaceVariant'), findsNWidgets(2));

      expect(chipFinder('outline'), findsNWidgets(2));
      expect(chipFinder('shadow'), findsNWidgets(2));
      expect(chipFinder('inverseSurface'), findsNWidgets(2));
      expect(chipFinder('onInverseSurface'), findsNWidgets(2));
      expect(chipFinder('inversePrimary'), findsNWidgets(2));
    });
  });
}
