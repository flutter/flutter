// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/transitions/scale_transition.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows flutter logo in transition', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ScaleTransitionExampleApp());
    expect(find.byType(FlutterLogo), findsOneWidget);
    expect(find.byType(Center), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Center),
        matching: find.byType(ScaleTransition),
      ),
      findsOneWidget,
    );

    final transition = tester.widget<ScaleTransition>(
      find.byType(ScaleTransition),
    );
    expect(transition.scale.value, 0.0);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(
      transition.scale.value,
      moreOrLessEquals(Curves.fastOutSlowIn.transform(0.5)),
    );
  });

  testWidgets('Scales every 2 seconds', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ScaleTransitionExampleApp());
    final Finder transformFinder = find.descendant(
      of: find.byType(Center),
      matching: find.byType(Transform),
    );

    Transform transform = tester.widget(transformFinder);
    expect(transform.transform[0], 0);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    transform = tester.widget(transformFinder);
    expect(transform.transform[0], 1.0);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    transform = tester.widget(transformFinder);
    expect(transform.transform[0], 0);
  });
}
