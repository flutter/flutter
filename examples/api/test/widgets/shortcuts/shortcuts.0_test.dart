// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_api_samples/widgets/shortcuts/shortcuts.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Verify correct labels are displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ShortcutsExampleApp());

    expect(find.text('Shortcuts Sample'), findsOneWidget);
    expect(find.text('Add to the counter by pressing the up arrow key'), findsOneWidget);
    expect(find.text('Subtract from the counter by pressing the down arrow key'), findsOneWidget);
    expect(find.text('count: 0'), findsOneWidget);
  });

  testWidgets('Up and down arrow press updates counter', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ShortcutsExampleApp());

    int counter = 0;

    while (counter < 10) {
      expect(find.text('count: $counter'), findsOneWidget);

      // Increment the counter.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      counter++;
    }

    while (counter >= 0) {
      expect(find.text('count: $counter'), findsOneWidget);

      // Decrement the counter.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      counter--;
    }
  });
}
