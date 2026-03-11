// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/page_view/page_view.2.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PageView.shrinkWrapCrossAxis example renders and swipes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.ShrinkWrapCrossAxisExampleApp());
    await tester.pumpAndSettle();

    // Verify the first page is shown.
    expect(find.text('Page 1 — Short (100)'), findsOneWidget);

    // The PageView should adapt its height to the first page.
    final pageView = find.byType(PageView);
    expect(pageView, findsOneWidget);

    // Swipe to the second page.
    await tester.fling(pageView, const Offset(-300.0, 0.0), 3000);
    await tester.pumpAndSettle();

    // Verify the second page is shown.
    expect(find.text('Page 2 — Medium (250)'), findsOneWidget);
  });
}
