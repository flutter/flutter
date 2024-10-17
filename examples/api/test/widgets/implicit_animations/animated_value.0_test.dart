// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/implicit_animations/animated_value.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

typedef RotationValues = (double, double, double, double);

void main() {
  testWidgets('Widget animates from its initialValue', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.AnimatedValueApp(),
    );

    final Finder findTransform = find.descendant(
      of: find.byType(AnimatedRotation),
      matching: find.byType(Transform),
    );

    // The values that Transform.rotate() changes.
    RotationValues rotationValues() {
      final Transform widget = tester.widget<Transform>(findTransform);

      final [
        double p0,
        double p1,
        _,
        _,
        double p2,
        double p3,
        ..._,
      ] = widget.transform.storage;

      return (p0, p1, p2, p3);
    }

    // Extract relevant values from the Transform widget right when spin begins.
    example.FreePrizes.spin(tester.element(find.byType(example.PrizeSpinner)));
    await tester.pump();
    final RotationValues initialValues = rotationValues();

    // Spin is >= halfway done; rotation should have changed.
    await tester.pump(const Duration(milliseconds: 1200));
    final RotationValues halfway = rotationValues();
    expect(halfway == initialValues, isFalse);

    // Spin is now complete; values should have changed.
    await tester.pump(const Duration(milliseconds: 1200));
    final RotationValues atRest = rotationValues();
    expect(atRest == initialValues, isFalse);
    expect(atRest == halfway, isFalse);

    // Sanity check: once full duration has passed,
    // spinner should not be rotating.
    await tester.pump(const Duration(milliseconds: 1200));
    expect(rotationValues(), atRest);
  });
}
