// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  DateTime firstDate;
  DateTime lastDate;
  DateTime initialDate;
  SelectableDayPredicate selectableDayPredicate;

  setUp(() {
    firstDate = new DateTime(2001, DateTime.JANUARY, 1);
    lastDate = new DateTime(2031, DateTime.DECEMBER, 31);
    initialDate = new DateTime(2016, DateTime.JANUARY, 15);
  });

  testWidgets('tap-select a day', (WidgetTester tester) async {
    final Key _datePickerKey = new UniqueKey();
    DateTime _selectedDate = new DateTime(2016, DateTime.JULY, 26);

    await tester.pumpWidget(
      new Overlay(
        initialEntries: <OverlayEntry>[
          new OverlayEntry(
            builder: (BuildContext context) => new StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return new Positioned(
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
          ),
        ],
      ),
    );
    expect(_selectedDate, equals(new DateTime(2016, DateTime.JULY, 26)));

    await tester.tapAt(const Point(50.0, 100.0));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.JULY, 26)));
    await tester.pump(const Duration(seconds: 2));

    await tester.tapAt(const Point(300.0, 100.0));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.JULY, 1)));
    await tester.pump(const Duration(seconds: 2));

    await tester.tapAt(const Point(380.0, 20.0));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.JULY, 1)));

    await tester.tapAt(const Point(300.0, 100.0));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.AUGUST, 5)));
    await tester.pump(const Duration(seconds: 2));

    await tester.drag(find.byKey(_datePickerKey), const Offset(-300.0, 0.0));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.AUGUST, 5)));

    await tester.tapAt(const Point(45.0, 270.0));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.SEPTEMBER, 25)));
    await tester.pump(const Duration(seconds: 2));

    await tester.drag(find.byKey(_datePickerKey), const Offset(300.0, 0.0));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.SEPTEMBER, 25)));

    await tester.tapAt(const Point(210.0, 180.0));
    expect(_selectedDate, equals(new DateTime(2016, DateTime.AUGUST, 17)));
  });

  testWidgets('render picker with intrinsic dimensions', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Overlay(
        initialEntries: <OverlayEntry>[
          new OverlayEntry(
            builder: (BuildContext context) => new StatefulBuilder(
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
        ],
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

    final Future<DateTime> date = showDatePicker(
      context: buttonContext,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: selectableDayPredicate
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
      await tester.tap(find.text('2006'));
      await tester.tap(find.text('OK'));
      expect(await date, equals(new DateTime(2006, DateTime.JANUARY, 15)));
    });
  });

  testWidgets('Can select a year and then a day', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('2016'));
      await tester.pump();
      await tester.tap(find.text('2005'));
      await tester.pump();
      final String dayLabel = new DateFormat('E, MMM\u00a0d').format(new DateTime(2005, DateTime.JANUARY, 15));
      await tester.tap(find.text(dayLabel));
      await tester.pump();
      await tester.tap(find.text('19'));
      await tester.tap(find.text('OK'));
      expect(await date, equals(new DateTime(2005, DateTime.JANUARY, 19)));
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
      // We should still be on the inital date.
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

  group('haptic feedback', () {
    const Duration kHapticFeedbackInterval = const Duration(milliseconds: 10);
    int hapticFeedbackCount;

    setUpAll(() {
      SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == "HapticFeedback.vibrate")
          hapticFeedbackCount++;
      });
    });

    setUp(() {
      hapticFeedbackCount = 0;
      initialDate = new DateTime(2017, DateTime.JANUARY, 16);
      firstDate = new DateTime(2017, DateTime.JANUARY, 10);
      lastDate = new DateTime(2018, DateTime.JANUARY, 20);
      selectableDayPredicate = (DateTime date) => date.day.isEven;
    });

    testWidgets('tap-select date vibrates', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('10'));
        await tester.pump(kHapticFeedbackInterval);
        expect(hapticFeedbackCount, 1);
        await tester.tap(find.text('12'));
        await tester.pump(kHapticFeedbackInterval);
        expect(hapticFeedbackCount, 2);
        await tester.tap(find.text('14'));
        await tester.pump(kHapticFeedbackInterval);
        expect(hapticFeedbackCount, 3);
      });
    });

    testWidgets('tap-select unselectable date does not vibrate', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('11'));
        await tester.pump(kHapticFeedbackInterval);
        expect(hapticFeedbackCount, 0);
        await tester.tap(find.text('13'));
        await tester.pump(kHapticFeedbackInterval);
        expect(hapticFeedbackCount, 0);
        await tester.tap(find.text('15'));
        await tester.pump(kHapticFeedbackInterval);
        expect(hapticFeedbackCount, 0);
      });
    });

    testWidgets('mode, year change vibrates', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('2017'));
        await tester.pump(kHapticFeedbackInterval);
        expect(hapticFeedbackCount, 1);
        await tester.tap(find.text('2018'));
        await tester.pump(kHapticFeedbackInterval);
        expect(hapticFeedbackCount, 2);
      });
    });
  });
}
