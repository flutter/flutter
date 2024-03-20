// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/toggle_value/toggle_value.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ToggleValue toggles value, changing alignment in example', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: example.ToggleValueWithNotifierExample(),
      ),
    );
    final Finder toggleFinder = find.byType(ToggleValue<AlignmentGeometry>);
    expect(toggleFinder, findsOneWidget);
    final Finder logoFinder = find.byType(FlutterLogo);
    expect(logoFinder, findsOneWidget);

    expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, equals(Alignment.center));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, equals(Alignment.bottomLeft));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, equals(Alignment.topLeft));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, equals(Alignment.topRight));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, equals(Alignment.bottomRight));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, equals(Alignment.bottomLeft));
  });
}
