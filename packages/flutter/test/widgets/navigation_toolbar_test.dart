// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
