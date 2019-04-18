// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Viewport basic test (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Scrollbar(
        child: SingleChildScrollView(
          child: SizedBox(width: 4000.0, height: 4000.0),
        ),
      ),
    ));
    expect(find.byType(Scrollbar), isNot(paints..rect()));
    await tester.fling(find.byType(SingleChildScrollView), const Offset(0.0, -10.0), 10.0);
    expect(find.byType(Scrollbar), paints..rect(rect: Rect.fromLTRB(800.0 - 6.0, 1.5, 800.0, 91.5)));
  });

  testWidgets('Viewport basic test (RTL)', (WidgetTester tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.rtl,
      child: Scrollbar(
        child: SingleChildScrollView(
          child: SizedBox(width: 4000.0, height: 4000.0),
        ),
      ),
    ));
    expect(find.byType(Scrollbar), isNot(paints..rect()));
    await tester.fling(find.byType(SingleChildScrollView), const Offset(0.0, -10.0), 10.0);
    expect(find.byType(Scrollbar), paints..rect(rect: Rect.fromLTRB(0.0, 1.5, 6.0, 91.5)));
  });
}
