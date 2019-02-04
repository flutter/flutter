// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Paints iOS spec', (WidgetTester tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: CupertinoScrollbar(
        child: SingleChildScrollView(
          child: SizedBox(width: 4000.0, height: 4000.0),
        ),
      ),
    ));
    expect(find.byType(CupertinoScrollbar), isNot(paints..rrect()));
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(SingleChildScrollView)));
    await gesture.moveBy(const Offset(0.0, -10.0));
    // Move back to original position.
    await gesture.moveBy(const Offset(0.0, 10.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      color: const Color(0x99777777),
      rrect: RRect.fromRectAndRadius(
        Rect.fromLTWH(
          800.0 - 2.5 - 2.5, // Screen width - margin - thickness.
          4.0, // Initial position is the top margin.
          2.5, // Thickness.
          // Fraction in viewport * scrollbar height - top, bottom margin.
          600.0 / 4000.0 * 600.0 - 4.0 - 4.0,
        ),
        const Radius.circular(1.25),
      ),
    ));
  });
}
