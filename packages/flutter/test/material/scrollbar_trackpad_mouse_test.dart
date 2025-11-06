// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/gestures.dart' show PointerExitEvent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> main() async {
  // Place for me to list other test ideas:
  // - Make sure that MaterialScrollBehavior returns a Scrollbar by default on Android
  testWidgets('The scrollbar is visible by default when a mouse is used to scroll', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Scrollbar(
          child: ListView.builder(
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );
    print('widget pumped');

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

    // TODO(camsim99): look into this
    expect(scrollbarPainter.color, isNot(const Color(0x00000000)));

    final TestPointer trackpadPointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(trackpadPointer.hover(tester.getCenter(find.byType(ListView))));
    await tester.sendEventToBinding(trackpadPointer.scroll(const Offset(0, -300)));
    await tester.pump();

    expect(scrollbarPainter.color, isNot(const Color(0x00000000)));

    // await tester.sendEventToBinding(trackpadPointer.scrollInertiaCancel());

    // final TestPointer fingerPointer = TestPointer(2);
    // await tester.sendEventToBinding(fingerPointer.down(tester.getCenter(find.byType(ListView))));
    // await tester.pumpAndSettle();

    await tester.sendEventToBinding(
      PointerExitEvent(
        position: tester.getCenter(find.byType(ListView)),
        device: 1,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pumpAndSettle();

    expect(scrollbarPainter.color, const Color(0x00000000));
  });
}
