// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'feedback_tester.dart';

void main() {
  DateTime firstDate;
  DateTime lastDate;
  DateTimeRange initialDateRange;
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar;

  String cancelText;
  String confirmText;
  String errorInvalidRangeText;
  String errorFormatText;
  String errorInvalidText;
  String fieldStartHintText;
  String fieldEndHintText;
  String fieldStartLabelText;
  String fieldEndLabelText;
  String helpText;
  String saveText;

  setUp(() {
    firstDate = DateTime(2015, DateTime.january, 1);
    lastDate = DateTime(2016, DateTime.december, 31);
    initialDateRange = DateTimeRange(
      start: DateTime(2016, DateTime.january, 15),
      end: DateTime(2016, DateTime.january, 25),
    );
    initialEntryMode = DatePickerEntryMode.calendar;

    cancelText = null;
    confirmText = null;
    errorInvalidRangeText = null;
    errorFormatText = null;
    errorInvalidText = null;
    fieldStartHintText = null;
    fieldEndHintText = null;
    fieldStartLabelText = null;
    fieldEndLabelText = null;
    helpText = null;
    saveText = null;
  });

  Future<void> preparePicker(WidgetTester tester, Future<void> callback(Future<DateTimeRange> date)) async {
    BuildContext buttonContext;
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Builder(
          builder: (BuildContext context) {
            return RaisedButton(
              onPressed: () {
                buttonContext = context;
              },
              child: const Text('Go'),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.text('Go'));
    expect(buttonContext, isNotNull);

    final Future<DateTimeRange> range = showDateRangePicker(
      context: buttonContext,
      initialDateRange: initialDateRange,
      firstDate: firstDate,
      lastDate: lastDate,
      initialEntryMode: initialEntryMode,
      cancelText: cancelText,
      confirmText: confirmText,
      errorInvalidRangeText: errorInvalidRangeText,
      errorFormatText: errorFormatText,
      errorInvalidText: errorInvalidText,
      fieldStartHintText: fieldStartHintText,
      fieldEndHintText: fieldEndHintText,
      fieldStartLabelText: fieldStartLabelText,
      fieldEndLabelText: fieldEndLabelText,
      helpText: helpText,
      saveText: saveText,
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    await callback(range);
  }

  testWidgets('Save and help text is used', (WidgetTester tester) async {
    helpText = 'help';
    saveText = 'make it so';
    await preparePicker(tester, (Future<DateTimeRange> range) async {
      expect(find.text(helpText), findsOneWidget);
      expect(find.text(saveText), findsOneWidget);
    });
  });

  testWidgets('Initial date is the default', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange> range) async {
      await tester.tap(find.text('SAVE'));
      expect(await range, DateTimeRange(
        start: DateTime(2016, DateTime.january, 15),
        end: DateTime(2016, DateTime.january, 25)
      ));
    });
  });

  testWidgets('Can cancel', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange> range) async {
      await tester.tap(find.byIcon(Icons.close));
      expect(await range, isNull);
    });
  });

  testWidgets('Can select a range', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange> range) async {
      await tester.tap(find.text('12').first);
      await tester.tap(find.text('14').first);
      await tester.tap(find.text('SAVE'));
      expect(await range, DateTimeRange(
        start: DateTime(2016, DateTime.january, 12),
        end: DateTime(2016, DateTime.january, 14),
      ));
    });
  });

  testWidgets('Tapping earlier date resets selected range', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange> range) async {
      await tester.tap(find.text('12').first);
      await tester.tap(find.text('11').first);
      await tester.tap(find.text('15').first);
      await tester.tap(find.text('SAVE'));
      expect(await range, DateTimeRange(
        start: DateTime(2016, DateTime.january, 11),
        end: DateTime(2016, DateTime.january, 15),
      ));
    });
  });

  testWidgets('Can select single day range', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange> range) async {
      await tester.tap(find.text('12').first);
      await tester.tap(find.text('12').first);
      await tester.tap(find.text('SAVE'));
      expect(await range, DateTimeRange(
        start: DateTime(2016, DateTime.january, 12),
        end: DateTime(2016, DateTime.january, 12),
      ));
    });
  });

  testWidgets('Cannot select a day outside bounds', (WidgetTester tester) async {
    initialDateRange = DateTimeRange(
      start: DateTime(2017, DateTime.january, 13),
      end: DateTime(2017, DateTime.january, 15),
    );
    firstDate = DateTime(2017, DateTime.january, 12);
    lastDate = DateTime(2017, DateTime.january, 16);
    await preparePicker(tester, (Future<DateTimeRange> range) async {
      // Earlier than firstDate. Should be ignored.
      await tester.tap(find.text('10'));
      // Later than lastDate. Should be ignored.
      await tester.tap(find.text('20'));
      await tester.tap(find.text('SAVE'));
      // We should still be on the initial date.
      expect(await range, initialDateRange);
    });
  });

  testWidgets('Can toggle to input entry mode', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange> range) async {
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });

  testWidgets('Toggle to input mode keeps selected date', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange> range) async {
      await tester.tap(find.text('12').first);
      await tester.tap(find.text('14').first);
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      expect(await range, DateTimeRange(
        start: DateTime(2016, DateTime.january, 12),
        end: DateTime(2016, DateTime.january, 14),
      ));
    });
  });

  group('Haptic feedback', () {
    const Duration hapticFeedbackInterval = Duration(milliseconds: 10);
    FeedbackTester feedback;

    setUp(() {
      feedback = FeedbackTester();
      initialDateRange = DateTimeRange(
        start: DateTime(2017, DateTime.january, 15),
        end: DateTime(2017, DateTime.january, 17),
      );
      firstDate = DateTime(2017, DateTime.january, 10);
      lastDate = DateTime(2018, DateTime.january, 20);
    });

    tearDown(() {
      feedback?.dispose();
    });

    testWidgets('Selecting dates vibrates', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        await tester.tap(find.text('10').first);
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 1);
        await tester.tap(find.text('12').first);
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 2);
        await tester.tap(find.text('14').first);
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 3);
      });
    });

    testWidgets('Tapping unselectable date does not vibrate', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        await tester.tap(find.text('8').first);
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 0);
      });
    });
  });

  group('Input mode', () {
    setUp(() {
      firstDate = DateTime(2015, DateTime.january, 1);
      lastDate = DateTime(2017, DateTime.december, 31);
      initialDateRange = DateTimeRange(
        start: DateTime(2017, DateTime.january, 15),
        end: DateTime(2017, DateTime.january, 17),
      );
      initialEntryMode = DatePickerEntryMode.input;
    });

    testWidgets('Initial entry mode is used', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        expect(find.byType(TextField), findsNWidgets(2));
      });
    });

    testWidgets('All custom strings are used', (WidgetTester tester) async {
      initialDateRange = null;
      cancelText = 'nope';
      confirmText = 'yep';
      fieldStartHintText = 'hint1';
      fieldEndHintText = 'hint2';
      fieldStartLabelText = 'label1';
      fieldEndLabelText = 'label2';
      helpText = 'help';
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        expect(find.text(cancelText), findsOneWidget);
        expect(find.text(confirmText), findsOneWidget);
        expect(find.text(fieldStartHintText), findsOneWidget);
        expect(find.text(fieldEndHintText), findsOneWidget);
        expect(find.text(fieldStartLabelText), findsOneWidget);
        expect(find.text(fieldEndLabelText), findsOneWidget);
        expect(find.text(helpText), findsOneWidget);
      });
    });

    testWidgets('Initial date is the default', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        await tester.tap(find.text('OK'));
        expect(await range, DateTimeRange(
          start: DateTime(2017, DateTime.january, 15),
          end: DateTime(2017, DateTime.january, 17),
        ));
      });
    });

    testWidgets('Can toggle to calendar entry mode', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        expect(find.byType(TextField), findsNWidgets(2));
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
      });
    });

    testWidgets('Toggle to calendar mode keeps selected date', (WidgetTester tester) async {
      initialDateRange = null;
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/25/2016');
        await tester.enterText(find.byType(TextField).at(1), '12/27/2016');
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SAVE'));

        expect(await range, DateTimeRange(
          start: DateTime(2016, DateTime.december, 25),
          end: DateTime(2016, DateTime.december, 27),
        ));
      });
    });

    testWidgets('Entered text returns range', (WidgetTester tester) async {
      initialDateRange = null;
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/25/2016');
        await tester.enterText(find.byType(TextField).at(1), '12/27/2016');
        await tester.tap(find.text('OK'));

        expect(await range, DateTimeRange(
          start: DateTime(2016, DateTime.december, 25),
          end: DateTime(2016, DateTime.december, 27),
        ));
      });
    });

    testWidgets('Too short entered text shows error', (WidgetTester tester) async {
      initialDateRange = null;
      errorFormatText = 'oops';
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/25');
        await tester.enterText(find.byType(TextField).at(1), '12/25');
        expect(find.text(errorFormatText), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text(errorFormatText), findsNWidgets(2));
      });
    });

    testWidgets('Bad format entered text shows error', (WidgetTester tester) async {
      initialDateRange = null;
      errorFormatText = 'oops';
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        await tester.enterText(find.byType(TextField).at(0), '20202014');
        await tester.enterText(find.byType(TextField).at(1), '20212014');
        expect(find.text(errorFormatText), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text(errorFormatText), findsNWidgets(2));
      });
    });

    testWidgets('Invalid entered text shows error', (WidgetTester tester) async {
      initialDateRange = null;
      errorInvalidText = 'oops';
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        await tester.enterText(find.byType(TextField).at(0), '08/08/2014');
        await tester.enterText(find.byType(TextField).at(1), '08/08/2014');
        expect(find.text(errorInvalidText), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text(errorInvalidText), findsNWidgets(2));
      });
    });

    testWidgets('End before start date shows error', (WidgetTester tester) async {
      initialDateRange = null;
      errorInvalidRangeText = 'oops';
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/27/2016');
        await tester.enterText(find.byType(TextField).at(1), '12/25/2016');
        expect(find.text(errorInvalidRangeText), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text(errorInvalidRangeText), findsOneWidget);
      });
    });

    testWidgets('Error text only displayed for invalid date', (WidgetTester tester) async {
      initialDateRange = null;
      errorInvalidText = 'oops';
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/27/2016');
        await tester.enterText(find.byType(TextField).at(1), '01/01/2018');
        expect(find.text(errorInvalidText), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text(errorInvalidText), findsOneWidget);
      });
    });

    testWidgets('End before start date does not get passed to calendar mode', (WidgetTester tester) async {
      initialDateRange = null;
      await preparePicker(tester, (Future<DateTimeRange> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/27/2016');
        await tester.enterText(find.byType(TextField).at(1), '12/25/2016');

        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SAVE'));
        await tester.pumpAndSettle();

        // Save button should be disabled, so dialog should still be up
        // with the first date selected, but no end date
        expect(find.text('Dec 27'), findsOneWidget);
        expect(find.text('End Date'), findsOneWidget);
      });
    });
  });
}
