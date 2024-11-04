// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/scrollbar/raw_scrollbar.desktop.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'ScrollbarApp displays two scrollable lists with scrollbars',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ScrollbarApp(),
    );

    // Check if there are two Scrollbars present in the widget tree.
    expect(find.byType(Scrollbar), findsNWidgets(2));
    expect(find.text('Scrollable 1 : Index 0'), findsOneWidget);
    expect(find.text('Scrollable 2 : Index 0'), findsOneWidget);

    // Verify that both lists are rendered with 100 items each.
    await tester.dragUntilVisible(
      find.text('Scrollable 1 : Index 99'),
      find.byType(Scrollbar).first,
      const Offset(0, -300),
    );
    await tester.dragUntilVisible(
      find.text('Scrollable 2 : Index 99'),
      find.byType(Scrollbar).last,
      const Offset(0, -300),
    );

    // After scrolling, the first item should no longer be visible.
    expect(find.text('Scrollable 1 : Index 0'), findsNothing);
    expect(find.text('Scrollable 2 : Index 0'), findsNothing);
  });
}
