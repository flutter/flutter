// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/widgets/overlay/overlay_portal.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows anchor and hides overlay initially', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const example.OverlayPortalLayoutBuilderExampleApp(),
    );

    expect(find.text('Press me'), findsOneWidget);
    expect(find.text('Hello from the overlay!'), findsNothing);
  });

  testWidgets('tapping anchor shows overlay below it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const example.OverlayPortalLayoutBuilderExampleApp(),
    );

    await tester.tap(find.text('Press me'));
    await tester.pump();

    expect(find.text('Hello from the overlay!'), findsOneWidget);

    final Rect anchorRect = tester.getRect(
      find.ancestor(
        of: find.text('Press me'),
        matching: find.byType(GestureDetector),
      ),
    );
    final Rect overlayRect = tester.getRect(
      find.ancestor(
        of: find.text('Hello from the overlay!'),
        matching: find.byType(Container),
      ),
    );

    expect(overlayRect.top, anchorRect.bottom);
    expect(overlayRect.left, anchorRect.left);
  });

  testWidgets('tapping anchor again hides the overlay', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const example.OverlayPortalLayoutBuilderExampleApp(),
    );

    await tester.tap(find.text('Press me'));
    await tester.pump();
    expect(find.text('Hello from the overlay!'), findsOneWidget);

    await tester.tap(find.text('Press me'));
    await tester.pump();
    expect(find.text('Hello from the overlay!'), findsNothing);
  });
}
