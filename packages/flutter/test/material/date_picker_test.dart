// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;

import '../widgets/semantics_tester.dart';
import 'feedback_tester.dart';

void main() {
  group('showDatePicker', () {
    _tests();
  });
}

void _tests() {
  DateTime firstDate;
  DateTime lastDate;
  DateTime initialDate;
  SelectableDayPredicate selectableDayPredicate;
  DatePickerMode initialDatePickerMode;
  final Finder nextMonthIcon = find.byWidgetPredicate((Widget w) => w is IconButton && (w.tooltip?.startsWith('Next month') ?? false));
  final Finder previousMonthIcon = find.byWidgetPredicate((Widget w) => w is IconButton && (w.tooltip?.startsWith('Previous month') ?? false));

  setUp(() {
    firstDate = DateTime(2001, DateTime.january, 1);
    lastDate = DateTime(2031, DateTime.december, 31);
    initialDate = DateTime(2016, DateTime.january, 15);
    selectableDayPredicate = null;
    initialDatePickerMode = null;
  });

  testWidgets('tap-select a day', (WidgetTester tester) async {
    final Key _datePickerKey = UniqueKey();
    DateTime _selectedDate = DateTime(2016, DateTime.july, 26);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              width: 400.0,
              child: SingleChildScrollView(
                dragStartBehavior: DragStartBehavior.down,
                child: Material(
                  child: MonthPicker(
                    dragStartBehavior: DragStartBehavior.down,
                    firstDate: DateTime(0),
                    lastDate: DateTime(9999),
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
    );

    expect(_selectedDate, equals(DateTime(2016, DateTime.july, 26)));

    await tester.tapAt(const Offset(50.0, 100.0));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(DateTime(2016, DateTime.july, 1)));

    await tester.tap(nextMonthIcon);
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(DateTime(2016, DateTime.july, 1)));

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(DateTime(2016, DateTime.august, 5)));

    await tester.drag(find.byKey(_datePickerKey), const Offset(-400.0, 0.0));
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(DateTime(2016, DateTime.august, 5)));

    await tester.tap(find.text('25'));
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(DateTime(2016, DateTime.september, 25)));

    await tester.drag(find.byKey(_datePickerKey), const Offset(800.0, 0.0));
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(DateTime(2016, DateTime.september, 25)));

    await tester.tap(find.text('17'));
    await tester.pumpAndSettle();
    expect(_selectedDate, equals(DateTime(2016, DateTime.august, 17)));
  });

  testWidgets('render picker with intrinsic dimensions', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return IntrinsicWidth(
              child: IntrinsicHeight(
                child: Material(
                  child: SingleChildScrollView(
                    child: MonthPicker(
                      firstDate: DateTime(0),
                      lastDate: DateTime(9999),
                      onChanged: (DateTime value) { },
                      selectedDate: DateTime(2000, DateTime.january, 1),
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

  Future<void> preparePicker(WidgetTester tester, Future<void> callback(Future<DateTime> date)) async {
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
      expect(await date, equals(DateTime(2016, DateTime.january, 15)));
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
      expect(await date, equals(DateTime(2016, DateTime.january, 12)));
    });
  });

  testWidgets('Can select a month', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(previousMonthIcon);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('25'));
      await tester.tap(find.text('OK'));
      expect(await date, equals(DateTime(2015, DateTime.december, 25)));
    });
  });

  testWidgets('Can select a year', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('2016'));
      await tester.pump();
      await tester.tap(find.text('2018'));
      await tester.tap(find.text('OK'));
      expect(await date, equals(DateTime(2018, DateTime.january, 15)));
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
      final String dayLabel = localizations.formatMediumDate(DateTime(2017, DateTime.january, 15));
      await tester.tap(find.text(dayLabel));
      await tester.pump();
      await tester.tap(find.text('19'));
      await tester.tap(find.text('OK'));
      expect(await date, equals(DateTime(2017, DateTime.january, 19)));
    });
  });

  testWidgets('Current year is initially visible in year picker', (WidgetTester tester) async {
    initialDate = DateTime(2000);
    firstDate = DateTime(1900);
    lastDate = DateTime(2100);
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('2000'));
      await tester.pump();
      expect(find.text('2000'), findsNWidgets(2));
    });
  });

  testWidgets('Cannot select a day outside bounds', (WidgetTester tester) async {
    initialDate = DateTime(2017, DateTime.january, 15);
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
    initialDate = DateTime(2017, DateTime.january, 15);
    firstDate = initialDate;
    lastDate = DateTime(2017, DateTime.february, 20);
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(nextMonthIcon);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // Shouldn't be possible to keep going into March.
      expect(nextMonthIcon, findsNothing);
    });
  });

  testWidgets('Cannot select a month before first date', (WidgetTester tester) async {
    initialDate = DateTime(2017, DateTime.january, 15);
    firstDate = DateTime(2016, DateTime.december, 10);
    lastDate = initialDate;
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(previousMonthIcon);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // Shouldn't be possible to keep going into November.
      expect(previousMonthIcon, findsNothing);
    });
  });

  testWidgets('Selecting firstDate year respects firstDate', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/17309
    initialDate = DateTime(2018, DateTime.may, 4);
    firstDate = DateTime(2016, DateTime.june, 9);
    lastDate = DateTime(2019, DateTime.january, 15);
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('2018'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2016'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(await date, DateTime(2016, DateTime.june, 9));
    });
  });

  testWidgets('Selecting lastDate year respects lastDate', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/17309
    initialDate = DateTime(2018, DateTime.may, 4);
    firstDate = DateTime(2016, DateTime.june, 9);
    lastDate = DateTime(2019, DateTime.january, 15);
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('2018'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2019'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(await date, DateTime(2019, DateTime.january, 15));
    });
  });


  testWidgets('Only predicate days are selectable', (WidgetTester tester) async {
    initialDate = DateTime(2017, DateTime.january, 16);
    firstDate = DateTime(2017, DateTime.january, 10);
    lastDate = DateTime(2017, DateTime.january, 20);
    selectableDayPredicate = (DateTime day) => day.day.isEven;
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.tap(find.text('10')); // Even, works.
      await tester.tap(find.text('13')); // Odd, doesn't work.
      await tester.tap(find.text('17')); // Odd, doesn't work.
      await tester.tap(find.text('OK'));
      expect(await date, equals(DateTime(2017, DateTime.january, 10)));
    });
  });

  testWidgets('Can select initial date picker mode', (WidgetTester tester) async {
    initialDate = DateTime(2014, DateTime.january, 15);
    initialDatePickerMode = DatePickerMode.year;
    await preparePicker(tester, (Future<DateTime> date) async {
      await tester.pump();
      // 2018 wouldn't be available if the year picker wasn't showing.
      // The initial current year is 2014.
      await tester.tap(find.text('2018'));
      await tester.tap(find.text('OK'));
      expect(await date, equals(DateTime(2018, DateTime.january, 15)));
    });
  });

  group('haptic feedback', () {
    const Duration kHapticFeedbackInterval = Duration(milliseconds: 10);
    FeedbackTester feedback;

    setUp(() {
      feedback = FeedbackTester();
      initialDate = DateTime(2017, DateTime.january, 16);
      firstDate = DateTime(2017, DateTime.january, 10);
      lastDate = DateTime(2018, DateTime.january, 20);
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

  testWidgets('exports semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await preparePicker(tester, (Future<DateTime> date) async {
      final TestSemantics expected = TestSemantics(
        flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
        children: <TestSemantics>[
          TestSemantics(
            elevation: 24.0,
            thickness: 0.0,
            children: <TestSemantics>[
              TestSemantics(
                flags: <SemanticsFlag>[SemanticsFlag.isFocusable],
                actions: <SemanticsAction>[SemanticsAction.tap],
                label: '2016',
                textDirection: TextDirection.ltr,
              ),
              TestSemantics(
                flags: <SemanticsFlag>[
                  SemanticsFlag.isSelected,
                  SemanticsFlag.isFocusable,
                ],
                actions: <SemanticsAction>[SemanticsAction.tap],
                label: 'Fri, Jan 15',
                textDirection: TextDirection.ltr,
              ),
              TestSemantics(
                children: <TestSemantics>[
                  TestSemantics(
                    id: 55,
                    actions: <SemanticsAction>[SemanticsAction.scrollLeft, SemanticsAction.scrollRight],
                    children: <TestSemantics>[
                      TestSemantics(
                        children: <TestSemantics>[
                          TestSemantics(
                            children: <TestSemantics>[
                              TestSemantics(
                                id: 11,
                                flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
                                children: <TestSemantics>[
                                  // TODO(dnfield): These shouldn't be here. https://github.com/flutter/flutter/issues/34431
                                  TestSemantics(),
                                  TestSemantics(),
                                  TestSemantics(),
                                  TestSemantics(),
                                  TestSemantics(),
                                  TestSemantics(),
                                  TestSemantics(),
                                  TestSemantics(),
                                  TestSemantics(),
                                  TestSemantics(),
                                  TestSemantics(),
                                  TestSemantics(),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '1, Friday, January 1, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '2, Saturday, January 2, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '3, Sunday, January 3, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '4, Monday, January 4, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '5, Tuesday, January 5, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '6, Wednesday, January 6, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '7, Thursday, January 7, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '8, Friday, January 8, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '9, Saturday, January 9, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '10, Sunday, January 10, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '11, Monday, January 11, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '12, Tuesday, January 12, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '13, Wednesday, January 13, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '14, Thursday, January 14, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    flags: <SemanticsFlag>[SemanticsFlag.isSelected],
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '15, Friday, January 15, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '16, Saturday, January 16, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '17, Sunday, January 17, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '18, Monday, January 18, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '19, Tuesday, January 19, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '20, Wednesday, January 20, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '21, Thursday, January 21, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '22, Friday, January 22, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '23, Saturday, January 23, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '24, Sunday, January 24, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '25, Monday, January 25, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '26, Tuesday, January 26, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '27, Wednesday, January 27, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '28, Thursday, January 28, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '29, Friday, January 29, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '30, Saturday, January 30, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TestSemantics(
                                    actions: <SemanticsAction>[SemanticsAction.tap],
                                    label: '31, Sunday, January 31, 2016',
                                    textDirection: TextDirection.ltr,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              TestSemantics(
                flags: <SemanticsFlag>[
                  SemanticsFlag.hasEnabledState,
                  SemanticsFlag.isButton,
                  SemanticsFlag.isEnabled,
                  SemanticsFlag.isFocusable,
                ],
                actions: <SemanticsAction>[SemanticsAction.tap],
                label: 'Previous month December 2015',
                textDirection: TextDirection.ltr,
              ),
              TestSemantics(
                flags: <SemanticsFlag>[
                  SemanticsFlag.hasEnabledState,
                  SemanticsFlag.isButton,
                  SemanticsFlag.isEnabled,
                  SemanticsFlag.isFocusable,
                ],
                actions: <SemanticsAction>[SemanticsAction.tap],
                label: 'Next month February 2016',
                textDirection: TextDirection.ltr,
              ),
              TestSemantics(
                flags: <SemanticsFlag>[
                  SemanticsFlag.hasEnabledState,
                  SemanticsFlag.isButton,
                  SemanticsFlag.isEnabled,
                  SemanticsFlag.isFocusable,
                ],
                actions: <SemanticsAction>[SemanticsAction.tap],
                label: 'CANCEL',
                textDirection: TextDirection.ltr,
              ),
              TestSemantics(
                flags: <SemanticsFlag>[
                  SemanticsFlag.hasEnabledState,
                  SemanticsFlag.isButton,
                  SemanticsFlag.isEnabled,
                  SemanticsFlag.isFocusable,
                ],
                actions: <SemanticsAction>[SemanticsAction.tap],
                label: 'OK',
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ],
      );

      expect(semantics, hasSemantics(
        TestSemantics.root(children: <TestSemantics>[
          TestSemantics(
            children: <TestSemantics>[expected],
          ),
        ]),
        ignoreId: true,
        ignoreTransform: true,
        ignoreRect: true,
      ));
    });

    semantics.dispose();
  });

  testWidgets('chervons animate when scrolling month picker', (WidgetTester tester) async {
    final Key _datePickerKey = UniqueKey();
    DateTime _selectedDate = DateTime(2016, DateTime.july, 26);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              width: 400.0,
              child: SingleChildScrollView(
                child: Material(
                  child: MonthPicker(
                    firstDate: DateTime(0),
                    lastDate: DateTime(9999),
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
    );

    final Finder chevronFinder = find.byType(IconButton);
    final List<RenderAnimatedOpacity> chevronRenderers = chevronFinder
      .evaluate()
      .map((Element element) => element.findAncestorRenderObjectOfType<RenderAnimatedOpacity>())
      .toList();

    // Initial chevron animation state should be dismissed
    // An AlwaysStoppedAnimation is also found and is ignored
    for (final RenderAnimatedOpacity renderer in chevronRenderers) {
      expect(renderer.opacity.value, equals(1.0));
      expect(renderer.opacity.status, equals(AnimationStatus.dismissed));
    }

    // Drag and hold the picker to test for the opacity change
    final TestGesture gesture = await tester.startGesture(const Offset(100.0, 100.0));
    await gesture.moveBy(const Offset(50.0, 100.0));
    await tester.pumpAndSettle();
    for (final RenderAnimatedOpacity renderer in chevronRenderers) {
      expect(renderer.opacity.value, equals(0.0));
      expect(renderer.opacity.status, equals(AnimationStatus.completed));
    }

    // Release the drag and test for the opacity to return to original value
    await gesture.up();
    await tester.pumpAndSettle();
    for (final RenderAnimatedOpacity renderer in chevronRenderers) {
      expect(renderer.opacity.value, equals(1.0));
      expect(renderer.opacity.status, equals(AnimationStatus.dismissed));
    }
  });

  testWidgets('builder parameter', (WidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: Builder(
              builder: (BuildContext context) {
                return RaisedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2018),
                      lastDate: DateTime(2030),
                      builder: (BuildContext context, Widget child) {
                        return Directionality(
                          textDirection: textDirection,
                          child: child,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(TextDirection.ltr));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();
    final double ltrOkRight = tester.getBottomRight(find.text('OK')).dx;

    await tester.tap(find.text('OK')); // dismiss the dialog
    await tester.pumpAndSettle();

    await tester.pumpWidget(buildFrame(TextDirection.rtl));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    // Verify that the time picker is being laid out RTL.
    // We expect the left edge of the 'OK' button in the RTL
    // layout to match the gap between right edge of the 'OK'
    // button and the right edge of the 800 wide window.
    expect(tester.getBottomLeft(find.text('OK')).dx, 800 - ltrOkRight);
  });

  group('screen configurations', () {
    // Test various combinations of screen sizes, orientations and text scales
    // to ensure the layout doesn't overflow and cause an exception to be thrown.

    // Regression tests for https://github.com/flutter/flutter/issues/21383
    // Regression tests for https://github.com/flutter/flutter/issues/19744
    // Regression tests for https://github.com/flutter/flutter/issues/17745

    // Common screen size roughly based on a Pixel 1
    const Size kCommonScreenSizePortrait = Size(1070, 1770);
    const Size kCommonScreenSizeLandscape = Size(1770, 1070);

    // Small screen size based on a LG K130
    const Size kSmallScreenSizePortrait = Size(320, 521);
    const Size kSmallScreenSizeLandscape = Size(521, 320);

    Future<void> _showPicker(WidgetTester tester, Size size, [double textScaleFactor = 1.0]) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return RaisedButton(
                child: const Text('X'),
                onPressed: () {
                  showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                },
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('X'));
      await tester.pumpAndSettle();
    }

    testWidgets('common screen size - portrait', (WidgetTester tester) async {
      await _showPicker(tester, kCommonScreenSizePortrait);
      expect(tester.takeException(), isNull);
    });

    testWidgets('common screen size - landscape', (WidgetTester tester) async {
      await _showPicker(tester, kCommonScreenSizeLandscape);
      expect(tester.takeException(), isNull);
    });

    testWidgets('common screen size - portrait - textScale 1.3', (WidgetTester tester) async {
      await _showPicker(tester, kCommonScreenSizePortrait, 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('common screen size - landscape - textScale 1.3', (WidgetTester tester) async {
      await _showPicker(tester, kCommonScreenSizeLandscape, 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('small screen size - portrait', (WidgetTester tester) async {
      await _showPicker(tester, kSmallScreenSizePortrait);
      expect(tester.takeException(), isNull);
    });

    testWidgets('small screen size - landscape', (WidgetTester tester) async {
      await _showPicker(tester, kSmallScreenSizeLandscape);
      expect(tester.takeException(), isNull);
    });

    testWidgets('small screen size - portrait -textScale 1.3', (WidgetTester tester) async {
      await _showPicker(tester, kSmallScreenSizePortrait, 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('small screen size - landscape - textScale 1.3', (WidgetTester tester) async {
      await _showPicker(tester, kSmallScreenSizeLandscape, 1.3);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('uses root navigator by default', (WidgetTester tester) async {
    final DatePickerObserver rootObserver = DatePickerObserver();
    final DatePickerObserver nestedObserver = DatePickerObserver();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute<dynamic>(
            builder: (BuildContext context) {
              return RaisedButton(
                onPressed: () {
                  showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2018),
                    lastDate: DateTime(2030),
                    builder: (BuildContext context, Widget child) {
                      return const SizedBox();
                    },
                  );
                },
                child: const Text('Show Date Picker'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.byType(RaisedButton));

    expect(rootObserver.datePickerCount, 1);
    expect(nestedObserver.datePickerCount, 0);
  });

  testWidgets('uses nested navigator if useRootNavigator is false', (WidgetTester tester) async {
    final DatePickerObserver rootObserver = DatePickerObserver();
    final DatePickerObserver nestedObserver = DatePickerObserver();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute<dynamic>(
            builder: (BuildContext context) {
              return RaisedButton(
                onPressed: () {
                  showDatePicker(
                    context: context,
                    useRootNavigator: false,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2018),
                    lastDate: DateTime(2030),
                    builder: (BuildContext context, Widget child) => const SizedBox(),
                  );
                },
                child: const Text('Show Date Picker'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.byType(RaisedButton));

    expect(rootObserver.datePickerCount, 0);
    expect(nestedObserver.datePickerCount, 1);
  });
}

class DatePickerObserver extends NavigatorObserver {
  int datePickerCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route.toString().contains('_DialogRoute')) {
      datePickerCount++;
    }
    super.didPush(route, previousRoute);
  }
}
