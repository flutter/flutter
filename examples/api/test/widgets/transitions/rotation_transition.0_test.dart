// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/transitions/rotation_transition.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows flutter logo in rotation transition', (WidgetTester tester) async {
    await tester.pumpWidget(const example.RotationTransitionExampleApp());

    // Find RotationTransition widgets (there may be multiple due to Material transitions)
    final Finder rotationTransitions = find.byType(RotationTransition);
    expect(rotationTransitions, findsWidgets);

    expect(find.byType(FlutterLogo), findsOneWidget);
    expect(find.byType(Padding), findsAtLeast(1));
    expect(
      find.descendant(of: find.byType(Center), matching: find.byType(FlutterLogo)),
      findsOneWidget,
    );

    // Find our specific RotationTransition (the one that contains FlutterLogo)
    expect(
      find.ancestor(of: find.byType(FlutterLogo), matching: find.byType(RotationTransition)),
      findsOneWidget,
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // After 3 seconds, verify our RotationTransition still exists and contains the FlutterLogo
    expect(
      find.ancestor(of: find.byType(FlutterLogo), matching: find.byType(RotationTransition)),
      findsOneWidget,
    );
  });
}
