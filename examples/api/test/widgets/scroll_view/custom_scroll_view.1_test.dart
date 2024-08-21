// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/scroll_view/custom_scroll_view.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Pressing the add button  should add items above and below and keep the scroll position',
    (WidgetTester tester) async {
      await tester.pumpWidget(const example.CustomScrollViewExampleApp());

      expect(find.widgetWithText(AppBar, 'Press on the plus to add items above and below'), findsOne);

      expect(find.text('Item: -2'), findsNothing);
      expect(find.text('Item: -1'), findsNothing);
      expect(find.text('Item: 0'), findsOne);
      expect(find.text('Item: 1'), findsNothing);
      expect(find.text('Item: 2'), findsNothing);

      expect(tester.getTopLeft(find.widgetWithText(Container, 'Item: 0')), const Offset(0, 56));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('Item: -2'), findsNothing);
      expect(find.text('Item: -1', skipOffstage: false), findsOne);
      expect(find.text('Item: 0'), findsOne);
      expect(find.text('Item: 1'), findsOne);
      expect(find.text('Item: 2'), findsNothing);

      expect(
        tester.getTopLeft(find.widgetWithText(Container, 'Item: 0')),
        const Offset(0, 56),
        reason: 'The scroll position should not change when adding items above the current position',
      );

      // Scroll up a bit.
      await tester.fling(find.byType(CustomScrollView).last, const Offset(0, 50), 10.0);

      expect(
        tester.getTopLeft(find.widgetWithText(Container, 'Item: 0')),
        const Offset(0, 106),
        reason: 'The scroll position should not change when adding items above the current position',
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('Item: -2', skipOffstage: false), findsOne);
      expect(find.text('Item: -1'), findsOne);
      expect(find.text('Item: 0'), findsOne);
      expect(find.text('Item: 1'), findsOne);
      expect(find.text('Item: 2'), findsOne);

      expect(
        tester.getTopLeft(find.widgetWithText(Container, 'Item: 0')),
        const Offset(0, 106),
        reason: 'The scroll position should not change when adding items above the current position',
      );
    },
  );
}
