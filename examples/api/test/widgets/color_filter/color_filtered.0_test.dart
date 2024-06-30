// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_api_samples/widgets/color_filter/color_filtered.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The app being tested loads images via HTTP which the test
  // framework defeats by default.
  setUpAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('Displays two images', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ColorFilteredExampleApp(),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('Applies red color filter with modulate blend mode to the first image', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ColorFilteredExampleApp(),
    );

    await tester.pumpAndSettle();

    final RenderObject renderObject = tester.firstRenderObject(
      find.byType(ColorFiltered).first,
    );
    final ColorFilterLayer colorFilterLayer =
        renderObject.debugLayer! as ColorFilterLayer;

    expect(
      colorFilterLayer.colorFilter,
      equals(const ColorFilter.mode(Colors.red, BlendMode.modulate)),
    );
  });

  testWidgets('Applies grey color filter with saturation blend mode to the second image', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ColorFilteredExampleApp(),
    );

    await tester.pumpAndSettle();

    final RenderObject renderObject = tester.firstRenderObject(
      find.byType(ColorFiltered).last,
    );
    final ColorFilterLayer colorFilterLayer =
        renderObject.debugLayer! as ColorFilterLayer;

    expect(
      colorFilterLayer.colorFilter,
      equals(const ColorFilter.mode(Colors.grey, BlendMode.saturation)),
    );
  });
}
