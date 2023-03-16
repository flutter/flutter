// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/navigation_bar/navigation_bar.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Navigation bar updates destination on tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ExampleApp(),
    );
    final NavigationBar navigationBarWidget =
        tester.firstWidget(find.byType(NavigationBar));

    /// NavigationDestinations must be rendered
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Commute'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);

    /// initial index must be zero
    expect(navigationBarWidget.selectedIndex, 0);

    /// switch to second tab
    await tester.tap(find.text('Commute'));
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsOneWidget);

    /// switch to third tab
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Page 3'), findsOneWidget);
  });
}
