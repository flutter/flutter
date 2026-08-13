// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/foundation/key/value_key.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeyValueComparisonPage', () {
    testWidgets(
      'counter state stays attached to the correct color after reversing because of ValueKey',
      (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(const example.KeyValueComparisonExample());

        // Verify initial order: red, green, blue
        final containersBefore = tester.widgetList<Container>(
          find.byType(Container),
        );

        expect(containersBefore.elementAt(0).color, Colors.red);
        expect(containersBefore.elementAt(1).color, Colors.green);
        expect(containersBefore.elementAt(2).color, Colors.blue);

        // Verify all counters start at 0
        expect(find.text('0'), findsNWidgets(3));

        // Tap the RED widget counter
        await tester.tap(find.text('0').first);
        await tester.pump();

        // Verify state after tap
        expect(find.text('1'), findsOneWidget);
        expect(find.text('0'), findsNWidgets(2));

        // reverse the list
        await tester.tap(find.byIcon(Icons.flip));
        await tester.pump();

        // Verify order is now blue, green, red
        final containersAfter = tester.widgetList<Container>(
          find.byType(Container),
        );

        expect(containersAfter.elementAt(0).color, Colors.blue);
        expect(containersAfter.elementAt(1).color, Colors.green);
        expect(containersAfter.elementAt(2).color, Colors.red);

        // Verify the counter value "1" moved WITH the red widget
        final redContainer = tester.widget<Container>(
          find.byWidgetPredicate(
            (widget) => widget is Container && widget.color == Colors.red,
          ),
        );

        expect(redContainer.color, Colors.red);

        // Verify only one counter still has value 1
        expect(find.text('1'), findsOneWidget);
        expect(find.text('0'), findsNWidgets(2));

        // Verify the "1" is inside the red container subtree
        final redTextButtonFinder = find.descendant(
          of: find.byWidgetPredicate(
            (widget) => widget is Container && widget.color == Colors.red,
          ),
          matching: find.text('1'),
        );

        expect(redTextButtonFinder, findsOneWidget);
      },
    );
  });
}
