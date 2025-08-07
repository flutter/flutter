// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/time_picker/show_time_picker.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can open and modify time picker', (WidgetTester tester) async {
    const String openPicker = 'Open time picker';
    final List<String> options = <String>[
      '$TimePickerEntryMode',
      ...TimePickerEntryMode.values.map<String>((TimePickerEntryMode value) => value.name),
      '$ThemeMode',
      ...ThemeMode.values.map<String>((ThemeMode value) => value.name),
      '$TextDirection',
      ...TextDirection.values.map<String>((TextDirection value) => value.name),
      '$MaterialTapTargetSize',
      ...MaterialTapTargetSize.values.map<String>((MaterialTapTargetSize value) => value.name),
      '$Orientation',
      ...Orientation.values.map<String>((Orientation value) => value.name),
      'Time Mode',
      '12-hour am/pm time',
      '24-hour time',
      'Material Version',
      'Material 2',
      'Material 3',
      openPicker,
    ];

    await tester.pumpWidget(const example.ShowTimePickerApp());

    for (final String option in options) {
      expect(
        find.text(option),
        findsOneWidget,
        reason: 'Unable to find $option widget in example.',
      );
    }

    // Open time picker
    await tester.tap(find.text(openPicker));
    await tester.pumpAndSettle();
    expect(find.text('Select time'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    // Close time picker
    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(find.text('Select time'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('OK'), findsNothing);

    // Change an option.
    await tester.tap(find.text('Material 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(openPicker));
    await tester.pumpAndSettle();
    expect(find.text('SELECT TIME'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });
}

testWidgets('AM/PM buttons have correct selected semantics on iOS', (WidgetTester tester) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          return TextButton(
            onPressed: () {
              showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 14, minute: 0),
              );
            },
            child: const Text('Open Picker'),
          );
        },
      ),
    ),
  );

  await tester.tap(find.text('Open Picker'));
  await tester.pumpAndSettle();

  final Finder pmButtonSemantics = find.descendant(
    of: find.widgetWithText(InkWell, 'PM'),
    matching: find.byWidgetPredicate(
      (Widget widget) => widget is Semantics && widget.properties.selected == true,
    ),
  );

  final Finder amButtonSemantics = find.descendant(
    of: find.widgetWithText(InkWell, 'AM'),
    matching: find.byWidgetPredicate(
      (Widget widget) => widget is Semantics && widget.properties.selected == false,
    ),
  );

  expect(pmButtonSemantics, findsOneWidget, reason: 'The selected PM button should have Semantics with selected: true');
  expect(amButtonSemantics, findsOneWidget, reason: 'The unselected AM button should have Semantics with selected: false');

  debugDefaultTargetPlatformOverride = null;
});