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
      const example.NavigationBarApp(),
    );
    final NavigationBar navigationBarWidget = tester.firstWidget(find.byType(NavigationBar));

    /// NavigationDestinations must be rendered
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    /// Test notification badge.
    final Badge notificationBadge = tester.firstWidget(find.ancestor(
      of: find.byIcon(Icons.notifications_sharp),
      matching: find.byType(Badge),
    ));
    expect(notificationBadge.label, null);

    /// Test messages badge.
    final Badge messagesBadge = tester.firstWidget(find.ancestor(
      of: find.byIcon(Icons.messenger_sharp),
      matching: find.byType(Badge),
    ));
    expect(messagesBadge.label, isNotNull);

    /// initial index must be zero
    expect(navigationBarWidget.selectedIndex, 0);

    /// switch to second tab
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsOneWidget);

    /// switch to third tab
    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();
    expect(find.text('Page 3'), findsOneWidget);

    /// switch to fourth tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Page 4'), findsOneWidget);
  });
}
