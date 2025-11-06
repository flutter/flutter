// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> main() async {
  testWidgets(
    'When revealAssistiveScrollbar is true, the scrollbar is visible when a trackpad is used to scroll',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Scrollbar(
            revealAssistiveScrollbar: true,
            child: ListView.builder(
              itemCount: 100,
              itemBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: 100.0, height: 100.0),
            ),
          ),
        ),
      );
      // debugDumpApp();
      expect(find.byType(Scrollbar), findsOneWidget);
      final Finder customPaintFinder = find.descendant(
        of: find.byType(Scrollbar),
        matching: find.byWidgetPredicate(
          (Widget w) => w is CustomPaint && w.foregroundPainter is ScrollbarPainter,
        ),
      );
      expect(customPaintFinder, findsOneWidget);
      final ScrollbarPainter scrollbarPainter =
          (tester.widget<CustomPaint>(customPaintFinder).foregroundPainter!) as ScrollbarPainter;
      print(scrollbarPainter.color);

      final TestPointer pointer = TestPointer(1, PointerDeviceKind.trackpad);
      pointer.hover(tester.getCenter(find.byType(Scrollbar)));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -300)));
      await tester.pump();

      expect(scrollbarPainter.color, const Color(0x66BCBCBC));

      // await tester.sendEventToBinding(pointer.cancel());
      pointer.hover(tester.getCenter(find.byType(ListView)));
      await tester.pumpAndSettle();

      expect(scrollbarPainter.color, const Color(0x00000000));
    },
  );
}
