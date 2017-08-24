// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'feedback_tester.dart';

void main() {
  DateTime firstDate;
  DateTime lastDate;
  DateTime initialDate;
  SelectableDayPredicate selectableDayPredicate;
  DatePickerMode initialDatePickerMode;

  setUp(() {
    firstDate = new DateTime(2001, DateTime.JANUARY, 1);
    lastDate = new DateTime(2031, DateTime.DECEMBER, 31);
    initialDate = new DateTime(2016, DateTime.JANUARY, 15);
    selectableDayPredicate = null;
    initialDatePickerMode = null;
  });

  testWidgets('tap-select a day', (WidgetTester tester) async {
    final Key _datePickerKey = new UniqueKey();
    DateTime _selectedDate = new DateTime(2016, DateTime.JULY, 26);

    await tester.pumpWidget(
      new MaterialApp(
        home: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new Container(
              width: 400.0,
              child: new SingleChildScrollView(
                child: new Material(
                  child: new MonthPicker(
                    firstDate: new DateTime(0),
                    lastDate: new DateTime(9999),
                    key: _datePickerKey,
                    selectedDate: _selectedDate,
                    onChanged: (DateTime value) {
                      setState(() {
                        _selectedDate = value;
                      });
                    },
                  ),
                ),
              ),
            );
          },
        ),
      )
    );

    expect(_selectedDate, equals(new DateTime(2016, DateTime.JULY, 26)));

    await tester.tapAt(const Offset(50.0, 100.0));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(new DateTime(2016, DateTime.JULY, 1)));

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(new DateTime(2016, DateTime.JULY, 1)));

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(new DateTime(2016, DateTime.AUGUST, 5)));

    await tester.drag(find.byKey(_datePickerKey), const Offset(-400.0, 0.0));
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(new DateTime(2016, DateTime.AUGUST, 5)));

    await tester.tap(find.text('25'));
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(new DateTime(2016, DateTime.SEPTEMBER, 25)));

    await tester.drag(find.byKey(_datePickerKey), const Offset(800.0, 0.0));
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(new DateTime(2016, DateTime.SEPTEMBER, 25)));

    await tester.tap(find.text('17'));
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(new DateTime(2016, DateTime.AUGUST, 17)));
  });

  testWidgets('render picker with intrinsic dimensions', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return new IntrinsicWidth(
              child: new IntrinsicHeight(
                child: new Material(
                  child: new SingleChildScrollView(
                    child: new MonthPicker(
                      firstDate: new DateTime(0),
                      lastDate: new DateTime(9999),
                      onChanged: (DateTime value) { },
                      selectedDate: new DateTime(2000, DateTime.JANUARY, 1),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 5));
  });

  Future<Null> preparePicker(WidgetTester tester, Future<Null> callback(Future<DateTime> date)) async {
    BuildContext buttonContext;
    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new Builder(
          builder: (BuildContext context) {
            return new RaisedButton(
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

    final Future<DateTime> date = initialDatePickerMode == null
        // Exercise the argument default for initialDatePickerMode.
        ?
            showDatePicker(
              context: buttonContext,
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
              selectableDayPredicate: selectableDayPredicate,
            )
        :
            showDatePicker(
              context: buttonContext,
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
              selectableDayPredicate: selectableDayPredicate,
              initialDatePickerMode: initialDatePickerMode,
            );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    await callback(date);
  }

  testWidgets('Initial date is the default', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('OK'));
      expect(await date, equals(new DateTime(2016, DateTime.JANUARY, 15)));
    });
  });

  testWidgets('Can cancel', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('CANCEL'));
      expect(await date, isNull);
    });
  });

  testWidgets('Can select a day', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('12'));
      await tester.tap(find.text('OK'));
      expect(await date, equals(new DateTime(2016, DateTime.JANUARY, 12)));
    });
  });

  testWidgets('Can select a month', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('25'));
      await tester.tap(find.text('OK'));
      expect(await date, equals(new DateTime(2015, DateTime.DECEMBER, 25)));
    });
  });

  testWidgets('Can select a year', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('2016'));
      await tester.pump();
      await tester.tap(find.text('2018'));
      await tester.tap(find.text('OK'));
      expect(await date, equals(new DateTime(2018, DateTime.JANUARY, 15)));
    });
  });

  testWidgets('Can select a year and then a day', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('2016'));
      await tester.pump();
      await tester.tap(find.text('2017'));
      await tester.pump();
      final String dayLabel = new DateFormat('E, MMM\u00a0d').format(new DateTime(2017, DateTime.JANUARY, 15));
      await tester.tap(find.text(dayLabel));
      await tester.pump();
      await tester.tap(find.text('19'));
      await tester.tap(find.text('OK'));
      expect(await date, equals(new DateTime(2017, DateTime.JANUARY, 19)));
    });
  });

  testWidgets('Current year is initially visible in year picker', (WidgetTester tester) async {
    initialDate = new DateTime(2000);
    firstDate = new DateTime(1900);
    lastDate = new DateTime(2100);
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('2000'));
      await tester.pump();
      expect(find.text('2000'), findsNWidgets(2));
    });
  });

  testWidgets('Cannot select a day outside bounds', (WidgetTester tester) async {
    initialDate = new DateTime(2017, DateTime.JANUARY, 15);
    firstDate = initialDate;
    lastDate = initialDate;
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('10')); // Earlier than firstDate. Should be ignored.
      await tester.tap(find.text('20')); // Later than lastDate. Should be ignored.
      await tester.tap(find.text('OK'));
      // We should still be on the initial date.
      expect(await date, equals(initialDate));
    });
  });

  testWidgets('Cannot select a month past last date', (WidgetTester tester) async {
    initialDate = new DateTime(2017, DateTime.JANUARY, 15);
    firstDate = initialDate;
    lastDate = new DateTime(2017, DateTime.FEBRUARY, 20);
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // Shouldn't be possible to keep going into March.
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // We're still in February
      await tester.tap(find.text('20'));
      // Days outside bound for new month pages also disabled.
      await tester.tap(find.text('25'));
      await tester.tap(find.text('OK'));
      expect(await date, equals(new DateTime(2017, DateTime.FEBRUARY, 20)));
    });
  });

  testWidgets('Cannot select a month before first date', (WidgetTester tester) async {
    initialDate = new DateTime(2017, DateTime.JANUARY, 15);
    firstDate = new DateTime(2016, DateTime.DECEMBER, 10);
    lastDate = initialDate;
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // Shouldn't be possible to keep going into November.
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // We're still in December
      await tester.tap(find.text('10'));
      // Days outside bound for new month pages also disabled.
      await tester.tap(find.text('5'));
      await tester.tap(find.text('OK'));
      expect(await date, equals(new DateTime(2016, DateTime.DECEMBER, 10)));
    });
  });

  testWidgets('Only predicate days are selectable', (WidgetTester tester) async {
    initialDate = new DateTime(2017, DateTime.JANUARY, 16);
    firstDate = new DateTime(2017, DateTime.JANUARY, 10);
    lastDate = new DateTime(2017, DateTime.JANUARY, 20);
    selectableDayPredicate = (DateTime day) => day.day.isEven;
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('10')); // Even, works.
      await tester.tap(find.text('13')); // Odd, doesn't work.
      await tester.tap(find.text('17')); // Odd, doesn't work.
      await tester.tap(find.text('OK'));
      expect(await date, equals(new DateTime(2017, DateTime.JANUARY, 10)));
    });
  });

  testWidgets('Can select initial date picker mode', (WidgetTester tester) async {
    initialDate = new DateTime(2014, DateTime.JANUARY, 15);
    initialDatePickerMode = DatePickerMode.year;
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.pump();
      // 2018 wouldn't be available if the year picker wasn't showing.
      // The initial current year is 2014.
      await tester.tap(find.text('2018'));
      await tester.tap(find.text('OK'));
      expect(await date, equals(new DateTime(2018, DateTime.JANUARY, 15)));
    });
  });

  group('haptic feedback', () {
    const Duration kHapticFeedbackInterval = const Duration(milliseconds: 10);
    FeedbackTester feedback;

    setUp(() {
      feedback = new FeedbackTester();
      initialDate = new DateTime(2017, DateTime.JANUARY, 16);
      firstDate = new DateTime(2017, DateTime.JANUARY, 10);
      lastDate = new DateTime(2018, DateTime.JANUARY, 20);
      selectableDayPredicate = (DateTime date) => date.day.isEven;
    });

    tearDown(() {
      feedback?.dispose();
    });

    testWidgets('tap-select date vibrates', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('10'));
        await tester.pump(kHapticFeedbackInterval);
        expect(feedback.hapticCount, 1);
        await tester.tap(find.text('12'));
        await tester.pump(kHapticFeedbackInterval);
        expect(feedback.hapticCount, 2);
        await tester.tap(find.text('14'));
        await tester.pump(kHapticFeedbackInterval);
        expect(feedback.hapticCount, 3);
      });
    });

    testWidgets('tap-select unselectable date does not vibrate', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('11'));
        await tester.pump(kHapticFeedbackInterval);
        expect(feedback.hapticCount, 0);
        await tester.tap(find.text('13'));
        await tester.pump(kHapticFeedbackInterval);
        expect(feedback.hapticCount, 0);
        await tester.tap(find.text('15'));
        await tester.pump(kHapticFeedbackInterval);
        expect(feedback.hapticCount, 0);
      });
    });

    testWidgets('mode, year change vibrates', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('2017'));
        await tester.pump(kHapticFeedbackInterval);
        expect(feedback.hapticCount, 1);
        await tester.tap(find.text('2018'));
        await tester.pump(kHapticFeedbackInterval);
        expect(feedback.hapticCount, 2);
      });
    });

  });

  test('days in month', () {
    expect(DayPicker.getDaysInMonth(2017, 10), 31);
    expect(DayPicker.getDaysInMonth(2017, 6), 30);
    expect(DayPicker.getDaysInMonth(2017, 2), 28);
    expect(DayPicker.getDaysInMonth(2016, 2), 29);
    expect(DayPicker.getDaysInMonth(2000, 2), 29);
    expect(DayPicker.getDaysInMonth(1900, 2), 28);
  });

  testWidgets('month header tap', (WidgetTester tester) async {
    selectableDayPredicate = null;
    await preparePicker(tester, (Future<DateTime> date) async {
      // Switch into the year selector.
      await tester.tap(find.text('January 2016'));
      await tester.pump();
      expect(find.text('2020'), isNotNull);

      await tester.tap(find.text('CANCEL'));
      expect(await date, isNull);
    });
  });
}
