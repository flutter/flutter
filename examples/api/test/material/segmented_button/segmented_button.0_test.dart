// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/segmented_button/segmented_button.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Segmented button can be used for with a single selection', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SegmentedButtonApp(),
    );

    expect(find.text('Single choice'), findsOne);
    expect(find.text('Day'), findsOne);
    expect(find.text('Week'), findsOne);
    expect(find.text('Month'), findsOne);
    expect(find.text('Year'), findsOne);

    expect(find.byWidgetPredicate(
      (Widget widget) => widget is SegmentedButton<example.Calendar> && setEquals(widget.selected, const <example.Calendar>{example.Calendar.day}),
    ), findsOne);

    // Select the day.
    await tester.tap(find.text('Week'));
    await tester.pump();

    expect(find.byWidgetPredicate(
      (Widget widget) => widget is SegmentedButton<example.Calendar> && setEquals(widget.selected, const <example.Calendar>{example.Calendar.week}),
    ), findsOne);

    // Select the month.
    await tester.tap(find.text('Month'));
    await tester.pump();

    expect(find.byWidgetPredicate(
      (Widget widget) => widget is SegmentedButton<example.Calendar> && setEquals(widget.selected, const <example.Calendar>{example.Calendar.month}),
    ), findsOne);

    // Select the year.
    await tester.tap(find.text('Year'));
    await tester.pump();

    expect(find.byWidgetPredicate(
      (Widget widget) => widget is SegmentedButton<example.Calendar> && setEquals(widget.selected, const <example.Calendar>{example.Calendar.year}),
    ), findsOne);

    // Select the day.
    await tester.tap(find.text('Day'));
    await tester.pump();

    expect(find.byWidgetPredicate(
      (Widget widget) => widget is SegmentedButton<example.Calendar> && setEquals(widget.selected, const <example.Calendar>{example.Calendar.day}),
    ), findsOne);

    // Try to unselect the day.
    await tester.tap(find.text('Day'));
    await tester.pump();

    expect(find.byWidgetPredicate(
      (Widget widget) => widget is SegmentedButton<example.Calendar> && setEquals(widget.selected, const <example.Calendar>{example.Calendar.day}),
    ), findsOne);

  });

  testWidgets('Segmented button can be used for with a multiple selection', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SegmentedButtonApp(),
    );

    expect(find.text('Multiple choice'), findsOne);
    expect(find.text('XS'), findsOne);
    expect(find.text('S'), findsOne);
    expect(find.text('M'), findsOne);
    expect(find.text('L'), findsOne);
    expect(find.text('XL'), findsOne);

    expect(find.byWidgetPredicate(
      (Widget widget) => widget is SegmentedButton<example.Sizes> && setEquals(widget.selected, const <example.Sizes>{example.Sizes.large, example.Sizes.extraLarge}),
    ), findsOne);

    // Select everything.
    await tester.tap(find.text('XS'));
    await tester.pump();
    await tester.tap(find.text('S'));
    await tester.pump();
    await tester.tap(find.text('M'));
    await tester.pump();

    expect(find.byWidgetPredicate(
      (Widget widget) => widget is SegmentedButton<example.Sizes> && setEquals(widget.selected, example.Sizes.values.toSet()),
    ), findsOne);

    // Unselect everything but XS.
    await tester.tap(find.text('S'));
    await tester.pump();
    await tester.tap(find.text('M'));
    await tester.pump();
    await tester.tap(find.text('L'));
    await tester.pump();
    await tester.tap(find.text('XL'));
    await tester.pump();

    expect(find.byWidgetPredicate(
      (Widget widget) => widget is SegmentedButton<example.Sizes> && setEquals(widget.selected, const <example.Sizes>{example.Sizes.extraSmall}),
    ), findsOne);
  });
}
