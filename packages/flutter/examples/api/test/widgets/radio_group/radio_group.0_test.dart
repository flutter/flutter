// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/radio_group/radio_group.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Radio Smoke Test - character', (WidgetTester tester) async {
    await tester.pumpWidget(const example.RadioExampleApp());

    expect(find.widgetWithText(AppBar, 'Radio Group Sample'), findsOneWidget);
    final Finder listTile1 = find.widgetWithText(ListTile, 'Lafayette');
    expect(listTile1, findsOneWidget);
    final Finder listTile2 = find.widgetWithText(ListTile, 'Thomas Jefferson');
    expect(listTile2, findsOneWidget);

    final Finder radioButton1 = find
        .byType(Radio<example.SingingCharacter>)
        .first;
    final Finder radioButton2 = find
        .byType(Radio<example.SingingCharacter>)
        .last;
    final Finder radioGroup = find
        .byType(RadioGroup<example.SingingCharacter>)
        .last;

    await tester.tap(radioButton1);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<RadioGroup<example.SingingCharacter>>(radioGroup)
          .groupValue,
      tester.widget<Radio<example.SingingCharacter>>(radioButton1).value,
    );
    expect(
      tester
          .widget<RadioGroup<example.SingingCharacter>>(radioGroup)
          .groupValue,
      isNot(tester.widget<Radio<example.SingingCharacter>>(radioButton2).value),
    );
    await tester.tap(radioButton2);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<RadioGroup<example.SingingCharacter>>(radioGroup)
          .groupValue,
      isNot(tester.widget<Radio<example.SingingCharacter>>(radioButton1).value),
    );
    expect(
      tester
          .widget<RadioGroup<example.SingingCharacter>>(radioGroup)
          .groupValue,
      tester.widget<Radio<example.SingingCharacter>>(radioButton2).value,
    );
  });

  testWidgets('Radio Smoke Test - genre', (WidgetTester tester) async {
    await tester.pumpWidget(const example.RadioExampleApp());

    expect(find.widgetWithText(AppBar, 'Radio Group Sample'), findsOneWidget);
    final Finder listTile1 = find.widgetWithText(ListTile, 'Metal');
    expect(listTile1, findsOneWidget);
    final Finder listTile2 = find.widgetWithText(ListTile, 'Jazz');
    expect(listTile2, findsOneWidget);

    final Finder radioButton1 = find.byType(Radio<example.Genre>).first;
    final Finder radioButton2 = find.byType(Radio<example.Genre>).last;
    final Finder radioGroup = find.byType(RadioGroup<example.Genre>).last;

    await tester.tap(radioButton1);
    await tester.pumpAndSettle();
    expect(
      tester.widget<RadioGroup<example.Genre>>(radioGroup).groupValue,
      tester.widget<Radio<example.Genre>>(radioButton1).value,
    );
    expect(
      tester.widget<RadioGroup<example.Genre>>(radioGroup).groupValue,
      isNot(tester.widget<Radio<example.Genre>>(radioButton2).value),
    );
    await tester.tap(radioButton2);
    await tester.pumpAndSettle();
    expect(
      tester.widget<RadioGroup<example.Genre>>(radioGroup).groupValue,
      isNot(tester.widget<Radio<example.Genre>>(radioButton1).value),
    );
    expect(
      tester.widget<RadioGroup<example.Genre>>(radioGroup).groupValue,
      tester.widget<Radio<example.Genre>>(radioButton2).value,
    );
  });
}
