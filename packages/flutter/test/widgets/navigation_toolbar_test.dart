// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const toolbarWidth = 360.0;
  const leadingWidth = 48.0;
  const trailingWidth = 120.0;
  const middleSpacing = 4.0;
  const leadingKey = ValueKey<String>('leading');
  const middleKey = ValueKey<String>('middle');
  const trailingKey = ValueKey<String>('trailing');

  testWidgets('NavigationToolbar centers middle within the toolbar when there is room', (
    WidgetTester tester,
  ) async {
    const middleWidth = 104.0; // Leaves an 8-pixel trailing gap when centered.
    for (final TextDirection textDirection in TextDirection.values) {
      await tester.pumpWidget(
        Directionality(
          textDirection: textDirection,
          child: const Center(
            child: SizedBox(
              width: toolbarWidth,
              child: NavigationToolbar(
                centerMiddle: true,
                middleSpacing: middleSpacing,
                leading: SizedBox(key: leadingKey, width: leadingWidth),
                middle: SizedBox(key: middleKey, width: middleWidth),
                trailing: SizedBox(key: trailingKey, width: trailingWidth),
              ),
            ),
          ),
        ),
      );

      // The leading and trailing widgets have different widths, so centering
      // the middle between them would place it off the toolbar's center.
      expect(
        tester.getCenter(find.byKey(middleKey)).dx,
        tester.getCenter(find.byType(NavigationToolbar)).dx,
      );
    }
  });

  // Regression test for https://github.com/flutter/flutter/issues/196207.
  for (final TextDirection textDirection in TextDirection.values) {
    for (final middleWidth in <double>[
      112.0, // Centering leaves the required 4-pixel trailing gap.
      // Centering leaves a 2-pixel gap. The middle should move 2 pixels toward
      // the leading widget to leave the required 4-pixel gap.
      116.0,
      120.0, // The centered middle touches the trailing widget.
      124.0, // The centered middle overlaps the trailing widget by 2 pixels.
    ]) {
      testWidgets('NavigationToolbar preserves middleSpacing when centered '
          '($textDirection, middle width: $middleWidth)', (WidgetTester tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: textDirection,
            child: Center(
              child: SizedBox(
                width: toolbarWidth,
                child: NavigationToolbar(
                  centerMiddle: true,
                  middleSpacing: middleSpacing,
                  leading: const SizedBox(key: leadingKey, width: leadingWidth),
                  middle: SizedBox(key: middleKey, width: middleWidth),
                  trailing: const SizedBox(key: trailingKey, width: trailingWidth),
                ),
              ),
            ),
          ),
        );

        final Rect leading = tester.getRect(find.byKey(leadingKey));
        final Rect middle = tester.getRect(find.byKey(middleKey));
        final Rect trailing = tester.getRect(find.byKey(trailingKey));

        expect(middle.width, middleWidth);
        if (textDirection == TextDirection.ltr) {
          expect(middle.left - leading.right, greaterThanOrEqualTo(middleSpacing));
          expect(trailing.left - middle.right, middleSpacing);
        } else {
          expect(leading.left - middle.right, greaterThanOrEqualTo(middleSpacing));
          expect(middle.left - trailing.right, middleSpacing);
        }
      });
    }
  }
}
