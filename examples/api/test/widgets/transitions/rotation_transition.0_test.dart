// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/transitions/rotation_transition.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows flutter logo in rotation transition', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.RotationTransitionExampleApp());
    expect(find.byType(FlutterLogo), findsOneWidget);
    expect(find.byType(Padding), findsAtLeast(1));
    expect(
      find.descendant(
        of: find.byType(Center),
        matching: find.byType(FlutterLogo),
      ),
      findsOneWidget,
    );

    expect(find.byType(RotationTransition), findsOneWidget);
    final transition = tester.widget<RotationTransition>(
      find.byType(RotationTransition),
    );
    expect(transition.turns.status, AnimationStatus.forward);
    expect(transition.turns.value, 0.0);

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(transition.turns.status, AnimationStatus.reverse);
    expect(
      transition.turns.value,
      moreOrLessEquals(Curves.elasticOut.transform(0.5)),
    );
  });
}
