// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Scrollbar never goes away until finger lift', (WidgetTester tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: CupertinoScrollbar(
        child: SingleChildScrollView(
          child: SizedBox(width: 4000.0, height: 4000.0),
        ),
      ),
    ));
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(SingleChildScrollView)));
    await gesture.moveBy(const Offset(0.0, -10.0));
    await tester.pump();
    // Scrollbar fully showing
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      color: const Color(0x99777777),
    ));

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    // Still there.
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      color: const Color(0x99777777),
    ));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // Opacity going down now.
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      color: const Color(0x15777777),
    ));
  });

  testWidgets('Scrollbar is not smaller than minLength with large scroll views',
          (WidgetTester tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: CupertinoScrollbar(
        child: SingleChildScrollView(
          child: SizedBox(width: 800.0, height: 20000.0),
        ),
      ),
    ));
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(SingleChildScrollView)));
    await gesture.moveBy(const Offset(0.0, -10.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Height is 36.0.
    final Rect scrollbarRect = Rect.fromLTWH(795.0, 4.28659793814433, 2.5, 36.0);
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      rrect: RRect.fromRectAndRadius(scrollbarRect, const Radius.circular(1.25)),
    ));
  });
}
