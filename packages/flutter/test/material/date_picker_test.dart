// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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

  testWidgets('MonthPicker receives header taps', (WidgetTester tester) async {
    DateTime currentValue;
    bool headerTapped = false;

    final Widget widget = new MaterialApp(
      home: new Material(
        child: new ListView(
          children: <Widget>[
            new MonthPicker(
              selectedDate: new DateTime.utc(2015, 6, 9, 7, 12),
              firstDate: new DateTime.utc(2013),
              lastDate: new DateTime.utc(2018),
              onChanged: (DateTime dateTime) {
                currentValue = dateTime;
              },
              onMonthHeaderTap: () {
                headerTapped = true;
              },
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(widget);

    expect(currentValue, isNull);
    expect(headerTapped, false);
    await tester.tap(find.text('June 2015'));
    expect(headerTapped, true);
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
      final MaterialLocalizations localizations = MaterialLocalizations.of(
        tester.element(find.byType(DayPicker))
      );
      final String dayLabel = localizations.formatMediumDate(new DateTime(2017, DateTime.JANUARY, 15));
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

  group(DayPicker, () {
    final Map<Locale, Map<String, dynamic>> testLocales = <Locale, Map<String, dynamic>>{
      // Tests the default.
      const Locale('en', 'US'): <String, dynamic>{
        'textDirection': TextDirection.ltr,
        'expectedDaysOfWeek': <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'],
        'expectedDaysOfMonth': new List<String>.generate(30, (int i) => '${i + 1}'),
        'expectedMonthYearHeader': 'September 2017',
      },
      // Tests a different first day of week.
      const Locale('ru', 'RU'): <String, dynamic>{
        'textDirection': TextDirection.ltr,
        'expectedDaysOfWeek': <String>['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'],
        'expectedDaysOfMonth': new List<String>.generate(30, (int i) => '${i + 1}'),
        'expectedMonthYearHeader': 'сентябрь 2017 г.',
      },
      // Tests RTL.
      // TODO: change to Arabic numerals when these are fixed:
      // TODO: https://github.com/dart-lang/intl/issues/143
      // TODO: https://github.com/flutter/flutter/issues/12289
      const Locale('ar', 'AR'): <String, dynamic>{
        'textDirection': TextDirection.rtl,
        'expectedDaysOfWeek': <String>['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'],
        'expectedDaysOfMonth': new List<String>.generate(30, (int i) => '${i + 1}'),
        'expectedMonthYearHeader': 'سبتمبر 2017',
      },
    };

    for (Locale locale in testLocales.keys) {
      testWidgets('shows dates for $locale', (WidgetTester tester) async {
        final List<String> expectedDaysOfWeek = testLocales[locale]['expectedDaysOfWeek'];
        final List<String> expectedDaysOfMonth = testLocales[locale]['expectedDaysOfMonth'];
        final String expectedMonthYearHeader = testLocales[locale]['expectedMonthYearHeader'];
        final TextDirection textDirection = testLocales[locale]['textDirection'];
        final DateTime baseDate = new DateTime(2017, 9, 27);

        await _pumpBoilerplate(tester, new DayPicker(
          selectedDate: baseDate,
          currentDate: baseDate,
          onChanged: (DateTime newValue) {},
          firstDate: baseDate.subtract(const Duration(days: 90)),
          lastDate: baseDate.add(const Duration(days: 90)),
          displayedMonth: baseDate,
        ), locale: locale, textDirection: textDirection);

        expect(find.text(expectedMonthYearHeader), findsOneWidget);

        expectedDaysOfWeek.forEach((String dayOfWeek) {
          expect(find.text(dayOfWeek), findsWidgets);
        });

        Offset previousCellOffset;
        expectedDaysOfMonth.forEach((String dayOfMonth) {
          final Finder dayCell = find.descendant(of: find.byType(GridView), matching: find.text(dayOfMonth));
          expect(dayCell, findsOneWidget);

          // Check that cells are correctly positioned relative to each other,
          // taking text direction into account.
          final Offset offset = tester.getCenter(dayCell);
          if (previousCellOffset != null) {
            if (textDirection == TextDirection.ltr) {
              expect(offset.dx > previousCellOffset.dx && offset.dy == previousCellOffset.dy || offset.dy > previousCellOffset.dy, true);
            } else {
              expect(offset.dx < previousCellOffset.dx && offset.dy == previousCellOffset.dy || offset.dy > previousCellOffset.dy, true);
            }
          }
          previousCellOffset = offset;
        });
      });
    }
  });

  testWidgets('locale parameter overrides ambient locale', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      locale: const Locale('en', 'US'),
      supportedLocales: const <Locale>[
        const Locale('en', 'US'),
        const Locale('fr', 'CA'),
      ],
      home: new Material(
        child: new Builder(
          builder: (BuildContext context) {
            return new FlatButton(
              onPressed: () async {
                await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  locale: const Locale('fr', 'CA'),
                );
              },
              child: const Text('X'),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final Element dayPicker = tester.element(find.byType(DayPicker));
    expect(
      Localizations.localeOf(dayPicker),
      const Locale('fr', 'CA'),
    );

    expect(
      Directionality.of(dayPicker),
      TextDirection.ltr,
    );

    await tester.tap(find.text('ANNULER'));
  });

  testWidgets('textDirection parameter overrides ambient textDirection', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      locale: const Locale('en', 'US'),
      supportedLocales: const <Locale>[
        const Locale('en', 'US'),
      ],
      home: new Material(
        child: new Builder(
          builder: (BuildContext context) {
            return new FlatButton(
              onPressed: () async {
                await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  textDirection: TextDirection.rtl,
                );
              },
              child: const Text('X'),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final Element dayPicker = tester.element(find.byType(DayPicker));
    expect(
      Directionality.of(dayPicker),
      TextDirection.rtl,
    );

    await tester.tap(find.text('CANCEL'));
  });

  testWidgets('textDirection parameter takes precendence over locale parameter', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      locale: const Locale('en', 'US'),
      supportedLocales: const <Locale>[
        const Locale('en', 'US'),
        const Locale('fr', 'CA'),
      ],
      home: new Material(
        child: new Builder(
          builder: (BuildContext context) {
            return new FlatButton(
              onPressed: () async {
                await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  locale: const Locale('fr', 'CA'),
                  textDirection: TextDirection.rtl,
                );
              },
              child: const Text('X'),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final Element dayPicker = tester.element(find.byType(DayPicker));
    expect(
      Localizations.localeOf(dayPicker),
      const Locale('fr', 'CA'),
    );

    expect(
      Directionality.of(dayPicker),
      TextDirection.rtl,
    );

    await tester.tap(find.text('ANNULER'));
  });
}

Future<Null> _pumpBoilerplate(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en', 'US'),
  TextDirection textDirection: TextDirection.ltr
}) async {
  await tester.pumpWidget(new Directionality(
    textDirection: TextDirection.ltr,
    child: new Localizations(
      locale: locale,
      delegates: <LocalizationsDelegate<dynamic>>[
        new _MaterialLocalizationsDelegate(
          new DefaultMaterialLocalizations(locale),
        ),
        const DefaultWidgetsLocalizationsDelegate(),
      ],
      child: child,
    ),
  ));
}

class _MaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialLocalizationsDelegate(this.localizations);

  final MaterialLocalizations localizations;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return new SynchronousFuture<MaterialLocalizations>(localizations);
  }

  @override
  bool shouldReload(_MaterialLocalizationsDelegate old) => false;
}

class DefaultWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const DefaultWidgetsLocalizationsDelegate();

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    return new SynchronousFuture<WidgetsLocalizations>(new DefaultWidgetsLocalizations(locale));
  }

  @override
  bool shouldReload(DefaultWidgetsLocalizationsDelegate old) => false;
}
