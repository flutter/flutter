// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/widgets/custom_multi_child_layout/custom_multi_child_layout.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('has all items on screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MyApp(),
    );

    final Finder containerFinder = find.byType(Container);
    expect(containerFinder, findsNWidgets(7));
  });

  testWidgets('has correct constraints when shrunk',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Center(
        child: SizedBox(
            key: Key('parent'),
            width: 500,
            height: 700,
            child: example.MyApp())));

    final Finder parent = find.byKey(const Key('parent'));
    final Size parentSize = tester.getSize(parent);
    final Size childSize = tester.getSize(find.byKey(const Key('Blue')));

    expect(childSize.width.roundToDouble(),
        (parentSize.width / 3).roundToDouble());
    expect(childSize.height.roundToDouble(), 100.0);
  });

  testWidgets('has correct size maximum constraints',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Center(
        child: SizedBox(
            key: Key('parent'),
            width: 800,
            height: 700,
            child: example.MyApp())));

    final Size childSize = tester.getSize(find.byKey(const Key('Blue')));

    expect(childSize.width.roundToDouble(), 200.0);
  });

  testWidgets('row behavior is correct', (WidgetTester tester) async {
    await tester.pumpWidget(const Center(
        child: SizedBox(
            key: Key('parent'),
            width: 800,
            height: 700,
            child: example.MyApp())));

    final Finder child = find.byKey(const Key('Pink'));
    final Size childSize = tester.getSize(find.byKey(const Key('Pink')));
    final Offset childPosition = tester.getBottomRight(child);
    expect(childPosition, Offset(childSize.width, childSize.height * 2 + 56));

    final Finder child1 = find.byKey(const Key('Yellow'));
    final Size childSize1 = tester.getSize(find.byKey(const Key('Yellow')));
    final Offset childPosition1 = tester.getBottomRight(child1);
    expect(
        childPosition1, Offset(childSize1.width, childSize1.height * 3 + 56));

    final Finder child2 = find.byKey(const Key('Purple'));
    final Size childSize2 = tester.getSize(find.byKey(const Key('Purple')));
    final Offset childPosition2 = tester.getBottomRight(child2);
    expect(childPosition2,
        Offset(childSize2.width * 2, childSize2.height * 2 + 56));
  });
}
