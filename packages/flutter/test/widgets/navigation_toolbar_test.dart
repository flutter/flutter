// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NavigationToolbar centers middle within the toolbar when there is room', (
    WidgetTester tester,
  ) async {
    const middleKey = ValueKey<String>('middle');

    for (final TextDirection textDirection in TextDirection.values) {
      await tester.pumpWidget(
        Directionality(
          textDirection: textDirection,
          child: const Center(
            child: SizedBox(
              width: 360.0,
              height: 56.0,
              child: NavigationToolbar(
                centerMiddle: true,
                middleSpacing: 4.0,
                leading: SizedBox(width: 48.0),
                middle: SizedBox(key: middleKey, width: 100.0, height: 56.0),
                trailing: SizedBox(width: 120.0, height: 56.0),
              ),
            ),
          ),
        ),
      );

      // The toolbar is centered in the 800 pixel wide test surface. The middle
      // is centered within the toolbar, not within the space between the
      // leading and trailing widgets, whose center is 36 pixels away.
      expect(tester.getCenter(find.byKey(middleKey)).dx, 400.0);
    }
  });

  // Regression test for https://github.com/flutter/flutter/issues/196207.
  for (final TextDirection textDirection in TextDirection.values) {
    for (final middleWidth in <double>[112.0, 116.0, 120.0, 124.0]) {
      testWidgets('NavigationToolbar preserves middleSpacing when centered '
          '($textDirection, middle: $middleWidth)', (WidgetTester tester) async {
        const leadingKey = ValueKey<String>('leading');
        const middleKey = ValueKey<String>('middle');
        const trailingKey = ValueKey<String>('trailing');
        const middleSpacing = 4.0;

        await tester.pumpWidget(
          Directionality(
            textDirection: textDirection,
            child: Center(
              child: SizedBox(
                width: 360.0,
                height: 56.0,
                child: NavigationToolbar(
                  centerMiddle: true,
                  middleSpacing: middleSpacing,
                  leading: const SizedBox(key: leadingKey, width: 48.0),
                  middle: SizedBox(key: middleKey, width: middleWidth, height: 56.0),
                  trailing: const SizedBox(key: trailingKey, width: 120.0, height: 56.0),
                ),
              ),
            ),
          ),
        );

        final Rect leading = tester.getRect(find.byKey(leadingKey));
        final Rect middle = tester.getRect(find.byKey(middleKey));
        final Rect trailing = tester.getRect(find.byKey(trailingKey));
        final double leadingGap = switch (textDirection) {
          .ltr => middle.left - leading.right,
          .rtl => leading.left - middle.right,
        };
        final double trailingGap = switch (textDirection) {
          .ltr => trailing.left - middle.right,
          .rtl => middle.left - trailing.right,
        };

        expect(middle.width, middleWidth);
        expect(leadingGap, greaterThanOrEqualTo(middleSpacing));
        expect(trailingGap, middleSpacing);
      });
    }
  }
}
