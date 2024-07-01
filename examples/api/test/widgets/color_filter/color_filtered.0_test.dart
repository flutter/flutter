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

  testWidgets('Color filters are applied to the images', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ColorFilteredExampleApp(),
    );

    await tester.pumpAndSettle();

    // Verify that two images are displayed.
    expect(find.byType(Image), findsNWidgets(2));

    final RenderObject renderObject1 = tester.firstRenderObject(
      find.byType(ColorFiltered).first,
    );
    final ColorFilterLayer colorFilterLayer1 =
        renderObject1.debugLayer! as ColorFilterLayer;

    // Verify that red colored filter with modulate blend mode is applied to the first image.
    expect(
      colorFilterLayer1.colorFilter,
      equals(const ColorFilter.mode(Colors.red, BlendMode.modulate)),
    );

    final RenderObject renderObject2 = tester.firstRenderObject(
      find.byType(ColorFiltered).last,
    );
    final ColorFilterLayer colorFilterLayer2 =
        renderObject2.debugLayer! as ColorFilterLayer;

    // Verify that grey colored filter with saturation blend mode is applied to the first image.
    expect(
      colorFilterLayer2.colorFilter,
      equals(const ColorFilter.mode(Colors.grey, BlendMode.saturation)),
    );
  });
}
