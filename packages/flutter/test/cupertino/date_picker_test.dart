// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
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
        CupertinoApp(
          home: CupertinoTimerPicker(
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
        CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: CupertinoTimerPicker(
              onTimerDurationChanged: (_) {},
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

      expect(tester.getTopLeft(find.text('min')).dx > lastOffset.dx, false);
      lastOffset = tester.getTopLeft(find.text('min'));

      expect(tester.getTopLeft(find.text('59')).dx > lastOffset.dx, false);
      lastOffset = tester.getTopLeft(find.text('59'));

      expect(tester.getTopLeft(find.text('sec')).dx > lastOffset.dx, false);
    });

    testWidgets('width of picker is consistent', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
            height: 400.0,
            width: 400.0,
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
        CupertinoApp(
          home: SizedBox(
            height: 400.0,
            width: 800.0,
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
          CupertinoDatePicker(
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
          CupertinoDatePicker(
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
          CupertinoDatePicker(
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
          CupertinoDatePicker(
            onDateTimeChanged: (_) {},
            initialDateTime: null,
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('changing initialDateTime after first build does not do anything', (WidgetTester tester) async {
      DateTime selectedDateTime;
      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
            height: 400.0,
            width: 400.0,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              onDateTimeChanged: (DateTime dateTime) => selectedDateTime = dateTime,
              initialDateTime: DateTime(2018, 1, 1, 10, 30),
            ),
          ),
        ),
      );

      await tester.drag(find.text('10'), const Offset(0.0, 32.0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(selectedDateTime, DateTime(2018, 1, 1, 9, 30));

      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
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
      );

      await tester.drag(find.text('9'), const Offset(0.0, 32.0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Moving up an hour is still based on the original initial date time.
      expect(selectedDateTime, DateTime(2018, 1, 1, 8, 30));
    });

    testWidgets('date picker has expected string', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
            height: 400.0,
            width: 400.0,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              onDateTimeChanged: (_) {},
              initialDateTime: DateTime(2018, 9, 15, 0, 0),
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
          home: SizedBox(
            height: 400.0,
            width: 400.0,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              onDateTimeChanged: (_) {},
              initialDateTime: DateTime(2018, 9, 15, 3, 14),
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
              onDateTimeChanged: (_) {},
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
          home: SizedBox(
            height: 400.0,
            width: 800.0,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              onDateTimeChanged: (_) {},
              initialDateTime: DateTime(2018, 1, 1, 10, 30),
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
          home: SizedBox(
            height: 400.0,
            width: 400.0,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              onDateTimeChanged: (_) {},
              initialDateTime: DateTime(2018, 1, 1, 10, 30),
            ),
          ),
        ),
      );

      // Distance between the first column and the last column.
      final double distance =
          tester.getCenter(find.text('January')).dx - tester.getCenter(find.text('2018')).dx;

      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
            height: 400.0,
            width: 800.0,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              onDateTimeChanged: (_) {},
              initialDateTime: DateTime(2018, 1, 1, 10, 30),
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
          home: SizedBox(
            height: 400.0,
            width: 400.0,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              onDateTimeChanged: (_) {},
              initialDateTime: DateTime(2018, 1, 1, 10, 30),
            ),
          ),
        ),
      );

      // Distance between the first column and the last column.
      final double distance =
          tester.getCenter(find.text('10')).dx - tester.getCenter(find.text('AM')).dx;

      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
            height: 400.0,
            width: 800.0,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              onDateTimeChanged: (_) {},
              initialDateTime: DateTime(2018, 1, 1, 10, 30),
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
          home: SizedBox(
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
      );

      await tester.drag(find.text('March'), const Offset(0.0, 32.0));
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

    testWidgets('picker automatically scrolls away from invalid date on day change', (WidgetTester tester) async {
      DateTime date;
      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
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
      );

      await tester.drag(find.text('27'), const Offset(0.0, -32.0));
      await tester.pump();
      expect(
        date,
        DateTime(2018, 2, 28),
      );


      await tester.drag(find.text('28'), const Offset(0.0, -32.0));
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

    testWidgets('picker automatically scrolls the am/pm column when the hour column changes enough', (WidgetTester tester) async {
      DateTime date;
      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
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
      );

      await tester.drag(find.text('11'), const Offset(0.0, -32.0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(date, DateTime(2018, 1, 1, 12, 59));

      await tester.drag(find.text('12'), const Offset(0.0, 32.0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(date, DateTime(2018, 1, 1, 11, 59));

      await tester.drag(find.text('11'), const Offset(0.0, 64.0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(date, DateTime(2018, 1, 1, 9, 59));

      await tester.drag(find.text('9'), const Offset(0.0, -192.0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(date, DateTime(2018, 1, 1, 15, 59));
    });
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

Widget _buildPicker({FixedExtentScrollController controller, ValueChanged<int> onSelectedItemChanged}) {
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
