// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:table_calendar/table_calendar.dart';

import 'common.dart';

Widget setupTestWidget(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: child,
  );
}

void main() {
  group('Correct days are displayed for given focusedDay when:', () {
    testWidgets(
      'in month format, starting day is Sunday',
      (tester) async {
        final focusedDay = DateTime.utc(2021, 7, 15);

        await tester.pumpWidget(
          setupTestWidget(
            TableCalendarBase(
              firstDay: DateTime.utc(2021, 5, 15),
              lastDay: DateTime.utc(2021, 8, 18),
              focusedDay: focusedDay,
              dayBuilder: (context, day, focusedDay) {
                return Text(
                  '${day.day}',
                  key: dateToKey(day),
                );
              },
              rowHeight: 52,
              dowVisible: false,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,
            ),
          ),
        );

        final firstVisibleDay = DateTime.utc(2021, 6, 27);
        final lastVisibleDay = DateTime.utc(2021, 7, 31);

        final focusedDayKey = dateToKey(focusedDay);
        final firstVisibleDayKey = dateToKey(firstVisibleDay);
        final lastVisibleDayKey = dateToKey(lastVisibleDay);

        final startOOBKey =
            dateToKey(firstVisibleDay.subtract(const Duration(days: 1)));
        final endOOBKey =
            dateToKey(lastVisibleDay.add(const Duration(days: 1)));

        expect(find.byKey(focusedDayKey), findsOneWidget);
        expect(find.byKey(firstVisibleDayKey), findsOneWidget);
        expect(find.byKey(lastVisibleDayKey), findsOneWidget);

        expect(find.byKey(startOOBKey), findsNothing);
        expect(find.byKey(endOOBKey), findsNothing);
      },
    );

    testWidgets(
      'in two weeks format, starting day is Sunday',
      (tester) async {
        final focusedDay = DateTime.utc(2021, 7, 15);

        await tester.pumpWidget(
          setupTestWidget(
            TableCalendarBase(
              firstDay: DateTime.utc(2021, 5, 15),
              lastDay: DateTime.utc(2021, 8, 18),
              focusedDay: focusedDay,
              dayBuilder: (context, day, focusedDay) {
                return Text(
                  '${day.day}',
                  key: dateToKey(day),
                );
              },
              rowHeight: 52,
              dowVisible: false,
              calendarFormat: CalendarFormat.twoWeeks,
              startingDayOfWeek: StartingDayOfWeek.sunday,
            ),
          ),
        );

        final firstVisibleDay = DateTime.utc(2021, 7, 4);
        final lastVisibleDay = DateTime.utc(2021, 7, 17);

        final focusedDayKey = dateToKey(focusedDay);
        final firstVisibleDayKey = dateToKey(firstVisibleDay);
        final lastVisibleDayKey = dateToKey(lastVisibleDay);

        final startOOBKey =
            dateToKey(firstVisibleDay.subtract(const Duration(days: 1)));
        final endOOBKey =
            dateToKey(lastVisibleDay.add(const Duration(days: 1)));

        expect(find.byKey(focusedDayKey), findsOneWidget);
        expect(find.byKey(firstVisibleDayKey), findsOneWidget);
        expect(find.byKey(lastVisibleDayKey), findsOneWidget);

        expect(find.byKey(startOOBKey), findsNothing);
        expect(find.byKey(endOOBKey), findsNothing);
      },
    );

    testWidgets(
      'in week format, starting day is Sunday',
      (tester) async {
        final focusedDay = DateTime.utc(2021, 7, 15);

        await tester.pumpWidget(
          setupTestWidget(
            TableCalendarBase(
              firstDay: DateTime.utc(2021, 5, 15),
              lastDay: DateTime.utc(2021, 8, 18),
              focusedDay: focusedDay,
              dayBuilder: (context, day, focusedDay) {
                return Text(
                  '${day.day}',
                  key: dateToKey(day),
                );
              },
              rowHeight: 52,
              dowVisible: false,
              calendarFormat: CalendarFormat.week,
              startingDayOfWeek: StartingDayOfWeek.sunday,
            ),
          ),
        );

        final firstVisibleDay = DateTime.utc(2021, 7, 11);
        final lastVisibleDay = DateTime.utc(2021, 7, 17);

        final focusedDayKey = dateToKey(focusedDay);
        final firstVisibleDayKey = dateToKey(firstVisibleDay);
        final lastVisibleDayKey = dateToKey(lastVisibleDay);

        final startOOBKey =
            dateToKey(firstVisibleDay.subtract(const Duration(days: 1)));
        final endOOBKey =
            dateToKey(lastVisibleDay.add(const Duration(days: 1)));

        expect(find.byKey(focusedDayKey), findsOneWidget);
        expect(find.byKey(firstVisibleDayKey), findsOneWidget);
        expect(find.byKey(lastVisibleDayKey), findsOneWidget);

        expect(find.byKey(startOOBKey), findsNothing);
        expect(find.byKey(endOOBKey), findsNothing);
      },
    );

    testWidgets(
      'in month format, starting day is Monday',
      (tester) async {
        final focusedDay = DateTime.utc(2021, 7, 15);

        await tester.pumpWidget(
          setupTestWidget(
            TableCalendarBase(
              firstDay: DateTime.utc(2021, 5, 15),
              lastDay: DateTime.utc(2021, 8, 18),
              focusedDay: focusedDay,
              dayBuilder: (context, day, focusedDay) {
                return Text(
                  '${day.day}',
                  key: dateToKey(day),
                );
              },
              rowHeight: 52,
              dowVisible: false,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
            ),
          ),
        );

        final firstVisibleDay = DateTime.utc(2021, 6, 28);
        final lastVisibleDay = DateTime.utc(2021, 8, 1);

        final focusedDayKey = dateToKey(focusedDay);
        final firstVisibleDayKey = dateToKey(firstVisibleDay);
        final lastVisibleDayKey = dateToKey(lastVisibleDay);

        final startOOBKey =
            dateToKey(firstVisibleDay.subtract(const Duration(days: 1)));
        final endOOBKey =
            dateToKey(lastVisibleDay.add(const Duration(days: 1)));

        expect(find.byKey(focusedDayKey), findsOneWidget);
        expect(find.byKey(firstVisibleDayKey), findsOneWidget);
        expect(find.byKey(lastVisibleDayKey), findsOneWidget);

        expect(find.byKey(startOOBKey), findsNothing);
        expect(find.byKey(endOOBKey), findsNothing);
      },
    );

    testWidgets(
      'in two weeks format, starting day is Monday',
      (tester) async {
        final focusedDay = DateTime.utc(2021, 7, 15);

        await tester.pumpWidget(
          setupTestWidget(
            TableCalendarBase(
              firstDay: DateTime.utc(2021, 5, 15),
              lastDay: DateTime.utc(2021, 8, 18),
              focusedDay: focusedDay,
              dayBuilder: (context, day, focusedDay) {
                return Text(
                  '${day.day}',
                  key: dateToKey(day),
                );
              },
              rowHeight: 52,
              dowVisible: false,
              calendarFormat: CalendarFormat.twoWeeks,
              startingDayOfWeek: StartingDayOfWeek.monday,
            ),
          ),
        );

        final firstVisibleDay = DateTime.utc(2021, 7, 5);
        final lastVisibleDay = DateTime.utc(2021, 7, 18);

        final focusedDayKey = dateToKey(focusedDay);
        final firstVisibleDayKey = dateToKey(firstVisibleDay);
        final lastVisibleDayKey = dateToKey(lastVisibleDay);

        final startOOBKey =
            dateToKey(firstVisibleDay.subtract(const Duration(days: 1)));
        final endOOBKey =
            dateToKey(lastVisibleDay.add(const Duration(days: 1)));

        expect(find.byKey(focusedDayKey), findsOneWidget);
        expect(find.byKey(firstVisibleDayKey), findsOneWidget);
        expect(find.byKey(lastVisibleDayKey), findsOneWidget);

        expect(find.byKey(startOOBKey), findsNothing);
        expect(find.byKey(endOOBKey), findsNothing);
      },
    );

    testWidgets(
      'in week format, starting day is Monday',
      (tester) async {
        final focusedDay = DateTime.utc(2021, 7, 15);

        await tester.pumpWidget(
          setupTestWidget(
            TableCalendarBase(
              firstDay: DateTime.utc(2021, 5, 15),
              lastDay: DateTime.utc(2021, 8, 18),
              focusedDay: focusedDay,
              dayBuilder: (context, day, focusedDay) {
                return Text(
                  '${day.day}',
                  key: dateToKey(day),
                );
              },
              rowHeight: 52,
              dowVisible: false,
              calendarFormat: CalendarFormat.week,
              startingDayOfWeek: StartingDayOfWeek.monday,
            ),
          ),
        );

        final firstVisibleDay = DateTime.utc(2021, 7, 12);
        final lastVisibleDay = DateTime.utc(2021, 7, 18);

        final focusedDayKey = dateToKey(focusedDay);
        final firstVisibleDayKey = dateToKey(firstVisibleDay);
        final lastVisibleDayKey = dateToKey(lastVisibleDay);

        final startOOBKey =
            dateToKey(firstVisibleDay.subtract(const Duration(days: 1)));
        final endOOBKey =
            dateToKey(lastVisibleDay.add(const Duration(days: 1)));

        expect(find.byKey(focusedDayKey), findsOneWidget);
        expect(find.byKey(firstVisibleDayKey), findsOneWidget);
        expect(find.byKey(lastVisibleDayKey), findsOneWidget);

        expect(find.byKey(startOOBKey), findsNothing);
        expect(find.byKey(endOOBKey), findsNothing);
      },
    );
  });

  testWidgets(
    'Callbacks return expected values',
    (tester) async {
      DateTime focusedDay = DateTime.utc(2021, 7, 15);
      final nextMonth = focusedDay.add(const Duration(days: 31)).month;

      bool calendarCreatedFlag = false;
      SwipeDirection? verticalSwipeDirection;

      await tester.pumpWidget(
        setupTestWidget(
          TableCalendarBase(
            firstDay: DateTime.utc(2021, 5, 15),
            lastDay: DateTime.utc(2021, 8, 18),
            focusedDay: focusedDay,
            dayBuilder: (context, day, focusedDay) {
              return Text(
                '${day.day}',
                key: dateToKey(day),
              );
            },
            onCalendarCreated: (pageController) {
              calendarCreatedFlag = true;
            },
            onPageChanged: (focusedDay2) {
              focusedDay = focusedDay2;
            },
            onVerticalSwipe: (direction) {
              verticalSwipeDirection = direction;
            },
            rowHeight: 52,
            dowVisible: false,
          ),
        ),
      );

      expect(calendarCreatedFlag, true);

      // Swipe left
      await tester.drag(
        find.byKey(dateToKey(focusedDay)),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      expect(focusedDay.month, nextMonth);

      // Swipe up
      await tester.drag(
        find.byKey(dateToKey(focusedDay)),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(verticalSwipeDirection, SwipeDirection.up);
    },
  );

  testWidgets(
    'Throw AssertionError when TableCalendarBase is built with dowVisible and dowBuilder, but dowHeight is absent',
    (tester) async {
      expect(() async {
        await tester.pumpWidget(
          setupTestWidget(
            TableCalendarBase(
              firstDay: DateTime.utc(2021, 5, 15),
              lastDay: DateTime.utc(2021, 8, 18),
              focusedDay: DateTime.utc(2021, 7, 15),
              dayBuilder: (context, day, focusedDay) {
                return Text(
                  '${day.day}',
                  key: dateToKey(day),
                );
              },
              rowHeight: 52,
              dowVisible: true,
              dowBuilder: (context, day) {
                return Text('${day.weekday}');
              },
            ),
          ),
        );
      }, throwsAssertionError);
    },
  );
}
