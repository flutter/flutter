// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/widgets/fade_in_image/fade_in_image.transition.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The app being tested loads images via HTTP which the test
  // framework defeats by default.
  setUpAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('switches the transition in place', (WidgetTester tester) async {
    await tester.pumpWidget(const example.FadeInImageTransitionExampleApp());
    await tester.pumpAndSettle();

    FadeInImage fadeInImage() =>
        tester.widget<FadeInImage>(find.byType(FadeInImage));
    final State state = tester.state(find.byType(FadeInImage));

    expect(fadeInImage().transition, FadeInImageTransition.sequential);

    await tester.tap(find.text('fadeInOver'));
    await tester.pumpAndSettle();
    expect(fadeInImage().transition, FadeInImageTransition.fadeInOver);
    // The transition is swapped in place rather than the widget being rebuilt
    // from scratch, so the same state is kept throughout.
    expect(tester.state(find.byType(FadeInImage)), same(state));

    await tester.tap(find.text('sequential'));
    await tester.pumpAndSettle();
    expect(fadeInImage().transition, FadeInImageTransition.sequential);
    expect(tester.state(find.byType(FadeInImage)), same(state));

    expect(tester.takeException(), isNull);
  });
}
