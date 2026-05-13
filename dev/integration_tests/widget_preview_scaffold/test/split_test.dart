// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/split.dart';
import 'package:widget_preview_scaffold/src/utils/pointer_events/pointer_events.dart';

void main() {


  testWidgets(
    'SplitPane toggles iframe pointer-events style during drag on web',
    (tester) async {
      debugAppendTestIframe();

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

        expect(debugGetIframePointerEvents(), '');

        final Finder splitterFinder = find.byKey(
          const Key('SplitPane dividerKey 0'),
        );
        expect(splitterFinder, findsOneWidget);

        // Start drag gesture.
        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(splitterFinder),
        );
        await tester.pump();

        // Verify pointer-events is disabled during active drag.
        expect(debugGetIframePointerEvents(), 'none');

        // End drag gesture.
        await gesture.up();
        await tester.pump();

        // Verify pointer-events is restored after drag.
        expect(debugGetIframePointerEvents(), '');
      } finally {
        debugRemoveTestIframe();
      }
    },
  );
}
