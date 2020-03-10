// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'feedback_tester.dart';

void main() {

  DateTime firstDate;
  DateTime lastDate;
  DateTime initialDate;
  SelectableDayPredicate selectableDayPredicate;
  DatePickerEntryMode initialEntryMode;
  DatePickerMode initialCalendarMode;

  String cancelText;
  String confirmText;
  String errorFormatText;
  String errorInvalidText;
  String fieldHintText;
  String fieldLabelText;
  String helpText;

  final Finder nextMonthIcon = find.byWidgetPredicate((Widget w) => w is IconButton && (w.tooltip?.startsWith('Next month') ?? false));
  final Finder previousMonthIcon = find.byWidgetPredicate((Widget w) => w is IconButton && (w.tooltip?.startsWith('Previous month') ?? false));
  final Finder switchToInputIcon = find.byIcon(Icons.edit);
  final Finder switchToCalendarIcon = find.byIcon(Icons.calendar_today);

  TextField textField(WidgetTester tester) {
    return tester.widget<TextField>(find.byType(TextField));
  }

  setUp(() {
    firstDate = DateTime(2001, DateTime.january, 1);
    lastDate = DateTime(2031, DateTime.december, 31);
    initialDate = DateTime(2016, DateTime.january, 15);
    selectableDayPredicate = null;
    initialEntryMode = DatePickerEntryMode.calendar;
    initialCalendarMode = DatePickerMode.day;

    cancelText = null;
    confirmText = null;
    errorFormatText = null;
    errorInvalidText = null;
    fieldHintText = null;
    fieldLabelText = null;
    helpText = null;
  });

  Future<void> prepareDatePicker(WidgetTester tester, Future<void> callback(Future<DateTime> date)) async {
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

    final Future<DateTime> date = showDatePicker(
      context: buttonContext,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: selectableDayPredicate,
      initialDatePickerMode: initialCalendarMode,
      initialEntryMode: initialEntryMode,
      cancelText: cancelText,
      confirmText: confirmText,
      errorFormatText: errorFormatText,
      errorInvalidText: errorInvalidText,
      fieldHintText: fieldHintText,
      fieldLabelText: fieldLabelText,
      helpText: helpText,
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    await callback(date);
  }

  group('showDatePicker Dialog', () {
    testWidgets('Cancel, confirm, and help text is used', (WidgetTester tester) async {
      cancelText = 'nope';
      confirmText = 'yep';
      helpText = 'help';
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        expect(find.text(cancelText), findsOneWidget);
        expect(find.text(confirmText), findsOneWidget);
        expect(find.text(helpText), findsOneWidget);
      });
    });

    testWidgets('Initial date is the default', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('OK'));
        expect(await date, DateTime(2016, DateTime.january, 15));
      });
    });

    testWidgets('Can cancel', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('CANCEL'));
        expect(await date, isNull);
      });
    });

    testWidgets('Can toggle to input entry mode', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        expect(find.byType(TextField), findsNothing);
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
      });
    });

    testWidgets('Toggle to input mode keeps selected date', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('12'));
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        expect(await date, DateTime(2016, DateTime.january, 12));
      });
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

      await tester.tap(find.text('OK')); // Dismiss the dialog.
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

    testWidgets('uses nested navigator if useRootNavigator is false', (WidgetTester tester) async {
      final _DatePickerObserver rootObserver = _DatePickerObserver();
      final _DatePickerObserver nestedObserver = _DatePickerObserver();

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

  });

  group('Calendar mode', () {
    testWidgets('Can select a day', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('12'));
        await tester.tap(find.text('OK'));
        expect(await date, equals(DateTime(2016, DateTime.january, 12)));
      });
    });

    testWidgets('Can select a month', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(previousMonthIcon);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.text('25'));
        await tester.tap(find.text('OK'));
        expect(await date, DateTime(2015, DateTime.december, 25));
      });
    });

    testWidgets('Can select a year', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('January 2016')); // Switch to year mode.
        await tester.pump();
        await tester.tap(find.text('2018'));
        await tester.pump();
        expect(find.text('January 2018'), findsOneWidget);
      });
    });

    testWidgets('Changing year does not change selected date', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('January 2016'));
        await tester.pump();
        await tester.tap(find.text('2018'));
        await tester.pump();
        await tester.tap(find.text('OK'));
        expect(await date, equals(DateTime(2016, DateTime.january, 15)));
      });
    });

    testWidgets('Changing year does not change the month', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(nextMonthIcon);
        await tester.pumpAndSettle();
        await tester.tap(nextMonthIcon);
        await tester.pumpAndSettle();
        await tester.tap(find.text('March 2016'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2018'));
        await tester.pumpAndSettle();
        expect(find.text('March 2018'), findsOneWidget);
      });
    });

    testWidgets('Can select a year and then a day', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('January 2016')); // Switch to year mode.
        await tester.pump();
        await tester.tap(find.text('2017'));
        await tester.pump();
        await tester.tap(find.text('19'));
        await tester.tap(find.text('OK'));
        expect(await date, DateTime(2017, DateTime.january, 19));
      });
    });

    testWidgets('Current year is visible in year picker', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('January 2016')); // Switch to year mode.
        await tester.pump();
        expect(find.text('2016'), findsOneWidget);
      });
    });

    testWidgets('Cannot select a day outside bounds', (WidgetTester tester) async {
      initialDate = DateTime(2017, DateTime.january, 15);
      firstDate = initialDate;
      lastDate = initialDate;
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        // Earlier than firstDate. Should be ignored.
        await tester.tap(find.text('10'));
        // Later than lastDate. Should be ignored.
        await tester.tap(find.text('20'));
        await tester.tap(find.text('OK'));
        // We should still be on the initial date.
        expect(await date, initialDate);
      });
    });

    testWidgets('Cannot select a month past last date', (WidgetTester tester) async {
      initialDate = DateTime(2017, DateTime.january, 15);
      firstDate = initialDate;
      lastDate = DateTime(2017, DateTime.february, 20);
      await prepareDatePicker(tester, (Future<DateTime> date) async {
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
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(previousMonthIcon);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        // Shouldn't be possible to keep going into November.
        expect(previousMonthIcon, findsNothing);
      });
    });

    testWidgets('Cannot select disabled year', (WidgetTester tester) async {
      initialDate = DateTime(2018, DateTime.july, 4);
      firstDate = DateTime(2018, DateTime.june, 9);
      lastDate = DateTime(2018, DateTime.december, 15);
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('July 2018')); // Switch to year mode.
        await tester.pumpAndSettle();
        await tester.tap(find.text('2016')); // Disabled, doesn't change the year.
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(await date, DateTime(2018, DateTime.july, 4));
      });
    });

    testWidgets('Selecting firstDate year respects firstDate', (WidgetTester tester) async {
      initialDate = DateTime(2018, DateTime.may, 4);
      firstDate = DateTime(2016, DateTime.june, 9);
      lastDate = DateTime(2019, DateTime.january, 15);
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('May 2018'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2016'));
        await tester.pumpAndSettle();
        // Month should be clamped to June as the range starts at June 2016
        expect(find.text('June 2016'), findsOneWidget);
      });
    });

    testWidgets('Selecting lastDate year respects lastDate', (WidgetTester tester) async {
      initialDate = DateTime(2018, DateTime.may, 4);
      firstDate = DateTime(2016, DateTime.june, 9);
      lastDate = DateTime(2019, DateTime.january, 15);
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('May 2018'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2019'));
        await tester.pumpAndSettle();
        // Month should be clamped to January as the range ends at January 2019
        expect(find.text('January 2019'), findsOneWidget);
      });
    });

    testWidgets('Only predicate days are selectable', (WidgetTester tester) async {
      initialDate = DateTime(2017, DateTime.january, 16);
      firstDate = DateTime(2017, DateTime.january, 10);
      lastDate = DateTime(2017, DateTime.january, 20);
      selectableDayPredicate = (DateTime day) => day.day.isEven;
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('13')); // Odd, doesn't work.
        await tester.tap(find.text('10')); // Even, works.
        await tester.tap(find.text('17')); // Odd, doesn't work.
        await tester.tap(find.text('OK'));
        expect(await date, DateTime(2017, DateTime.january, 10));
      });
    });

    testWidgets('Can select initial date picker mode', (WidgetTester tester) async {
      initialDate = DateTime(2014, DateTime.january, 15);
      initialCalendarMode = DatePickerMode.year;
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.pump();
        // 2018 wouldn't be available if the year picker wasn't showing.
        // The initial current year is 2014.
        await tester.tap(find.text('2018'));
        await tester.pump();
        expect(find.text('January 2018'), findsOneWidget);
      });
    });

  });

  group('Input mode', () {
    setUp(() {
      firstDate = DateTime(2015, DateTime.january, 1);
      lastDate = DateTime(2017, DateTime.december, 31);
      initialDate = DateTime(2016, DateTime.january, 15);
      initialEntryMode = DatePickerEntryMode.input;
    });

    testWidgets('Initial entry mode is used', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        expect(find.byType(TextField), findsOneWidget);
      });
    });

    testWidgets('Hint, label, and help text is used', (WidgetTester tester) async {
      cancelText = 'nope';
      confirmText = 'yep';
      fieldHintText = 'hint';
      fieldLabelText = 'label';
      helpText = 'help';
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        expect(find.text(cancelText), findsOneWidget);
        expect(find.text(confirmText), findsOneWidget);
        expect(find.text(fieldHintText), findsOneWidget);
        expect(find.text(fieldLabelText), findsOneWidget);
        expect(find.text(helpText), findsOneWidget);
      });
    });

    testWidgets('Initial date is the default', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('OK'));
        expect(await date, DateTime(2016, DateTime.january, 15));
      });
    });

    testWidgets('Can toggle to calendar entry mode', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        expect(find.byType(TextField), findsOneWidget);
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
      });
    });

    testWidgets('Toggle to calendar mode keeps selected date', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        final TextField field = textField(tester);
        field.controller.clear();

        await tester.enterText(find.byType(TextField), '12/25/2016');
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        expect(await date, DateTime(2016, DateTime.december, 25));
      });
    });

    testWidgets('Entered text returns date', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        final TextField field = textField(tester);
        field.controller.clear();

        await tester.enterText(find.byType(TextField), '12/25/2016');
        await tester.tap(find.text('OK'));
        expect(await date, DateTime(2016, DateTime.december, 25));
      });
    });

    testWidgets('Too short entered text shows error', (WidgetTester tester) async {
      errorFormatText = 'oops';
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        final TextField field = textField(tester);
        field.controller.clear();

        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '1225');
        expect(find.text(errorFormatText), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text(errorFormatText), findsOneWidget);
      });
    });

    testWidgets('Bad format entered text shows error', (WidgetTester tester) async {
      errorFormatText = 'oops';
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        final TextField field = textField(tester);
        field.controller.clear();

        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '20202014');
        expect(find.text(errorFormatText), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text(errorFormatText), findsOneWidget);
      });
    });

    testWidgets('Invalid entered text shows error', (WidgetTester tester) async {
      errorInvalidText = 'oops';
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        final TextField field = textField(tester);
        field.controller.clear();

        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '08/10/1969');
        expect(find.text(errorInvalidText), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text(errorInvalidText), findsOneWidget);
      });
    });
  });

  group('Haptic feedback', () {
    const Duration hapticFeedbackInterval = Duration(milliseconds: 10);
    FeedbackTester feedback;

    setUp(() {
      feedback = FeedbackTester();
      initialDate = DateTime(2017, DateTime.january, 16);
      firstDate = DateTime(2017, DateTime.january, 10);
      lastDate = DateTime(2018, DateTime.january, 20);
      initialCalendarMode = DatePickerMode.day;
      selectableDayPredicate = (DateTime date) => date.day.isEven;
    });

    tearDown(() {
      feedback?.dispose();
    });

    testWidgets('Selecting date vibrates', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('10'));
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 1);
        await tester.tap(find.text('12'));
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 2);
        await tester.tap(find.text('14'));
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 3);
      });
    });

    testWidgets('Tapping unselectable date does not vibrate', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('11'));
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 0);
        await tester.tap(find.text('13'));
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 0);
        await tester.tap(find.text('15'));
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 0);
      });
    });

    testWidgets('Changing modes and year vibrates', (WidgetTester tester) async {
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('January 2017'));
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 1);
        await tester.tap(find.text('2018'));
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 2);
      });
    });
  });

  group('Semantics', () {
    testWidgets('calendar day mode', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      await prepareDatePicker(tester, (Future<DateTime> date) async {
        // Header
        expect(
            tester.getSemantics(find.text('SELECT DATE')), matchesSemantics(
          label: 'SELECT DATE\nFri, Jan 15',
        ));

        // Input mode toggle button
        expect(tester.getSemantics(switchToInputIcon), matchesSemantics(
          label: 'Switch to input',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ));

        // Year mode drop down button
        expect(
            tester.getSemantics(find.text('January 2016')), matchesSemantics(
          label: 'Select year',
          isButton: true,
        ));

        // Prev/Next month buttons
        expect(tester.getSemantics(previousMonthIcon), matchesSemantics(
          label: 'Previous month December 2015',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ));
        expect(tester.getSemantics(nextMonthIcon), matchesSemantics(
          label: 'Next month February 2016',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ));

        // Day grid
        expect(tester.getSemantics(find.text('1')), matchesSemantics(
          label: '1, Friday, January 1, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('2')), matchesSemantics(
          label: '2, Saturday, January 2, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('3')), matchesSemantics(
          label: '3, Sunday, January 3, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('4')), matchesSemantics(
          label: '4, Monday, January 4, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('5')), matchesSemantics(
          label: '5, Tuesday, January 5, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('6')), matchesSemantics(
          label: '6, Wednesday, January 6, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('7')), matchesSemantics(
          label: '7, Thursday, January 7, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('8')), matchesSemantics(
          label: '8, Friday, January 8, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('9')), matchesSemantics(
          label: '9, Saturday, January 9, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('10')), matchesSemantics(
          label: '10, Sunday, January 10, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('11')), matchesSemantics(
          label: '11, Monday, January 11, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('12')), matchesSemantics(
          label: '12, Tuesday, January 12, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('13')), matchesSemantics(
          label: '13, Wednesday, January 13, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('14')), matchesSemantics(
          label: '14, Thursday, January 14, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('15')), matchesSemantics(
          label: '15, Friday, January 15, 2016',
          hasTapAction: true,
          isSelected: true,
        ));
        expect(tester.getSemantics(find.text('16')), matchesSemantics(
          label: '16, Saturday, January 16, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('17')), matchesSemantics(
          label: '17, Sunday, January 17, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('18')), matchesSemantics(
          label: '18, Monday, January 18, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('19')), matchesSemantics(
          label: '19, Tuesday, January 19, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('20')), matchesSemantics(
          label: '20, Wednesday, January 20, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('21')), matchesSemantics(
          label: '21, Thursday, January 21, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('22')), matchesSemantics(
          label: '22, Friday, January 22, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('23')), matchesSemantics(
          label: '23, Saturday, January 23, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('24')), matchesSemantics(
          label: '24, Sunday, January 24, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('25')), matchesSemantics(
          label: '25, Monday, January 25, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('26')), matchesSemantics(
          label: '26, Tuesday, January 26, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('27')), matchesSemantics(
          label: '27, Wednesday, January 27, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('28')), matchesSemantics(
          label: '28, Thursday, January 28, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('29')), matchesSemantics(
          label: '29, Friday, January 29, 2016',
          hasTapAction: true,
        ));
        expect(tester.getSemantics(find.text('30')), matchesSemantics(
          label: '30, Saturday, January 30, 2016',
          hasTapAction: true,
        ));

        // Ok/Cancel buttons
        expect(tester.getSemantics(find.text('OK')), matchesSemantics(
          label: 'OK',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ));
        expect(tester.getSemantics(find.text('CANCEL')), matchesSemantics(
          label: 'CANCEL',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ));

      });

      semantics.dispose();
    });

    testWidgets('calendar year mode', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      initialCalendarMode = DatePickerMode.year;
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        // Header
        expect(tester.getSemantics(find.text('SELECT DATE')), matchesSemantics(
          label: 'SELECT DATE\nFri, Jan 15',
        ));

        // Input mode toggle button
        expect(tester.getSemantics(switchToInputIcon), matchesSemantics(
          label: 'Switch to input',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ));

        // Year mode drop down button
        expect(tester.getSemantics(find.text('January 2016')), matchesSemantics(
          label: 'Select year',
          isButton: true,
        ));

        // Year grid only shows 2010 - 2024
        for (int year = 2010; year <= 2024; year++) {
          expect(tester.getSemantics(find.text('$year')), matchesSemantics(
            label: '$year',
            hasTapAction: true,
            isSelected: year == 2016,
            isFocusable: true,
          ));
        }

        // Ok/Cancel buttons
        expect(tester.getSemantics(find.text('OK')), matchesSemantics(
          label: 'OK',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ));
        expect(tester.getSemantics(find.text('CANCEL')), matchesSemantics(
          label: 'CANCEL',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ));

      });

      semantics.dispose();
    });

    testWidgets('input mode', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      initialEntryMode = DatePickerEntryMode.input;
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        // Header
        expect(tester.getSemantics(find.text('SELECT DATE')), matchesSemantics(
          label: 'SELECT DATE\nFri, Jan 15',
        ));

        // Input mode toggle button
        expect(tester.getSemantics(switchToCalendarIcon), matchesSemantics(
          label: 'Switch to calendar',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ));

        // Text field
        expect(tester.getSemantics(find.byType(EditableText)), matchesSemantics(
          label: 'Enter Date\nmm/dd/yyyy',
          isTextField: true,
          isFocused: true,
          value: '01/15/2016',
          hasTapAction: true,
          hasSetSelectionAction: true,
          hasCopyAction: true,
          hasCutAction: true,
          hasPasteAction: true,
          hasMoveCursorBackwardByCharacterAction: true,
          hasMoveCursorBackwardByWordAction: true,
        ));

        // Ok/Cancel buttons
        expect(tester.getSemantics(find.text('OK')), matchesSemantics(
          label: 'OK',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ));
        expect(tester.getSemantics(find.text('CANCEL')), matchesSemantics(
          label: 'CANCEL',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ));

      });

      semantics.dispose();
    });

  });

  group('Screen configurations', () {
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
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
      await prepareDatePicker(tester, (Future<DateTime> date) async {
        await tester.tap(find.text('OK'));
      });
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
}

class _DatePickerObserver extends NavigatorObserver {
  int datePickerCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route.toString().contains('_DialogRoute')) {
      datePickerCount++;
    }
    super.didPush(route, previousRoute);
  }
}
