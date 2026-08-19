// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/fade_in_image/fade_in_image.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The app being tested loads images via HTTP which the test
  // framework defeats by default.
  setUpAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('selecting a transition updates the FadeInImage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.FadeInImageTransitionExampleApp());

    FadeInImage fadeInImage() =>
        tester.widget<FadeInImage>(find.byType(FadeInImage));

    // Defaults to the sequential transition.
    expect(fadeInImage().transition, FadeInImageTransition.sequential);

    // Selecting fadeInOver updates the transition without throwing.
    await tester.tap(find.text('fadeInOver'));
    await tester.pumpAndSettle();
    expect(fadeInImage().transition, FadeInImageTransition.fadeInOver);

    // Selecting sequential again switches back.
    await tester.tap(find.text('sequential'));
    await tester.pumpAndSettle();
    expect(fadeInImage().transition, FadeInImageTransition.sequential);

    expect(tester.takeException(), isNull);
  });
}
