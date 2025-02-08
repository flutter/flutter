// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/date_picker/custom_calendar_date_picker.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Days are based on the calendar delegate', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CalendarDatePickerApp());

    final Finder nextMonthButton = find.byIcon(Icons.chevron_right);

    Text lastDayText = tester.getLastDayText();
    expect(lastDayText.data, equals('21'));

    await tester.tap(nextMonthButton);
    await tester.pumpAndSettle();

    lastDayText = tester.getLastDayText();
    expect(lastDayText.data, equals('28'));

    await tester.tap(nextMonthButton);
    await tester.pumpAndSettle();

    lastDayText = tester.getLastDayText();
    expect(lastDayText.data, equals('21'));

    await tester.tap(nextMonthButton);
    await tester.pumpAndSettle();

    lastDayText = tester.getLastDayText();
    expect(lastDayText.data, equals('28'));

    // // Tap the button to show the date picker.
    // await tester.tap(find.byType(OutlinedButton));
    // await tester.pumpAndSettle();

    // // The initial date is shown.
    // expect(find.text(datePickerTitle), findsOneWidget);
    // expect(find.text(initialDate), findsOneWidget);

    // // Tap another date to select it.
    // await tester.tap(find.text('30'));
    // await tester.pumpAndSettle();

    // // The selected date is shown.
    // expect(find.text(datePickerTitle), findsOneWidget);
    // expect(find.text('Fri, Jul 30'), findsOneWidget);

    // // Tap OK to confirm the selection and close the date picker.
    // await tester.tap(find.text('OK'));
    // await tester.pumpAndSettle();

    // // The date picker is closed and the selected date is shown.
    // expect(find.text(datePickerTitle), findsNothing);
    // expect(find.text('Selected: 30/7/2021'), findsOneWidget);
  });
}

extension on WidgetTester {
  Text getLastDayText() {
    final Finder dayFinder = find.descendant(of: find.byType(Ink), matching: find.byType(Text));
    return widget(dayFinder.last);
  }
}
