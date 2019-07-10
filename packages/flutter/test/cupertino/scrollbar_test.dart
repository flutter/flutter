// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  const Duration _kScrollbarTimeToFade = Duration(milliseconds: 1200);
  const Duration _kScrollbarFadeDuration = Duration(milliseconds: 250);

  testWidgets('Scrollbar never goes away until finger lift', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(),
          child: CupertinoScrollbar(
            child: SingleChildScrollView(child: SizedBox(width: 4000.0, height: 4000.0)),
          ),
        ),
      ),
    );
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
    await tester.pump(_kScrollbarTimeToFade);
    await tester.pump(_kScrollbarFadeDuration * 0.5);

    // Opacity going down now.
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      color: const Color(0x77777777),
    ));
  });

  testWidgets('Scrollbar grows when long pressed', (WidgetTester tester) async {
    bool calledOnDragScrollbar = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: CupertinoScrollbar(
            onDragScrollbar: (double primaryDelta) {
              calledOnDragScrollbar = true;
            },
            child: const SingleChildScrollView(child: SizedBox(width: 4000.0, height: 4000.0)),
          ),
        ),
      ),
    );

    // Scroll a bit.
    final TestGesture scrollGesture = await tester.startGesture(tester.getCenter(find.byType(SingleChildScrollView)));
    await scrollGesture.moveBy(const Offset(0.0, -10.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Scrollbar is fully showing and DragScrollbar hasn't happened.
    expect(find.byType(CupertinoScrollbar), paints..rrect(
      color: const Color(0x99777777),
    ));
    expect(calledOnDragScrollbar, false);
    await scrollGesture.up();
    await tester.pump();

    // Longpress on the scrollbar.
    final TestGesture dragScrollbarGesture = await tester.startGesture(const Offset(796.0, 50.0));
    await tester.pump(const Duration(milliseconds: 500));

    // Drag the scrollbar.
    await dragScrollbarGesture.moveBy(const Offset(0.0, -10.0));
    await tester.pump(const Duration(milliseconds: 500));
    await dragScrollbarGesture.up();
    await tester.pumpAndSettle();
    // The onDragScrollbar callback was called.
    expect(calledOnDragScrollbar, true);
  });
}
