// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/widgets/annotated_region/annotated_region.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tapping a pane reports its annotated value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.AnnotatedRegionExampleApp());

    // Initially no region has been tapped.
    expect(find.text('No annotation found yet.'), findsOneWidget);

    // Tap the left pane (annotated with value 1).
    await tester.tap(find.text('Left'));
    await tester.pump();
    expect(find.text('Last tapped region value: 1'), findsOneWidget);

    // Tap the right pane (annotated with value 2).
    await tester.tap(find.text('Right'));
    await tester.pump();
    expect(find.text('Last tapped region value: 2'), findsOneWidget);

    // Two annotated regions exist in the tree.
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is AnnotatedRegion<int> &&
            (widget.value == 1 || widget.value == 2),
      ),
      findsNWidgets(2),
    );
  });
}
