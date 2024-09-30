// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/painting/star_border/star_border.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('main ...', (WidgetTester tester) async {
    await tester.pumpWidget(const example.StarBorderApp());

    expect(find.descendant(
      of: find.byType(Scaffold),
      matching: find.widgetWithText(AppBar, 'StarBorder Example'),
    ), findsOne);

    expect(find.descendant(
      of: find.byType(Scaffold),
      matching: find.byType(example.StarBorderExample),
    ), findsOne);

    expect(find.descendant(
      of: find.byType(example.StarBorderExample),
      matching: find.byType(ListView),
    ), findsOne);

    expect(find.descendant(
      of: find.byType(ListView),
      matching: find.byType(example.ExampleBorder),
    ), findsExactly(2));

    expect(find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Slider),
    ), findsExactly(6));

    expect(find.descendant(
      of: find.byType(ListView),
      matching: find.byWidgetPredicate((Widget pre)=>pre is SelectableText && pre.data!.startsWith('Container(')),
    ), findsExactly(2));

    final Finder starFinder = find.byType(example.ExampleBorder).first;
    example.ExampleBorder exampleBorder = tester.widget<example.ExampleBorder>(starFinder);

    // Defaults
    expect(exampleBorder.border.points, equals(5));
    expect(exampleBorder.border.innerRadiusRatio, equals(0.4));
    expect(exampleBorder.border.pointRounding, equals(0.0));
    expect(exampleBorder.border.valleyRounding, equals(0.0));
    expect(exampleBorder.border.squash, equals(0.0));
    expect(exampleBorder.border.rotation, equals(0.0));

    const Offset offset = Offset(10, 0);
    await tester.drag(find.descendant(
      of: find.byWidgetPredicate((Widget w)=> w is example.ControlSlider && w.label=='Points'),
      matching: find.byType(Slider),
    ), offset);
    await tester.drag(find.descendant(
      of: find.byWidgetPredicate((Widget w)=> w is example.ControlSlider && w.label=='Inner Radius'),
      matching: find.byType(Slider),
    ), offset);
    await tester.drag(find.descendant(
      of: find.byWidgetPredicate((Widget w)=> w is example.ControlSlider && w.label=='Point Rounding'),
      matching: find.byType(Slider)
    ), offset);
    await tester.drag(find.descendant(
      of: find.byWidgetPredicate((Widget w)=> w is example.ControlSlider && w.label=='Valley Rounding'),
      matching: find.byType(Slider)
    ), offset);
    await tester.drag(find.descendant(
      of: find.byWidgetPredicate((Widget w)=> w is example.ControlSlider && w.label=='Squash'),
      matching: find.byType(Slider)
    ), offset);
    await tester.drag(find.descendant(
      of: find.byWidgetPredicate((Widget w)=> w is example.ControlSlider && w.label=='Rotation'),
      matching: find.byType(Slider)
    ), offset);
    await tester.pump();
    exampleBorder = tester.widget<example.ExampleBorder>(starFinder);
    // Not defaults
    expect(exampleBorder.border.points, isNot(equals(5)));
    expect(exampleBorder.border.innerRadiusRatio, isNot(equals(0.4)));
    expect(exampleBorder.border.pointRounding, isNot(equals(0.0)));
    expect(exampleBorder.border.valleyRounding, isNot(equals(0.0)));
    expect(exampleBorder.border.squash, isNot(equals(0.0)));
    expect(exampleBorder.border.rotation, isNot(equals(0.0)));

    expect(find.descendant(
      of: find.byType(ListView),
      matching: find.byWidgetPredicate((Widget pre)=>
        pre is SelectableText &&
        pre.data!.startsWith('Container(') &&
        pre.data!.contains('points: ${exampleBorder.border.points}') &&
        pre.data!.contains('rotation: ${exampleBorder.border.rotation}') &&
        pre.data!.contains('innerRadiusRatio: ${exampleBorder.border.innerRadiusRatio}') &&
        pre.data!.contains('pointRounding: ${exampleBorder.border.pointRounding}') &&
        pre.data!.contains('valleyRounding: ${exampleBorder.border.valleyRounding}') &&
        pre.data!.contains('squash: ${exampleBorder.border.squash}'))
    ), findsOne);

    expect(find.descendant(
      of: find.byType(ListView),
      matching: find.byWidgetPredicate((Widget pre)=>
        pre is SelectableText &&
        pre.data!.startsWith('Container(') &&
        pre.data!.contains('sides: ${exampleBorder.border.points}') &&
        pre.data!.contains('rotation: ${exampleBorder.border.rotation}') &&
        pre.data!.contains('cornerRounding: ${exampleBorder.border.pointRounding}') &&
        pre.data!.contains('squash: ${exampleBorder.border.squash}'))
    ), findsOne);

    expect(exampleBorder.border.points, isNot(exampleBorder.border.points.roundToDouble()));
    final Finder nearestFinder = find.widgetWithText(OutlinedButton, 'Nearest');
    expect(nearestFinder, findsOne);
    await tester.tap(nearestFinder);
    await tester.pumpAndSettle();
    exampleBorder = tester.widget<example.ExampleBorder>(starFinder);
    expect(exampleBorder.border.points, exampleBorder.border.points.roundToDouble());

    final Finder resetFinder = find.widgetWithText(ElevatedButton, 'Reset');
    expect(resetFinder, findsOne);
    await tester.tap(resetFinder);
    await tester.pumpAndSettle();
    exampleBorder = tester.widget<example.ExampleBorder>(starFinder);
    // Defaults
    expect(exampleBorder.border.points, equals(5));
    expect(exampleBorder.border.innerRadiusRatio, equals(0.4));
    expect(exampleBorder.border.pointRounding, equals(0.0));
    expect(exampleBorder.border.valleyRounding, equals(0.0));
    expect(exampleBorder.border.squash, equals(0.0));
    expect(exampleBorder.border.rotation, equals(0.0));
  });
}
