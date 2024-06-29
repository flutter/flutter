// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/nested_scroll_view/nested_scroll_view.3.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Scroll down and verify Stretch effect in NestedScrollView', (WidgetTester tester) async {
    const double expandedAppBarHeight = 200.0;
    await tester.pumpWidget(const example.NestedScrollViewExampleApp());
    expect(find.text('Stretch Nested SliverAppBar'), findsOneWidget);
    expect(find.byType(NestedScrollView), findsOneWidget);
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(tester.getSize(find.byType(AppBar, skipOffstage: false)).height, expandedAppBarHeight);

    final Offset point1 = tester.getCenter(find.text('Item 3'));
    await tester.dragFrom(point1, const Offset(0.0, 50.0));
    await tester.pump();
    expect(tester.getSize(find.byType(AppBar, skipOffstage: false)).height, greaterThan(expandedAppBarHeight));

    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AppBar, skipOffstage: false)).height, expandedAppBarHeight);
  });
}
