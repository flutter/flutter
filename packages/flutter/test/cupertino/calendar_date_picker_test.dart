// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

// A number of the hit tests below say "warnIfMissed: false". This is because
// the way the CupertinoPicker works, the hits don't actually reach the labels,
// the scroll view intercepts them.

// scrolling by this offset will move the picker to the next item
const Offset _kRowOffset = Offset(0.0, -50.0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Finder nextMonthIcon = find.byWidgetPredicate((Widget w) => w is Icon && (w.semanticLabel?.startsWith('Next month') ?? false));
  final Finder previousMonthIcon = find.byWidgetPredicate((Widget w) => w is Icon && (w.semanticLabel?.startsWith('Previous month') ?? false));

  Widget cupertinoCalendarPicker({
    Key? key,
    DateTime? initialDate,
    DateTime? mininmumDate,
    ValueChanged<DateTime>? onDateChanged,
    ValueChanged<DateTime>? onDisplayedMonthChanged,
    CalendarPickerMode initialCalendarMode = CalendarPickerMode.day,
    TextDirection textDirection = TextDirection.ltr,
    Brightness? brightness,
  }) {
    return CupertinoApp(
      theme: CupertinoThemeData(brightness: brightness ?? Brightness.light),
      home: Directionality(
          textDirection: textDirection,
          child: Center(
            child: CupertinoCalendarPicker(
              key: key,
              initialDate: initialDate ?? DateTime(2016, DateTime.january, 15),
              onDateChanged: onDateChanged ?? (DateTime date) {},
              onDisplayedMonthChanged: onDisplayedMonthChanged,
              initialCalendarMode: initialCalendarMode,
            ),
          ),
        ),
    );
  }

  group('CalendarDatePicker', () {
    testWidgets('Can select a day', (WidgetTester tester) async {
      DateTime? selectedDate;
      await tester.pumpWidget(cupertinoCalendarPicker(
        onDateChanged: (DateTime date) => selectedDate = date,
      ));
      await tester.tap(find.text('12'));
      expect(selectedDate, equals(DateTime(2016, DateTime.january, 12)));
    });

    testWidgets('Can select a month from month picker', (WidgetTester tester) async {
      DateTime? displayedMonth;
      await tester.pumpWidget(cupertinoCalendarPicker(
        onDisplayedMonthChanged: (DateTime date) => displayedMonth = date,
      ));

      // Go back two months
      await tester.tap(previousMonthIcon);
      await tester.pumpAndSettle();
      expect(find.text('December 2015'), findsOneWidget);
      expect(displayedMonth, equals(DateTime(2015, DateTime.december)));
      await tester.tap(previousMonthIcon);
      await tester.pumpAndSettle();
      expect(find.text('November 2015'), findsOneWidget);
      expect(displayedMonth, equals(DateTime(2015, DateTime.november)));

      // Go forward a month
      await tester.tap(nextMonthIcon);
      await tester.pumpAndSettle();
      expect(find.text('December 2015'), findsOneWidget);
      expect(displayedMonth, equals(DateTime(2015, DateTime.december)));
    });

    testWidgets('Can select a month from year picker', (WidgetTester tester) async {
      DateTime? displayedMonth;
      await tester.pumpWidget(cupertinoCalendarPicker(
        onDisplayedMonthChanged: (DateTime date) => displayedMonth = date,
      ));

      // Go back two months
      await tester.tap(find.text('January 2016')); // Switch to year mode.
      await tester.pumpAndSettle();
      await tester.drag(find.text('January'), const Offset(0.0, 75.0), warnIfMissed: false); // see top of file
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('November 2016'), findsOneWidget);
      expect(displayedMonth, equals(DateTime(2016, DateTime.november)));

      // Go forward a month
      await tester.drag(find.text('November'), const Offset(0.0, -50.0), warnIfMissed: false); // see top of file
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('December 2016'), findsOneWidget);
      expect(displayedMonth, equals(DateTime(2016, DateTime.december)));
    });

    testWidgets('Can select a year', (WidgetTester tester) async {
      DateTime? displayedMonth;
      await tester.pumpWidget(cupertinoCalendarPicker(
        onDisplayedMonthChanged: (DateTime date) => displayedMonth = date,
      ));
      await tester.tap(find.text('January 2016')); // Switch to year mode.
      await tester.pumpAndSettle();
      await tester.drag(find.text('2016'), _kRowOffset, warnIfMissed: false); // see top of file
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('January 2017'), findsOneWidget);
      expect(displayedMonth, equals(DateTime(2017)));
    });

    testWidgets('Selecting date does not change displayed month', (WidgetTester tester) async {
      DateTime? selectedDate;
      DateTime? displayedMonth;

      await tester.pumpWidget(cupertinoCalendarPicker(
        initialDate: DateTime(2020, DateTime.march, 15),
        onDateChanged: (DateTime date) => selectedDate = date,
        onDisplayedMonthChanged: (DateTime date) => displayedMonth = date,
      ));
      await tester.tap(nextMonthIcon);
      await tester.pumpAndSettle();
      expect(find.text('April 2020'), findsOneWidget);
      expect(displayedMonth, equals(DateTime(2020, DateTime.april)));

      await tester.tap(find.text('25'));
      await tester.pumpAndSettle();
      expect(find.text('April 2020'), findsOneWidget);
      expect(displayedMonth, equals(DateTime(2020, DateTime.april)));
      expect(selectedDate, equals(DateTime(2020, DateTime.april, 25)));
      // There isn't a 31 in April so there shouldn't be one if it is showing April.
      expect(find.text('31'), findsNothing);
    });

    testWidgets('Changing year does not change selected date', (WidgetTester tester) async {
      DateTime? selectedDate;

      await tester.pumpWidget(cupertinoCalendarPicker(
        onDateChanged: (DateTime date) => selectedDate = date,
      ));
      await tester.tap(find.text('4'));
      expect(selectedDate, equals(DateTime(2016, DateTime.january, 4)));

      await tester.tap(find.text('January 2016')); // Switch to year mode.
      await tester.pumpAndSettle();
      await tester.drag(find.text('2016'), _kRowOffset, warnIfMissed: false); // see top of file
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('January 2017'), findsOneWidget);
      expect(selectedDate, equals(DateTime(2017, DateTime.january, 4)));
    });

    testWidgets('Changing year does not change the month', (WidgetTester tester) async {
      DateTime? displayedMonth;

      await tester.pumpWidget(cupertinoCalendarPicker(
        onDisplayedMonthChanged: (DateTime date) => displayedMonth = date,
      ));
      await tester.tap(nextMonthIcon);
      await tester.pumpAndSettle();
      await tester.tap(nextMonthIcon);
      await tester.pumpAndSettle();
      await tester.tap(find.text('March 2016'));
      await tester.pumpAndSettle();
      await tester.drag(find.text('2016'), const Offset(0.0, -75.0), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('March 2018'), findsOneWidget);
      expect(displayedMonth, equals(DateTime(2018, DateTime.march)));
    });

    testWidgets('Can select a year and then a day', (WidgetTester tester) async {
      DateTime? selectedDate;
      await tester.pumpWidget(cupertinoCalendarPicker(
        onDateChanged: (DateTime date) => selectedDate = date,
      ));
      await tester.tap(find.text('January 2016'));
      await tester.pumpAndSettle();
      await tester.drag(find.text('2016'), _kRowOffset, warnIfMissed: false); // see top of file
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('January 2017'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('19'));
      expect(selectedDate, equals(DateTime(2017, DateTime.january, 19)));
    });

    testWidgets('Can select initial calendar picker mode', (WidgetTester tester) async {
      await tester.pumpWidget(cupertinoCalendarPicker(
        initialDate: DateTime(2014, DateTime.january, 15),
        initialCalendarMode: CalendarPickerMode.year,
      ));
      await tester.drag(find.text('2014'), const Offset(0.0, -150.0), warnIfMissed: false); // see top of file
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('January 2018'), findsOneWidget);
    });

    testWidgets('InitialDate is highlighted', (WidgetTester tester) async {
      await tester.pumpWidget(cupertinoCalendarPicker(
        initialDate: DateTime(2014, DateTime.january, 15),
       ));
      final Finder finder = find.ancestor(
        of: find.text('15'),
        matching: find.byType(Container),
      );
      final Container container = tester.widget(finder);
      final BoxDecoration decoration =  container.decoration! as BoxDecoration;
      expect(
        decoration.color,
        CupertinoColors.systemBlue,
      );
    });

    testWidgets('Day selection is highlighted', (WidgetTester tester) async {
      final Color selectedDayBackground = CupertinoDynamicColor.withBrightness(
        color: CupertinoColors.systemBlue.withOpacity(.12),
        darkColor: CupertinoColors.systemBlue.withOpacity(.24),
      );
      await tester.pumpWidget(cupertinoCalendarPicker(
        initialDate: DateTime(2014, DateTime.january, 15),
      ));
      await tester.tap(find.text('22'));
      await tester.pumpAndSettle();
      final Finder finder = find.ancestor(
        of: find.text('22'),
        matching: find.byType(Container),
      );
      final Container container = tester.widget(finder);
      final BoxDecoration decoration =  container.decoration! as BoxDecoration;
      expect(
        decoration.color,
        selectedDayBackground,
      );
    });

    testWidgets('Calendar is adapted to brightness.dark', (WidgetTester tester) async {
      // Calendar with dark brightness.
      await tester.pumpWidget(cupertinoCalendarPicker(
        initialDate: DateTime(2014, DateTime.january, 15),
        brightness: Brightness.dark,
      ));
      final Finder finderTodayDate = find.ancestor(
        of: find.text('15'),
        matching: find.byType(Container),
      );
      final Container containerTodayDate = tester.widget(finderTodayDate);
      final BoxDecoration decorationTodayDate =  containerTodayDate.decoration! as BoxDecoration;
      expect(
        decorationTodayDate.color!.value,
        const Color(0xff0a84ff).value,
      );

      await tester.tap(find.text('22'));
      await tester.pumpAndSettle();
      final Finder finderSelectedDate = find.ancestor(
        of: find.text('22'),
        matching: find.byType(Container),
      );
      final Container containerSelectedDate = tester.widget(finderSelectedDate);
      final BoxDecoration decorationSelectedDate =  containerSelectedDate.decoration! as BoxDecoration;
      expect(
        decorationSelectedDate.color!.value,
        const Color(0x3d0a84ff).value,
      );
    });

    testWidgets('Calendar is adapted to brightness.light', (WidgetTester tester) async {
      // Calendar with dark brightness.
      await tester.pumpWidget(cupertinoCalendarPicker(
        initialDate: DateTime(2014, DateTime.january, 15),
        brightness: Brightness.light,
      ));
      final Finder finderTodayDate = find.ancestor(
        of: find.text('15'),
        matching: find.byType(Container),
      );
      final Container containerTodayDate = tester.widget(finderTodayDate);
      final BoxDecoration decorationTodayDate =  containerTodayDate.decoration! as BoxDecoration;
      expect(
        decorationTodayDate.color!.value,
        const Color(0xff007aff).value,
      );

      await tester.tap(find.text('22'));
      await tester.pumpAndSettle();
      final Finder finderSelectedDate = find.ancestor(
        of: find.text('22'),
        matching: find.byType(Container),
      );
      final Container containerSelectedDate = tester.widget(finderSelectedDate);
      final BoxDecoration decorationSelectedDate =  containerSelectedDate.decoration! as BoxDecoration;
      expect(
        decorationSelectedDate.color!.value,
        const Color(0x1f007aff).value,
      );
    });

    testWidgets('Today text color is updated up on non-today selection', (WidgetTester tester) async {
      await tester.pumpWidget(cupertinoCalendarPicker(
        initialDate: DateTime(2014, DateTime.january, 15),
       ));

      await tester.pumpAndSettle();
      expect(tester.firstWidget<Text>(find.text('15')).style?.color, CupertinoColors.white);
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      expect(tester.firstWidget<Text>(find.text('15')).style?.color, CupertinoColors.activeBlue);
    });

    testWidgets('Selecting date does not switch picker to year selection', (WidgetTester tester) async {
      await tester.pumpWidget(cupertinoCalendarPicker(
        initialDate: DateTime(2020, DateTime.may, 10),
      ));

      await tester.tap(find.text('May 2020')); // Switch to year mode.
      await tester.pumpAndSettle();
      await tester.drag(find.text('2020'), const Offset(0.0, 75.0), warnIfMissed: false); // see top of file
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('May 2018'), findsOneWidget);

      await tester.tap(find.text('May 2018')); // Switch to day mode.
      await tester.pumpAndSettle();
      await tester.tap(find.text('13'));
      await tester.pumpAndSettle();
      expect(find.text('May 2018'), findsOneWidget);
    });

   testWidgets('Updates to initialDate parameter is reflected in the state', (WidgetTester tester) async {
      final Key pickerKey = UniqueKey();
      final DateTime initialDate = DateTime(2020, 1, 13);
      final DateTime updatedDate = DateTime(1969, 7, 20);

      await tester.pumpWidget(cupertinoCalendarPicker(
        key: pickerKey,
        initialDate: initialDate,
      ));
      await tester.pumpAndSettle();

      // Month should show as January 2020
      expect(find.text('January 2020'), findsOneWidget);
      final Finder finderInitial = find.ancestor(
        of: find.text('13'),
        matching: find.byType(Container),
      );
      final Container containerInitial = tester.widget(finderInitial);
      final BoxDecoration decorationInitial =  containerInitial.decoration! as BoxDecoration;
      // Initial date should be highlighted.
      expect(
        decorationInitial.color,
        CupertinoColors.systemBlue,
      );

      await tester.pumpWidget(cupertinoCalendarPicker(
        key: pickerKey,
        initialDate: updatedDate,
      ));
      await tester.pumpAndSettle();

      // Month should show as January 1969
      expect(find.text('July 1969'), findsOneWidget);
      final Finder finderUpdated = find.ancestor(
        of: find.text('20'),
        matching: find.byType(Container),
      );
      final Container containerUpdated = tester.widget(finderUpdated);
      final BoxDecoration decorationUpdated =  containerUpdated.decoration! as BoxDecoration;
      // Updated date should be highlighted.
      expect(
        decorationUpdated.color,
        CupertinoColors.systemBlue,
      );
    });

    testWidgets('Updates to initialCalendarMode parameter is reflected in the state', (WidgetTester tester) async {
      final Key pickerKey = UniqueKey();

      await tester.pumpWidget(cupertinoCalendarPicker(
        key: pickerKey,
        initialCalendarMode: CalendarPickerMode.year,
      ));
      await tester.pumpAndSettle();

      // Should be in year mode.
      expect(find.text('January 2016'), findsOneWidget); // Day/year selector
      expect(find.text('15'), findsNothing); // day 15 should not be visible.
      expect(find.text('January'), findsOneWidget); // January in year wheel
      expect(find.text('2016'), findsOneWidget); // 2016 in year wheel

      await tester.pumpWidget(cupertinoCalendarPicker(
        key: pickerKey,
      ));
      await tester.pumpAndSettle();

      // Should be in day mode.
      expect(find.text('January 2016'), findsOneWidget); // Day/year selector
      expect(find.text('15'), findsOneWidget); // day 15 in grid
    });
  });

 group('Semantics', () {
      testWidgets('day mode', (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        addTearDown(semantics.dispose);

        await tester.pumpWidget(cupertinoCalendarPicker());

        // Year mode drop down button.
        expect(tester.getSemantics(find.text('January 2016')), matchesSemantics(
          label: 'January 2016',
          hasTapAction: true,
        ));

        // Prev/Next month buttons.
        expect(tester.getSemantics(previousMonthIcon), matchesSemantics(
          label: 'Previous month',
          hasTapAction: true,
        ));
       expect(tester.getSemantics(nextMonthIcon), matchesSemantics(
          label: 'Next month',
          hasTapAction: true,
        ));

        // Day grid.
        expect(tester.getSemantics(find.text('1')), matchesSemantics(
          label: '1, Friday, January 1, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('2')), matchesSemantics(
          label: '2, Saturday, January 2, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('3')), matchesSemantics(
          label: '3, Sunday, January 3, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('4')), matchesSemantics(
          label: '4, Monday, January 4, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('5')), matchesSemantics(
          label: '5, Tuesday, January 5, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('6')), matchesSemantics(
          label: '6, Wednesday, January 6, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('7')), matchesSemantics(
          label: '7, Thursday, January 7, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('8')), matchesSemantics(
          label: '8, Friday, January 8, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('9')), matchesSemantics(
          label: '9, Saturday, January 9, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('10')), matchesSemantics(
          label: '10, Sunday, January 10, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('11')), matchesSemantics(
          label: '11, Monday, January 11, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('12')), matchesSemantics(
          label: '12, Tuesday, January 12, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('13')), matchesSemantics(
          label: '13, Wednesday, January 13, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('14')), matchesSemantics(
          label: '14, Thursday, January 14, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('15')), matchesSemantics(
          label: '15, Friday, January 15, 2016',
          hasTapAction: true,
          isSelected: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('16')), matchesSemantics(
          label: '16, Saturday, January 16, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('17')), matchesSemantics(
          label: '17, Sunday, January 17, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('18')), matchesSemantics(
          label: '18, Monday, January 18, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('19')), matchesSemantics(
          label: '19, Tuesday, January 19, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('20')), matchesSemantics(
          label: '20, Wednesday, January 20, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('21')), matchesSemantics(
          label: '21, Thursday, January 21, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('22')), matchesSemantics(
          label: '22, Friday, January 22, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('23')), matchesSemantics(
          label: '23, Saturday, January 23, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('24')), matchesSemantics(
          label: '24, Sunday, January 24, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('25')), matchesSemantics(
          label: '25, Monday, January 25, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('26')), matchesSemantics(
          label: '26, Tuesday, January 26, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('27')), matchesSemantics(
          label: '27, Wednesday, January 27, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('28')), matchesSemantics(
          label: '28, Thursday, January 28, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('29')), matchesSemantics(
          label: '29, Friday, January 29, 2016',
          hasTapAction: true,
          isButton: true,
        ));
        expect(tester.getSemantics(find.text('30')), matchesSemantics(
          label: '30, Saturday, January 30, 2016',
          hasTapAction: true,
          isButton: true,
        ));
      });

      testWidgets('calendar year mode', (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();

        await tester.pumpWidget(cupertinoCalendarPicker(
          initialCalendarMode: CalendarPickerMode.year,
        ));

        // Year mode drop down button.
        expect(tester.getSemantics(find.text('January 2016')), matchesSemantics(
          label: 'January 2016',
          hasTapAction: true,
        ));

        // Month and Year pickers
        expect(find.byType(CupertinoPicker), findsNWidgets(2));
        addTearDown(semantics.dispose);
      });
    });
}
