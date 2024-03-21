// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/value_updater/value_updater.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ToggleValue toggles value, changing alignment in example', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ToggleValueExample());
    final Finder toggleFinder = find.byType(ValueUpdater<AlignmentGeometry>);
    expect(toggleFinder, findsOneWidget);
    final Finder logoFinder = find.byType(FlutterLogo);
    expect(logoFinder, findsOneWidget);

    expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, equals(Alignment.bottomLeft));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, equals(Alignment.topRight));
  });
}
