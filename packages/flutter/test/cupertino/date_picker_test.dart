// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

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
            onTimerDurationChanged: (_) {},
            initialTimerDuration: const Duration(days: 1),
          );
        },
        throwsAssertionError,
      );

      expect(
        () {
          CupertinoTimerPicker(
            onTimerDurationChanged: (_) {},
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
            onTimerDurationChanged: (_) {},
            minuteInterval: 0,
          );
        },
        throwsAssertionError,
      );
      expect(
        () {
          CupertinoTimerPicker(
            onTimerDurationChanged: (_) {},
            minuteInterval: -1,
          );
        },
        throwsAssertionError,
      );
      expect(
        () {
          CupertinoTimerPicker(
            onTimerDurationChanged: (_) {},
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
            onTimerDurationChanged: (_) {},
            secondInterval: 0,
          );
        },
        throwsAssertionError,
      );
      expect(
        () {
          CupertinoTimerPicker(
            onTimerDurationChanged: (_) {},
            secondInterval: -1,
          );
        },
        throwsAssertionError,
      );
      expect(
        () {
          CupertinoTimerPicker(
            onTimerDurationChanged: (_) {},
            secondInterval: 7,
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('columns are ordered correctly when text direction is ltr', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CupertinoTimerPicker(
            onTimerDurationChanged: (_) {},
            initialTimerDuration: const Duration(hours: 12, minutes: 30, seconds: 59),
          ),
        ),
      );

      Offset lastOffset = tester.getTopLeft(find.text('12'));

      expect(tester.getTopLeft(find.text('hours')).dx > lastOffset.dx, true);
      lastOffset = tester.getTopLeft(find.text('hours'));

      expect(tester.getTopLeft(find.text('30')).dx > lastOffset.dx, true);
      lastOffset = tester.getTopLeft(find.text('30'));

      expect(tester.getTopLeft(find.text('min')).dx > lastOffset.dx, true);
      lastOffset = tester.getTopLeft(find.text('min'));

      expect(tester.getTopLeft(find.text('59')).dx > lastOffset.dx, true);
      lastOffset = tester.getTopLeft(find.text('59'));

      expect(tester.getTopLeft(find.text('sec')).dx > lastOffset.dx, true);
    });

    testWidgets('columns are ordered correctly when text direction is rtl', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: CupertinoTimerPicker(
            onTimerDurationChanged: (_) {},
            initialTimerDuration: const Duration(hours: 12, minutes: 30, seconds: 59),
          ),
        ),
      );

      Offset lastOffset = tester.getTopLeft(find.text('12'));

      expect(tester.getTopLeft(find.text('hours')).dx > lastOffset.dx, false);
      lastOffset = tester.getTopLeft(find.text('hours'));

      expect(tester.getTopLeft(find.text('30')).dx > lastOffset.dx, false);
      lastOffset = tester.getTopLeft(find.text('30'));

      expect(tester.getTopLeft(find.text('min')).dx > lastOffset.dx, false);
      lastOffset = tester.getTopLeft(find.text('min'));

      expect(tester.getTopLeft(find.text('59')).dx > lastOffset.dx, false);
      lastOffset = tester.getTopLeft(find.text('59'));

      expect(tester.getTopLeft(find.text('sec')).dx > lastOffset.dx, false);
    });

    testWidgets('width of picker is consistent', (WidgetTester tester) async {
      await tester.pumpWidget(
        SizedBox(
          height: 400.0,
          width: 400.0,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CupertinoTimerPicker(
              onTimerDurationChanged: (_) {},
              initialTimerDuration: const Duration(hours: 12, minutes: 30, seconds: 59),
            ),
          ),
        ),
      );

      // Distance between the first column and the last column.
      final double distance =
        tester.getCenter(find.text('sec')).dx - tester.getCenter(find.text('12')).dx;

      await tester.pumpWidget(
        SizedBox(
          height: 400.0,
          width: 800.0,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CupertinoTimerPicker(
              onTimerDurationChanged: (_) {},
              initialTimerDuration: const Duration(hours: 12, minutes: 30, seconds: 59),
            ),
          ),
        ),
      );

      // Distance between the first and the last column should be the same.
      expect(
        tester.getCenter(find.text('sec')).dx - tester.getCenter(find.text('12')).dx,
        distance,
      );
    });
  });
  group('Date picker', () {
    testWidgets('mode is not null', (WidgetTester tester) async {
      expect(
        () {
          new CupertinoDatePicker(
            mode: null,
            onDateTimeChanged: (_) {},
            initialDateTime: DateTime.now(),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('onDateTimeChanged is not null', (WidgetTester tester) async {
      expect(
        () {
          new CupertinoDatePicker(
            onDateTimeChanged: null,
            initialDateTime: DateTime.now(),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('initial date time is not null', (WidgetTester tester) async {
      expect(
        () {
          new CupertinoDatePicker(
            onDateTimeChanged: (_) {},
            initialDateTime: null,
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('initial date time is not null', (WidgetTester tester) async {
      expect(
            () {
          new CupertinoDatePicker(
            onDateTimeChanged: (_) {},
            initialDateTime: null,
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('width of picker in date and time mode is consistent', (WidgetTester tester) async {
      await tester.pumpWidget(
        new SizedBox(
          height: 400.0,
          width: 400.0,
          child: new Directionality(
            textDirection: TextDirection.ltr,
            child: new CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              onDateTimeChanged: (_) {},
              initialDateTime: new DateTime(2018, 1, 1, 10, 30),
            ),
          ),
        ),
      );

      // Distance between the first column and the last column.
      final double distance =
          tester.getCenter(find.text('Mon Jan 1')).dx - tester.getCenter(find.text('AM')).dx;

      await tester.pumpWidget(
        new SizedBox(
          height: 400.0,
          width: 800.0,
          child: new Directionality(
            textDirection: TextDirection.ltr,
            child: new CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              onDateTimeChanged: (_) {},
              initialDateTime: new DateTime(2018, 1, 1, 10, 30),
            ),
          ),
        ),
      );

      // Distance between the first and the last column should be the same.
      expect(
        tester.getCenter(find.text('Mon Jan 1')).dx - tester.getCenter(find.text('AM')).dx,
        distance,
      );
    });

    testWidgets('width of picker in date mode is consistent', (WidgetTester tester) async {
      await tester.pumpWidget(
        new SizedBox(
          height: 400.0,
          width: 400.0,
          child: new Directionality(
            textDirection: TextDirection.ltr,
            child: new CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              onDateTimeChanged: (_) {},
              initialDateTime: new DateTime(2018, 1, 1, 10, 30),
            ),
          ),
        ),
      );

      // Distance between the first column and the last column.
      final double distance =
          tester.getCenter(find.text('January')).dx - tester.getCenter(find.text('2018')).dx;

      await tester.pumpWidget(
        new SizedBox(
          height: 400.0,
          width: 800.0,
          child: new Directionality(
            textDirection: TextDirection.ltr,
            child: new CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              onDateTimeChanged: (_) {},
              initialDateTime: new DateTime(2018, 1, 1, 10, 30),
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
        new SizedBox(
          height: 400.0,
          width: 400.0,
          child: new Directionality(
            textDirection: TextDirection.ltr,
            child: new CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              onDateTimeChanged: (_) {},
              initialDateTime: new DateTime(2018, 1, 1, 10, 30),
            ),
          ),
        ),
      );

      // Distance between the first column and the last column.
      final double distance =
          tester.getCenter(find.text('10')).dx - tester.getCenter(find.text('AM')).dx;

      await tester.pumpWidget(
        new SizedBox(
          height: 400.0,
          width: 800.0,
          child: new Directionality(
            textDirection: TextDirection.ltr,
            child: new CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              onDateTimeChanged: (_) {},
              initialDateTime: new DateTime(2018, 1, 1, 10, 30),
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

    // This test currently fails because of an issue with FixedExtentScrollController.animateToItem().
    testWidgets('picker automatically scrolls away from invalid date', (WidgetTester tester) async {
      DateTime date;
      await tester.pumpWidget(
        new SizedBox(
          height: 400.0,
          width: 400.0,
          child: new Directionality(
            textDirection: TextDirection.ltr,
            child: new CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              onDateTimeChanged: (DateTime newDate) {
                date = newDate;
              },
              initialDateTime: new DateTime(2018, 3, 30),
            ),
          ),
        ),
      );

      await tester.drag(find.text('March'), const Offset(0.0, 32.0));
      await tester.pumpAndSettle();
      
      expect(
        date,
        new DateTime(2018, 2, 28),
      );
    });

    testWidgets('picker automatically scrolls the am/pm column when the hour column changes enough', (WidgetTester tester) async {
      DateTime date;
      await tester.pumpWidget(
        new SizedBox(
          height: 400.0,
          width: 400.0,
          child: new Directionality(
            textDirection: TextDirection.ltr,
            child: new CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              onDateTimeChanged: (DateTime newDate) {
                date = newDate;
              },
              initialDateTime: new DateTime(2018, 1, 1, 11, 59),
            ),
          ),
        ),
      );

      await tester.drag(find.text('11'), const Offset(0.0, -32.0));
      await tester.pumpAndSettle();

      expect(date, new DateTime(2018, 1, 1, 12, 59));

      await tester.drag(find.text('12'), const Offset(0.0, 32.0));
      await tester.pumpAndSettle();

      expect(date, new DateTime(2018, 1, 1, 11, 59));

      await tester.drag(find.text('11'), const Offset(0.0, 64.0));
      await tester.pumpAndSettle();

      expect(date, new DateTime(2018, 1, 1, 9, 59));

      await tester.drag(find.text('09'), const Offset(0.0, -192.0));
      await tester.pumpAndSettle();

      expect(date, new DateTime(2018, 1, 1, 15, 59));
    });
  });
}