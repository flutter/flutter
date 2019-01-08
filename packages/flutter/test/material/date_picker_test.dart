// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
      )
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
        flags: <SemanticsFlag>[
          SemanticsFlag.scopesRoute,
        ],
        children: <TestSemantics>[
          TestSemantics(
            actions: <SemanticsAction>[SemanticsAction.tap],
            label: '2016',
            textDirection: TextDirection.ltr,
          ),
          TestSemantics(
            flags: <SemanticsFlag>[SemanticsFlag.isSelected],
            actions: <SemanticsAction>[SemanticsAction.tap],
            label: 'Fri, Jan 15',
            textDirection: TextDirection.ltr,
          ),
          TestSemantics(
            children: <TestSemantics>[
              TestSemantics(
                children: <TestSemantics>[
                  TestSemantics(
                    actions: <SemanticsAction>[SemanticsAction.scrollLeft, SemanticsAction.scrollRight],
                    children: <TestSemantics>[
                      TestSemantics(
                        children: <TestSemantics>[
                          TestSemantics(
                            children: <TestSemantics>[
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
            flags: <SemanticsFlag>[SemanticsFlag.isButton, SemanticsFlag.hasEnabledState, SemanticsFlag.isEnabled],
            actions: <SemanticsAction>[SemanticsAction.tap],
            label: 'Previous month December 2015',
            textDirection: TextDirection.ltr,
          ),
          TestSemantics(
            flags: <SemanticsFlag>[SemanticsFlag.isButton, SemanticsFlag.hasEnabledState, SemanticsFlag.isEnabled],
            actions: <SemanticsAction>[SemanticsAction.tap],
            label: 'Next month February 2016',
            textDirection: TextDirection.ltr,
          ),
          TestSemantics(
            flags: <SemanticsFlag>[SemanticsFlag.isButton, SemanticsFlag.hasEnabledState, SemanticsFlag.isEnabled],
            actions: <SemanticsAction>[SemanticsAction.tap],
            label: 'CANCEL',
            textDirection: TextDirection.ltr,
          ),
          TestSemantics(
            flags: <SemanticsFlag>[SemanticsFlag.isButton, SemanticsFlag.hasEnabledState, SemanticsFlag.isEnabled],
            actions: <SemanticsAction>[SemanticsAction.tap],
            label: 'OK',
            textDirection: TextDirection.ltr,
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
      )
    );

    final Finder chevronFinder = find.byType(IconButton);
    final List<RenderAnimatedOpacity> chevronRenderers = chevronFinder.evaluate().map(
      (Element element) => element.ancestorRenderObjectOfType(
        const TypeMatcher<RenderAnimatedOpacity>())).cast<RenderAnimatedOpacity>().toList();

    // Initial chevron animation state should be dismissed
    // An AlwaysStoppedAnimation is also found and is ignored
    for(RenderAnimatedOpacity renderer in chevronRenderers) {
      expect(renderer.opacity.value, equals(1.0));
      expect(renderer.opacity.status, equals(AnimationStatus.dismissed));
    }

    // Drag and hold the picker to test for the opacity change
    final TestGesture gesture = await tester.startGesture(const Offset(100.0, 100.0));
    await gesture.moveBy(const Offset(50.0, 100.0));
    await tester.pumpAndSettle();
    for(RenderAnimatedOpacity renderer in chevronRenderers) {
      expect(renderer.opacity.value, equals(0.0));
      expect(renderer.opacity.status, equals(AnimationStatus.completed));
    }

    // Release the drag and test for the opacity to return to original value
    await gesture.up();
    await tester.pumpAndSettle();
    for(RenderAnimatedOpacity renderer in chevronRenderers) {
      expect(renderer.opacity.value, equals(1.0));
      expect(renderer.opacity.status, equals(AnimationStatus.dismissed));
    }
  });
}
