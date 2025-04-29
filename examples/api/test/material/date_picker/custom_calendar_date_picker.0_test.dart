// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/date_picker/custom_calendar_date_picker.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Text getLastDayText(WidgetTester tester) {
    final Finder dayFinder = find.descendant(of: find.byType(Ink), matching: find.byType(Text));
    return tester.widget(dayFinder.last);
  }

  testWidgets('Days are based on the calendar delegate', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CalendarDatePickerApp());

    final Finder nextMonthButton = find.byIcon(Icons.chevron_right);

    Text lastDayText = getLastDayText(tester);
    expect(find.text('February 2025'), findsOneWidget);
    expect(lastDayText.data, equals('21'));

    await tester.tap(nextMonthButton);
    await tester.pumpAndSettle();

    lastDayText = getLastDayText(tester);
    expect(find.text('March 2025'), findsOneWidget);
    expect(lastDayText.data, equals('28'));

    await tester.tap(nextMonthButton);
    await tester.pumpAndSettle();

    lastDayText = getLastDayText(tester);
    expect(find.text('April 2025'), findsOneWidget);
    expect(lastDayText.data, equals('21'));

    await tester.tap(nextMonthButton);
    await tester.pumpAndSettle();

    lastDayText = getLastDayText(tester);
    expect(lastDayText.data, equals('28'));
  });
}
