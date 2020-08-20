// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

// scrolling by this offset will move the picker to the next item
const Offset _kRowOffset = Offset(0.0, -50.0);

void main() {
  group('Countdown timer picker', () {
    testWidgets('onTimerDurationChanged is not null', (WidgetTester tester) async {
      expect(
        () {
          CupertinoTimerPicker(onTimerDurationChanged: null);
        },
        throwsAssertionError,
      );
    });

    testWidgets('initialTimerDuration falls within limit', (WidgetTester tester) async {
      expect(
        () {
          CupertinoTimerPicker(
            onTimerDurationChanged: (_) { },
            initialTimerDuration: const Duration(days: 1),
          );
        },
        throwsAssertionError,
      );

      expect(
        () {
          CupertinoTimerPicker(
            onTimerDurationChanged: (_) { },
            initialTimerDuration: const Duration(seconds: -1),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('minuteInterval is positive and is a factor of 60', (WidgetTester tester) async {
      expect(
        () {
          CupertinoTimerPicker(
            onTimerDurationChanged: (_) { },
            minuteInterval: 0,
          );
        },
        throwsAssertionError,
      );
      expect(
        () {
          CupertinoTimerPicker(
            onTimerDurationChanged: (_) { },
            minuteInterval: -1,
          );
        },
        throwsAssertionError,
      );
      expect(
        () {
          CupertinoTimerPicker(
            onTimerDurationChanged: (_) { },
            minuteInterval: 7,
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('secondInterval is positive and is a factor of 60', (WidgetTester tester) async {
      expect(
        () {
          CupertinoTimerPicker(
            onTimerDurationChanged: (_) { },
            secondInterval: 0,
          );
        },
        throwsAssertionError,
      );
      expect(
        () {
          CupertinoTimerPicker(
            onTimerDurationChanged: (_) { },
            secondInterval: -1,
          );
        },
        throwsAssertionError,
      );
      expect(
        () {
          CupertinoTimerPicker(
            onTimerDurationChanged: (_) { },
            secondInterval: 7,
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('background color default value', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoTimerPicker(
            onTimerDurationChanged: (_) { },
          ),
        ),
      );

      final Iterable<CupertinoPicker> pickers = tester.allWidgets.whereType<CupertinoPicker>();
      expect(pickers.any((CupertinoPicker picker) => picker.backgroundColor != null), false);
    });

    testWidgets('background color can be null', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoTimerPicker(
            onTimerDurationChanged: (_) { },
            backgroundColor: null,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('specified background color is applied', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoTimerPicker(
            onTimerDurationChanged: (_) { },
            backgroundColor: CupertinoColors.black,
          ),
        ),
      );

      final Iterable<CupertinoPicker> pickers = tester.allWidgets.whereType<CupertinoPicker>();
      expect(pickers.any((CupertinoPicker picker) => picker.backgroundColor != CupertinoColors.black), false);
    });

    testWidgets('columns are ordered correctly when text direction is ltr', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoTimerPicker(
            onTimerDurationChanged: (_) { },
            initialTimerDuration: const Duration(hours: 12, minutes: 30, seconds: 59),
          ),
        ),
      );

      Offset lastOffset = tester.getTopLeft(find.text('12'));

      expect(tester.getTopLeft(find.text('hours')).dx > lastOffset.dx, true);
      lastOffset = tester.getTopLeft(find.text('hours'));

      expect(tester.getTopLeft(find.text('30')).dx > lastOffset.dx, true);
      lastOffset = tester.getTopLeft(find.text('30'));

      expect(tester.getTopLeft(find.text('min.')).dx > lastOffset.dx, true);
      lastOffset = tester.getTopLeft(find.text('min.'));

      expect(tester.getTopLeft(find.text('59')).dx > lastOffset.dx, true);
      lastOffset = tester.getTopLeft(find.text('59'));

      expect(tester.getTopLeft(find.text('sec.')).dx > lastOffset.dx, true);
    });

    testWidgets('columns are ordered correctly when text direction is rtl', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: CupertinoTimerPicker(
              onTimerDurationChanged: (_) { },
              initialTimerDuration: const Duration(hours: 12, minutes: 30, seconds: 59),
            ),
          ),
        ),
      );

      Offset lastOffset = tester.getTopLeft(find.text('12'));

      expect(tester.getTopLeft(find.text('hours')).dx > lastOffset.dx, false);
      lastOffset = tester.getTopLeft(find.text('hours'));

      expect(tester.getTopLeft(find.text('30')).dx > lastOffset.dx, false);
      lastOffset = tester.getTopLeft(find.text('30'));

      expect(tester.getTopLeft(find.text('min.')).dx > lastOffset.dx, false);
      lastOffset = tester.getTopLeft(find.text('min.'));

      expect(tester.getTopLeft(find.text('59')).dx > lastOffset.dx, false);
      lastOffset = tester.getTopLeft(find.text('59'));

      expect(tester.getTopLeft(find.text('sec.')).dx > lastOffset.dx, false);
    });

    testWidgets('width of picker is consistent', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
            height: 400.0,
            width: 400.0,
            child: CupertinoTimerPicker(
              onTimerDurationChanged: (_) { },
              initialTimerDuration: const Duration(hours: 12, minutes: 30, seconds: 59),
            ),
          ),
        ),
      );

      // Distance between the first column and the last column.
      final double distance = tester.getCenter(
        find.text('sec.')).dx - tester.getCenter(find.text('12'),
      ).dx;

      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
            height: 400.0,
            width: 800.0,
            child: CupertinoTimerPicker(
              onTimerDurationChanged: (_) { },
              initialTimerDuration: const Duration(hours: 12, minutes: 30, seconds: 59),
            ),
          ),
        ),
      );

      // Distance between the first and the last column should be the same.
      expect(
        tester.getCenter(find.text('sec.')).dx - tester.getCenter(find.text('12')).dx,
        distance,
      );
    });
  });

  testWidgets('picker honors minuteInterval and secondInterval', (WidgetTester tester) async {
    Duration duration;
    await tester.pumpWidget(
      CupertinoApp(
        home: SizedBox(
          height: 400.0,
          width: 400.0,
          child: CupertinoTimerPicker(
            minuteInterval: 10,
            secondInterval: 12,
            initialTimerDuration: const Duration(hours: 10, minutes: 40, seconds: 48),
            mode: CupertinoTimerPickerMode.hms,
            onTimerDurationChanged: (Duration d) {
              duration = d;
            },
          ),
        ),
      ),
    );

    await tester.drag(find.text('40'), _kRowOffset);
    await tester.pump();
    await tester.drag(find.text('48'), -_kRowOffset);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      duration,
      const Duration(hours: 10, minutes: 50, seconds: 36),
    );
  });

  group('Date picker', () {
    testWidgets('mode is not null', (WidgetTester tester) async {
      expect(
        () {
          CupertinoDatePicker(
            mode: null,
            onDateTimeChanged: (_) { },
            initialDateTime: DateTime.now(),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('onDateTimeChanged is not null', (WidgetTester tester) async {
      expect(
        () {
          CupertinoDatePicker(
            onDateTimeChanged: null,
            initialDateTime: DateTime.now(),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('initial date is set to default value', (WidgetTester tester) async {
      final CupertinoDatePicker picker = CupertinoDatePicker(
        onDateTimeChanged: (_) { },
      );
      expect(picker.initialDateTime, isNotNull);
    });

    testWidgets('background color default value', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoDatePicker(
            onDateTimeChanged: (_) { },
          ),
        ),
      );

      final Iterable<CupertinoPicker> pickers = tester.allWidgets.whereType<CupertinoPicker>();
      expect(pickers.any((CupertinoPicker picker) => picker.backgroundColor != null), false);
    });

    testWidgets('background color can be null', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoDatePicker(
            onDateTimeChanged: (_) { },
            backgroundColor: null,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('specified background color is applied', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoDatePicker(
            onDateTimeChanged: (_) { },
            backgroundColor: CupertinoColors.black,
          ),
        ),
      );

      final Iterable<CupertinoPicker> pickers = tester.allWidgets.whereType<CupertinoPicker>();
      expect(pickers.any((CupertinoPicker picker) => picker.backgroundColor != CupertinoColors.black), false);
    });

    testWidgets('initial date honors minuteInterval', (WidgetTester tester) async {
      DateTime newDateTime;
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: CupertinoDatePicker(
                onDateTimeChanged: (DateTime d) => newDateTime = d,
                initialDateTime: DateTime(2018, 10, 10, 10, 3),
                minuteInterval: 3,
              ),
            ),
          ),
        ),
      );

      // Drag the minute picker to the next slot (03 -> 06).
      // The `initialDateTime` and the `minuteInterval` values are specifically chosen
      // so that `find.text` finds exactly one widget.
      await tester.drag(find.text('03'), _kRowOffset);
      await tester.pump();

      expect(newDateTime.minute, 6);
    });

    test('initial date honors minimumDate & maximumDate', () {
      expect(() {
          CupertinoDatePicker(
            onDateTimeChanged: (DateTime d) { },
            initialDateTime: DateTime(2018, 10, 10),
            minimumDate: DateTime(2018, 10, 11),
          );
        },
        throwsAssertionError,
      );

      expect(() {
          CupertinoDatePicker(
            onDateTimeChanged: (DateTime d) { },
            initialDateTime: DateTime(2018, 10, 10),
            maximumDate: DateTime(2018, 10, 9),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('changing initialDateTime after first build does not do anything', (WidgetTester tester) async {
      DateTime selectedDateTime;
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 400.0,
              width: 400.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                onDateTimeChanged: (DateTime dateTime) => selectedDateTime = dateTime,
                initialDateTime: DateTime(2018, 1, 1, 10, 30),
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('10'), const Offset(0.0, 32.0), touchSlopY: 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(selectedDateTime, DateTime(2018, 1, 1, 9, 30));

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 400.0,
              width: 400.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                onDateTimeChanged: (DateTime dateTime) => selectedDateTime = dateTime,
                // Change the initial date, but it shouldn't affect the present state.
                initialDateTime: DateTime(2016, 4, 5, 15, 00),
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('9'), const Offset(0.0, 32.0), touchSlopY: 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Moving up an hour is still based on the original initial date time.
      expect(selectedDateTime, DateTime(2018, 1, 1, 8, 30));
    });

    testWidgets('date picker has expected string', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 400.0,
              width: 400.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                onDateTimeChanged: (_) { },
                initialDateTime: DateTime(2018, 9, 15, 0, 0),
              ),
            ),
          ),
        ),
      );

      expect(find.text('September'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('2018'), findsOneWidget);
    });

    testWidgets('datetime picker has expected string', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 400.0,
              width: 400.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                onDateTimeChanged: (_) { },
                initialDateTime: DateTime(2018, 9, 15, 3, 14),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sat Sep 15'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);
    });

    testWidgets('width of picker in date and time mode is consistent', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              onDateTimeChanged: (_) { },
              initialDateTime: DateTime(2018, 1, 1, 10, 30),
            ),
          ),
        ),
      );

      // Distance between the first column and the last column.
      final double distance =
          tester.getCenter(find.text('Mon Jan 1 ')).dx - tester.getCenter(find.text('AM')).dx;

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 400.0,
              width: 800.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                onDateTimeChanged: (_) { },
                initialDateTime: DateTime(2018, 1, 1, 10, 30),
              ),
            ),
          ),
        ),
      );

      // Distance between the first and the last column should be the same.
      expect(
        tester.getCenter(find.text('Mon Jan 1 ')).dx - tester.getCenter(find.text('AM')).dx,
        distance,
      );
    });

    testWidgets('width of picker in date mode is consistent', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 400.0,
              width: 400.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                onDateTimeChanged: (_) { },
                initialDateTime: DateTime(2018, 1, 1, 10, 30),
              ),
            ),
          ),
        ),
      );

      // Distance between the first column and the last column.
      final double distance =
          tester.getCenter(find.text('January')).dx - tester.getCenter(find.text('2018')).dx;

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 400.0,
              width: 800.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                onDateTimeChanged: (_) { },
                initialDateTime: DateTime(2018, 1, 1, 10, 30),
              ),
            ),
          ),
        ),
      );

      // Distance between the first and the last column should be the same.
      expect(
        tester.getCenter(find.text('January')).dx - tester.getCenter(find.text('2018')).dx,
        distance,
      );
    });

    testWidgets('width of picker in time mode is consistent', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 400.0,
              width: 400.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                onDateTimeChanged: (_) { },
                initialDateTime: DateTime(2018, 1, 1, 10, 30),
              ),
            ),
          ),
        ),
      );

      // Distance between the first column and the last column.
      final double distance =
          tester.getCenter(find.text('10')).dx - tester.getCenter(find.text('AM')).dx;

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 400.0,
              width: 800.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                onDateTimeChanged: (_) { },
                initialDateTime: DateTime(2018, 1, 1, 10, 30),
              ),
            ),
          ),
        ),
      );

      // Distance between the first and the last column should be the same.
      expect(
        tester.getCenter(find.text('10')).dx - tester.getCenter(find.text('AM')).dx,
        distance,
      );
    });

    testWidgets('picker automatically scrolls away from invalid date on month change', (WidgetTester tester) async {
      DateTime date;
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 400.0,
              width: 400.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                onDateTimeChanged: (DateTime newDate) {
                  date = newDate;
                },
                initialDateTime: DateTime(2018, 3, 30),
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('March'), const Offset(0, 32.0), touchSlopY: 0.0);

      // Momentarily, the 2018 and the incorrect 30 of February is aligned.
      expect(
        tester.getTopLeft(find.text('2018')).dy,
        tester.getTopLeft(find.text('30')).dy,
      );
      await tester.pump(); // Once to trigger the post frame animate call.
      await tester.pump(); // Once to start the DrivenScrollActivity.
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        date,
        DateTime(2018, 2, 28),
      );
      expect(
        tester.getTopLeft(find.text('2018')).dy,
        tester.getTopLeft(find.text('28')).dy,
      );
    });

    testWidgets(
      'date picker automatically scrolls away from invalid date, '
      "and onDateTimeChanged doesn't report these dates",
      (WidgetTester tester) async {
        DateTime date;
        // 2016 is a leap year.
        final DateTime minimum = DateTime(2016, 2, 29);
        final DateTime maximum = DateTime(2018, 12, 31);
        await tester.pumpWidget(
          CupertinoApp(
            home: Center(
              child: SizedBox(
                height: 400.0,
                width: 400.0,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  minimumDate: minimum,
                  maximumDate: maximum,
                  onDateTimeChanged: (DateTime newDate) {
                    date = newDate;
                    // Callback doesn't transiently go into invalid dates.
                    expect(newDate.isAtSameMomentAs(minimum) || newDate.isAfter(minimum), isTrue);
                    expect(newDate.isAtSameMomentAs(maximum) || newDate.isBefore(maximum), isTrue);
                  },
                  initialDateTime: DateTime(2017, 2, 28),
                ),
              ),
            ),
          ),
        );

        // 2017 has 28 days in Feb so 29 is greyed out.
        expect(
          tester.widget<Text>(find.text('29')).style.color,
          isSameColorAs(CupertinoColors.inactiveGray.color),
        );

        await tester.drag(find.text('2017'), const Offset(0.0, 32.0), touchSlopY: 0.0);
        await tester.pump();
        await tester.pumpAndSettle(); // Now the autoscrolling should happen.

        expect(
          date,
          DateTime(2016, 2, 29),
        );

        // 2016 has 29 days in Feb so 29 is not greyed out.
        expect(
          tester.widget<Text>(find.text('29')).style.color,
          isNot(isSameColorAs(CupertinoColors.inactiveGray.color)),
        );

        await tester.drag(find.text('2016'), const Offset(0.0, -32.0), touchSlopY: 0.0);
        await tester.pump(); // Once to trigger the post frame animate call.
        await tester.pumpAndSettle();

        expect(
          date,
          DateTime(2017, 2, 28),
        );

        expect(
          tester.widget<Text>(find.text('29')).style.color,
          isSameColorAs(CupertinoColors.inactiveGray.color),
        );
    });

    testWidgets(
      'dateTime picker automatically scrolls away from invalid date, '
      "and onDateTimeChanged doesn't report these dates",
      (WidgetTester tester) async {
        DateTime date;
        final DateTime minimum = DateTime(2019, 11, 11, 3, 30);
        final DateTime maximum = DateTime(2019, 11, 11, 14, 59, 59);
        await tester.pumpWidget(
          CupertinoApp(
            home: Center(
              child: SizedBox(
                height: 400.0,
                width: 400.0,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  minimumDate: minimum,
                  maximumDate: maximum,
                  onDateTimeChanged: (DateTime newDate) {
                    date = newDate;
                    // Callback doesn't transiently go into invalid dates.
                    expect(minimum.isAfter(newDate), isFalse);
                    expect(maximum.isBefore(newDate), isFalse);
                  },
                  initialDateTime: DateTime(2019, 11, 11, 4),
                ),
              ),
            ),
          ),
        );

        // 3:00 is valid but 2:00 should be invalid.
        expect(
          tester.widget<Text>(find.text('3')).style.color,
          isNot(isSameColorAs(CupertinoColors.inactiveGray.color)),
        );

        expect(
          tester.widget<Text>(find.text('2')).style.color,
          isSameColorAs(CupertinoColors.inactiveGray.color),
        );

        // 'PM' is greyed out.
        expect(
          tester.widget<Text>(find.text('PM')).style.color,
          isSameColorAs(CupertinoColors.inactiveGray.color),
        );

        await tester.drag(find.text('AM'), const Offset(0.0, -32.0), touchSlopY: 0.0);
        await tester.pump();
        await tester.pumpAndSettle(); // Now the autoscrolling should happen.

        expect(
          date,
          DateTime(2019, 11, 11, 14, 59),
        );

        // 3'o clock and 'AM' are now greyed out.
        expect(
          tester.widget<Text>(find.text('AM')).style.color,
          isSameColorAs(CupertinoColors.inactiveGray.color),
        );
        expect(
          tester.widget<Text>(find.text('3')).style.color,
          isSameColorAs(CupertinoColors.inactiveGray.color),
        );

        await tester.drag(find.text('PM'), const Offset(0.0, 32.0), touchSlopY: 0.0);
        await tester.pump(); // Once to trigger the post frame animate call.
        await tester.pumpAndSettle();

        // Returns to min date.
        expect(
          date,
          DateTime(2019, 11, 11, 3, 30),
        );
    });

    testWidgets(
      'time picker automatically scrolls away from invalid date, '
      "and onDateTimeChanged doesn't report these dates",
      (WidgetTester tester) async {
        DateTime date;
        final DateTime minimum = DateTime(2019, 11, 11, 3, 30);
        final DateTime maximum = DateTime(2019, 11, 11, 14, 59, 59);
        await tester.pumpWidget(
          CupertinoApp(
            home: Center(
              child: SizedBox(
                height: 400.0,
                width: 400.0,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  minimumDate: minimum,
                  maximumDate: maximum,
                  onDateTimeChanged: (DateTime newDate) {
                    date = newDate;
                    // Callback doesn't transiently go into invalid dates.
                    expect(minimum.isAfter(newDate), isFalse);
                    expect(maximum.isBefore(newDate), isFalse);
                  },
                  initialDateTime: DateTime(2019, 11, 11, 4),
                ),
              ),
            ),
          ),
        );

        // 3:00 is valid but 2:00 should be invalid.
        expect(
          tester.widget<Text>(find.text('3')).style.color,
          isNot(isSameColorAs(CupertinoColors.inactiveGray.color)),
        );

        expect(
          tester.widget<Text>(find.text('2')).style.color,
          isSameColorAs(CupertinoColors.inactiveGray.color),
        );

        // 'PM' is greyed out.
        expect(
          tester.widget<Text>(find.text('PM')).style.color,
          isSameColorAs(CupertinoColors.inactiveGray.color),
        );

        await tester.drag(find.text('AM'), const Offset(0.0, -32.0), touchSlopY: 0.0);
        await tester.pump();
        await tester.pumpAndSettle(); // Now the autoscrolling should happen.

        expect(
          date,
          DateTime(2019, 11, 11, 14, 59),
        );

        // 3'o clock and 'AM' are now greyed out.
        expect(
          tester.widget<Text>(find.text('AM')).style.color,
          isSameColorAs(CupertinoColors.inactiveGray.color),
        );
        expect(
          tester.widget<Text>(find.text('3')).style.color,
          isSameColorAs(CupertinoColors.inactiveGray.color),
        );

        await tester.drag(find.text('PM'), const Offset(0.0, 32.0), touchSlopY: 0.0);
        await tester.pump(); // Once to trigger the post frame animate call.
        await tester.pumpAndSettle();

        // Returns to min date.
        expect(
          date,
          DateTime(2019, 11, 11, 3, 30),
        );
    });

    testWidgets('picker automatically scrolls away from invalid date on day change', (WidgetTester tester) async {
      DateTime date;
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 400.0,
              width: 400.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                onDateTimeChanged: (DateTime newDate) {
                  date = newDate;
                },
                initialDateTime: DateTime(2018, 2, 27), // 2018 has 28 days in Feb.
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('27'), const Offset(0.0, -32.0), touchSlopY: 0.0);
      await tester.pump();
      expect(
        date,
        DateTime(2018, 2, 28),
      );

      await tester.drag(find.text('28'), const Offset(0.0, -32.0), touchSlopY: 0.0);
      await tester.pump(); // Once to trigger the post frame animate call.

      // Callback doesn't transiently go into invalid dates.
      expect(
        date,
        DateTime(2018, 2, 28),
      );
      // Momentarily, the invalid 29th of Feb is dragged into the middle.
      expect(
        tester.getTopLeft(find.text('2018')).dy,
        tester.getTopLeft(find.text('29')).dy,
      );

      await tester.pump(); // Once to start the DrivenScrollActivity.
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        date,
        DateTime(2018, 2, 28),
      );
      expect(
        tester.getTopLeft(find.text('2018')).dy,
        tester.getTopLeft(find.text('28')).dy,
      );
    });

    testWidgets(
      'date picker should only take into account the date part of minimumDate and maximumDate',
      (WidgetTester tester) async {
        // Regression test for https://github.com/flutter/flutter/issues/49606.
        DateTime date;
        final DateTime minDate = DateTime(2020, 1, 1, 12);
        await tester.pumpWidget(
          CupertinoApp(
            home: Center(
              child: SizedBox(
                height: 400.0,
                width: 400.0,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  minimumDate: minDate,
                  onDateTimeChanged: (DateTime newDate) { date = newDate; },
                  initialDateTime: DateTime(2020, 1, 12),
                ),
              ),
            ),
          ),
        );

        // Scroll to 2019.
        await tester.drag(find.text('2020'), const Offset(0.0, 32.0), touchSlopY: 0.0);
        await tester.pump();
        await tester.pumpAndSettle();
        expect(date.year, minDate.year);
        expect(date.month, minDate.month);
        expect(date.day, minDate.day);
    });


    group('Picker handles initial noon/midnight times', () {
      testWidgets('midnight', (WidgetTester tester) async {
        DateTime date;
        await tester.pumpWidget(
          CupertinoApp(
            home: Center(
              child: SizedBox(
                height: 400.0,
                width: 400.0,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  onDateTimeChanged: (DateTime newDate) {
                    date = newDate;
                  },
                  initialDateTime: DateTime(2019, 1, 1, 0, 15),
                ),
              ),
            ),
          ),
        );

        // 0:15 -> 0:16
        await tester.drag(find.text('15'), _kRowOffset);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(date, DateTime(2019, 1, 1, 0, 16));
      });

      testWidgets('noon', (WidgetTester tester) async {
        DateTime date;
        await tester.pumpWidget(
          CupertinoApp(
            home: Center(
              child: SizedBox(
                height: 400.0,
                width: 400.0,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  onDateTimeChanged: (DateTime newDate) {
                    date = newDate;
                  },
                  initialDateTime: DateTime(2019, 1, 1, 12, 15),
                ),
              ),
            ),
          ),
        );

        // 12:15 -> 12:16
        await tester.drag(find.text('15'), _kRowOffset);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(date, DateTime(2019, 1, 1, 12, 16));
      });

      testWidgets('noon in 24 hour time', (WidgetTester tester) async {
        DateTime date;
        await tester.pumpWidget(
          CupertinoApp(
            home: Center(
              child: SizedBox(
                height: 400.0,
                width: 400.0,
                child: CupertinoDatePicker(
                  use24hFormat: true,
                  mode: CupertinoDatePickerMode.time,
                  onDateTimeChanged: (DateTime newDate) {
                    date = newDate;
                  },
                  initialDateTime: DateTime(2019, 1, 1, 12, 25),
                ),
              ),
            ),
          ),
        );

        // 12:25 -> 12:26
        await tester.drag(find.text('25'), _kRowOffset);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(date, DateTime(2019, 1, 1, 12, 26));
      });
    });

    testWidgets('picker persists am/pm value when scrolling hours', (WidgetTester tester) async {
      DateTime date;
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 400.0,
              width: 400.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                onDateTimeChanged: (DateTime newDate) {
                  date = newDate;
                },
                initialDateTime: DateTime(2019, 1, 1, 3),
              ),
            ),
          ),
        ),
      );

      // 3:00 -> 15:00
      await tester.drag(find.text('AM'), _kRowOffset);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(date, DateTime(2019, 1, 1, 15));

      // 15:00 -> 16:00
      await tester.drag(find.text('3'), _kRowOffset);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(date, DateTime(2019, 1, 1, 16));

      // 16:00 -> 4:00
      await tester.drag(find.text('PM'), -_kRowOffset);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(date, DateTime(2019, 1, 1, 4));

      // 4:00 -> 3:00
      await tester.drag(find.text('4'), -_kRowOffset);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(date, DateTime(2019, 1, 1, 3));
    });

    testWidgets('picker automatically scrolls the am/pm column when the hour column changes enough', (WidgetTester tester) async {
      DateTime date;
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 400.0,
              width: 400.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                onDateTimeChanged: (DateTime newDate) {
                  date = newDate;
                },
                initialDateTime: DateTime(2018, 1, 1, 11, 59),
              ),
            ),
          ),
        ),
      );

      const Offset deltaOffset = Offset(0.0, -18.0);

      // 11:59 -> 12:59
      await tester.drag(find.text('11'), _kRowOffset);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(date, DateTime(2018, 1, 1, 12, 59));

      // 12:59 -> 11:59
      await tester.drag(find.text('12'), -_kRowOffset);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(date, DateTime(2018, 1, 1, 11, 59));

      // 11:59 -> 9:59
      await tester.drag(find.text('11'), -((_kRowOffset - deltaOffset) * 2 + deltaOffset));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(date, DateTime(2018, 1, 1, 9, 59));

      // 9:59 -> 15:59
      await tester.drag(find.text('9'), (_kRowOffset - deltaOffset) * 6 + deltaOffset);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(date, DateTime(2018, 1, 1, 15, 59));
    });

    testWidgets('date picker given too narrow space horizontally shows message', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              // This is too small to draw the picker out fully.
              width: 100,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: DateTime(2019, 1, 1, 4),
                onDateTimeChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      final dynamic exception = tester.takeException();
      expect(exception, isFlutterError);
      expect(
        exception.toString(),
        contains('Insufficient horizontal space to render the CupertinoDatePicker'),
      );
    });

    testWidgets('DatePicker golden tests', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              width: 500,
              height: 400,
              child: RepaintBoundary(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: DateTime(2019, 1, 1, 4),
                  onDateTimeChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CupertinoDatePicker),
        matchesGoldenFile('date_picker_test.datetime.initial.png'),
      );

      // Slightly drag the hour component to make the current hour off-center.
      await tester.drag(find.text('4'), Offset(0, _kRowOffset.dy / 2));
      await tester.pump();

      await expectLater(
        find.byType(CupertinoDatePicker),
        matchesGoldenFile('date_picker_test.datetime.drag.png'),
      );
    });

    testWidgets('DatePicker displays hours and minutes correctly in RTL', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: SizedBox(
                width: 500,
                height: 400,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: DateTime(2019, 1, 1, 4),
                  onDateTimeChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      final double hourLeft = tester.getTopLeft(find.text('4')).dx;
      final double minuteLeft = tester.getTopLeft(find.text('00')).dx;
      expect(hourLeft, lessThan(minuteLeft));
    });
  });

  testWidgets('TimerPicker golden tests', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        // Also check if the picker respects the theme.
        theme: const CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            pickerTextStyle: TextStyle(
              color: Color(0xFF663311),
            ),
          ),
        ),
        home: Center(
          child: SizedBox(
            width: 320,
            height: 216,
            child: RepaintBoundary(
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                initialTimerDuration: const Duration(hours: 23, minutes: 59),
                onTimerDurationChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(CupertinoTimerPicker),
      matchesGoldenFile('timer_picker_test.datetime.initial.png'),
    );

    // Slightly drag the minute component to make the current minute off-center.
    await tester.drag(find.text('59'), Offset(0, _kRowOffset.dy / 2));
    await tester.pump();

    await expectLater(
      find.byType(CupertinoTimerPicker),
      matchesGoldenFile('timer_picker_test.datetime.drag.png'),
    );
  });

  testWidgets('TimerPicker only changes hour label after scrolling stops', (WidgetTester tester) async {
    Duration duration;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: SizedBox(
            width: 320,
            height: 216,
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hm,
              initialTimerDuration: const Duration(hours: 2, minutes: 30),
              onTimerDurationChanged: (Duration d) { duration = d; },
            ),
          ),
        ),
      ),
    );

    expect(duration, isNull);
    expect(find.text('hour'), findsNothing);
    expect(find.text('hours'), findsOneWidget);

    await tester.drag(find.text('2'), Offset(0, -_kRowOffset.dy));
    // Duration should change but not the label.
    expect(duration?.inHours, 1);
    expect(find.text('hour'), findsNothing);
    expect(find.text('hours'), findsOneWidget);
    await tester.pumpAndSettle();

    // Now the label should change.
    expect(duration?.inHours, 1);
    expect(find.text('hours'), findsNothing);
    expect(find.text('hour'), findsOneWidget);
  });

  testWidgets('TimerPicker has intrinsic width and height', (WidgetTester tester) async {
    const Key key = Key('key');

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTimerPicker(
          key: key,
          mode: CupertinoTimerPickerMode.hm,
          initialTimerDuration: const Duration(hours: 2, minutes: 30),
          onTimerDurationChanged: (Duration d) {},
        ),
      ),
    );

    expect(tester.getSize(find.descendant(of: find.byKey(key), matching: find.byType(Row))), const Size(320, 216));

    // Different modes shouldn't share state.
    await tester.pumpWidget(const Placeholder());
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTimerPicker(
          key: key,
          mode: CupertinoTimerPickerMode.ms,
          initialTimerDuration: const Duration(minutes: 30, seconds: 3),
          onTimerDurationChanged: (Duration d) {},
        ),
      ),
    );

    expect(tester.getSize(find.descendant(of: find.byKey(key), matching: find.byType(Row))), const Size(320, 216));

    // Different modes shouldn't share state.
    await tester.pumpWidget(const Placeholder());
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTimerPicker(
          key: key,
          mode: CupertinoTimerPickerMode.hms,
          initialTimerDuration: const Duration(hours: 5, minutes: 17, seconds: 19),
          onTimerDurationChanged: (Duration d) {},
        ),
      ),
    );

    expect(tester.getSize(find.descendant(of: find.byKey(key), matching: find.byType(Row))), const Size(330, 216));
  });

  testWidgets('scrollController can be removed or added', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    int lastSelectedItem;
    void onSelectedItemChanged(int index) {
      lastSelectedItem = index;
    }
    await tester.pumpWidget(_buildPicker(
      controller: FixedExtentScrollController(),
      onSelectedItemChanged: onSelectedItemChanged,
    ));

    tester.binding.pipelineOwner.semanticsOwner.performAction(1, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(lastSelectedItem, 1);

    await tester.pumpWidget(_buildPicker(
      onSelectedItemChanged: onSelectedItemChanged,
    ));

    tester.binding.pipelineOwner.semanticsOwner.performAction(1, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(lastSelectedItem, 2);

    await tester.pumpWidget(_buildPicker(
      controller: FixedExtentScrollController(),
      onSelectedItemChanged: onSelectedItemChanged,
    ));

    tester.binding.pipelineOwner.semanticsOwner.performAction(1, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(lastSelectedItem, 3);

    handle.dispose();
  });

  testWidgets('CupertinoDataPicker does not provide invalid MediaQuery', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/47989.
    Brightness brightness = Brightness.light;
    StateSetter setState;

    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(
              color: CupertinoDynamicColor.withBrightness(
                color: Color(0xFFFFFFFF),
                darkColor: Color(0xFF000000),
              ),
            ),
          ),
        ),
        home: StatefulBuilder(builder: (BuildContext context, StateSetter stateSetter) {
          setState = stateSetter;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(platformBrightness: brightness),
            child: CupertinoDatePicker(
              initialDateTime: DateTime(2019),
              mode: CupertinoDatePickerMode.date,
              onDateTimeChanged: (DateTime date) {},
            ),
          );
        }),
      ),
    );

    expect(
      tester.widget<Text>(find.text('2019')).style.color,
      isSameColorAs(const Color(0xFFFFFFFF)),
    );

    setState(() { brightness = Brightness.dark; });
    await tester.pump();

    expect(
      tester.widget<Text>(find.text('2019')).style.color,
      isSameColorAs(const Color(0xFF000000)),
    );
  });

  testWidgets('picker exports semantics', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    debugResetSemanticsIdCounter();
    int lastSelectedItem;
    await tester.pumpWidget(_buildPicker(onSelectedItemChanged: (int index) {
      lastSelectedItem = index;
    }));

    expect(tester.getSemantics(find.byType(CupertinoPicker)), matchesSemantics(
      children: <Matcher>[
        matchesSemantics(
          hasIncreaseAction: true,
          hasDecreaseAction: false,
          increasedValue: '1',
          value: '0',
          textDirection: TextDirection.ltr,
        ),
      ],
    ));

    tester.binding.pipelineOwner.semanticsOwner.performAction(1, SemanticsAction.increase);
    await tester.pumpAndSettle();

    expect(tester.getSemantics(find.byType(CupertinoPicker)), matchesSemantics(
      children: <Matcher>[
        matchesSemantics(
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          increasedValue: '2',
          decreasedValue: '0',
          value: '1',
          textDirection: TextDirection.ltr,
        ),
      ],
    ));
    expect(lastSelectedItem, 1);
    handle.dispose();
  });
}

Widget _buildPicker({ FixedExtentScrollController controller, ValueChanged<int> onSelectedItemChanged }) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: CupertinoPicker(
      scrollController: controller,
      itemExtent: 100.0,
      onSelectedItemChanged: onSelectedItemChanged,
      children: List<Widget>.generate(100, (int index) {
        return Center(
          child: Container(
            width: 400.0,
            height: 100.0,
            child: Text(index.toString()),
          ),
        );
      }),
    ),
  );
}
