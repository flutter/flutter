// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/keep_alive/automatic_keep_alive_client_mixin.0.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('The state is maintained when the item is scrolled out of view', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AutomaticKeepAliveClientMixinExampleApp());

    expect(find.text('Item 0: 0'), findsOne);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
    await tester.pump();

    expect(find.text('Item 0: 1'), findsOne);

    // Scrolls all the way down to the bottom of the list.
    await tester.fling(find.byType(ListView), const Offset(0, -6000), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Item 99: 0'), findsOne);

    // Scrolls all the way back to the top of the list.
    await tester.fling(find.byType(ListView), const Offset(0, 6000), 1000);
    await tester.pumpAndSettle();

    expect(
      find.text('Item 0: 1'),
      findsOne,
      reason: 'The state of item 0 should be maintained',
    );
  });

  testWidgets(
    'The state is not maintained when the item is scrolled out of view',
    (WidgetTester tester) async {
      await tester.pumpWidget(const AutomaticKeepAliveClientMixinExampleApp());

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Item 0: 0'), findsOne);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
      await tester.pump();

      expect(find.text('Item 0: 1'), findsOne);

      // Scrolls all the way down to the bottom of the list.
      await tester.fling(find.byType(ListView), const Offset(0, -6000), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Item 99: 0'), findsOne);

      // Scrolls all the way back to the top of the list.
      await tester.fling(find.byType(ListView), const Offset(0, 6000), 1000);
      await tester.pumpAndSettle();

      expect(
        find.text('Item 0: 0'),
        findsOne,
        reason: 'The state of item 0 should not be maintained',
      );
    },
  );
}
