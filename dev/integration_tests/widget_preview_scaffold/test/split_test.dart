// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;
import 'package:widget_preview_scaffold/src/split.dart';

void main() {
  testWidgets('SplitPane lays out children and can be resized', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 600,
            child: SplitPane(
              axis: Axis.horizontal,
              initialFractions: const [0.7, 0.3],
              children: const [
                SizedBox.expand(key: ValueKey('child-0')),
                SizedBox.expand(key: ValueKey('child-1')),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify initial sizes based on fractions.
    // Total width is 1000. Splitter width is 12.0.
    // Available size = 1000 - 12 = 988.
    // child-0: 988 * 0.7 = 691.6
    // child-1: 988 * 0.3 = 296.4
    final double initialWidth0 = tester
        .getSize(find.byKey(const ValueKey('child-0')))
        .width;
    final double initialWidth1 = tester
        .getSize(find.byKey(const ValueKey('child-1')))
        .width;

    expect(initialWidth0, closeTo(691.6, 0.1));
    expect(initialWidth1, closeTo(296.4, 0.1));

    // Find the splitter divider.
    final Finder splitterFinder = find.byKey(
      const Key('SplitPane dividerKey 0'),
    );
    expect(splitterFinder, findsOneWidget);

    // Drag the splitter to the left by -100 pixels horizontally.
    await tester.drag(splitterFinder, const Offset(-100, 0));
    await tester.pump();

    // Verify updated sizes.
    // Drag of -100 pixels out of total 1000.
    // Fractional delta is -100 / 1000 = -0.1.
    // New fractions are 0.6 and 0.4.
    // child-0: 988 * 0.6 = 592.8
    // child-1: 988 * 0.4 = 395.2
    final double updatedWidth0 = tester
        .getSize(find.byKey(const ValueKey('child-0')))
        .width;
    final double updatedWidth1 = tester
        .getSize(find.byKey(const ValueKey('child-1')))
        .width;

    expect(updatedWidth0, closeTo(592.8, 0.1));
    expect(updatedWidth1, closeTo(395.2, 0.1));
  });

  testWidgets(
    'SplitPane toggles iframe pointer-events style during drag on web',
    (tester) async {
      web.HTMLIFrameElement? iframe;
      if (kIsWeb) {
        iframe = web.HTMLIFrameElement();
        web.document.body!.appendChild(iframe);
      }

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1000,
                height: 600,
                child: SplitPane(
                  axis: Axis.horizontal,
                  initialFractions: const [0.7, 0.3],
                  children: const [SizedBox.expand(), SizedBox.expand()],
                ),
              ),
            ),
          ),
        );

        if (kIsWeb && iframe != null) {
          expect(iframe.style.pointerEvents, '');
        }

        final Finder splitterFinder = find.byKey(
          const Key('SplitPane dividerKey 0'),
        );
        expect(splitterFinder, findsOneWidget);

        // Start drag gesture.
        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(splitterFinder),
        );
        await tester.pump();

        if (kIsWeb && iframe != null) {
          // Verify pointer-events is disabled during active drag.
          expect(iframe.style.pointerEvents, 'none');
        }

        // End drag gesture.
        await gesture.up();
        await tester.pump();

        if (kIsWeb && iframe != null) {
          // Verify pointer-events is restored after drag.
          expect(iframe.style.pointerEvents, '');
        }
      } finally {
        if (kIsWeb && iframe != null) {
          iframe.remove();
        }
      }
    },
  );
}
