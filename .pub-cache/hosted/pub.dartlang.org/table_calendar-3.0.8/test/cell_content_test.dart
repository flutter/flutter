// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/src/widgets/cell_content.dart';
import 'package:table_calendar/table_calendar.dart';

Widget setupTestWidget(
  DateTime cellDay, {
  CalendarBuilders calendarBuilders = const CalendarBuilders(),
  bool isDisabled = false,
  bool isToday = false,
  bool isWeekend = false,
  bool isOutside = false,
  bool isSelected = false,
  bool isRangeStart = false,
  bool isRangeEnd = false,
  bool isWithinRange = false,
  bool isHoliday = false,
  bool isTodayHighlighted = true,
}) {
  final calendarStyle = CalendarStyle();

  return Directionality(
    textDirection: TextDirection.ltr,
    child: CellContent(
      day: cellDay,
      focusedDay: cellDay,
      calendarBuilders: calendarBuilders,
      calendarStyle: calendarStyle,
      isDisabled: isDisabled,
      isToday: isToday,
      isWeekend: isWeekend,
      isOutside: isOutside,
      isSelected: isSelected,
      isRangeStart: isRangeStart,
      isRangeEnd: isRangeEnd,
      isWithinRange: isWithinRange,
      isHoliday: isHoliday,
      isTodayHighlighted: isTodayHighlighted,
    ),
  );
}

void main() {
  group('CalendarBuilders flag test:', () {
    testWidgets('selectedBuilder', (tester) async {
      DateTime? builderDay;

      final calendarBuilders = CalendarBuilders(
        selectedBuilder: (context, day, focusedDay) {
          builderDay = day;
          return Text('${day.day}');
        },
      );

      final cellDay = DateTime.utc(2021, 7, 15);
      expect(builderDay, isNull);

      await tester.pumpWidget(
        setupTestWidget(
          cellDay,
          calendarBuilders: calendarBuilders,
          isSelected: true,
        ),
      );

      expect(builderDay, cellDay);
    });

    testWidgets('rangeStartBuilder', (tester) async {
      DateTime? builderDay;

      final calendarBuilders = CalendarBuilders(
        rangeStartBuilder: (context, day, focusedDay) {
          builderDay = day;
          return Text('${day.day}');
        },
      );

      final cellDay = DateTime.utc(2021, 7, 15);
      expect(builderDay, isNull);

      await tester.pumpWidget(
        setupTestWidget(
          cellDay,
          calendarBuilders: calendarBuilders,
          isRangeStart: true,
        ),
      );

      expect(builderDay, cellDay);
    });

    testWidgets('rangeEndBuilder', (tester) async {
      DateTime? builderDay;

      final calendarBuilders = CalendarBuilders(
        rangeEndBuilder: (context, day, focusedDay) {
          builderDay = day;
          return Text('${day.day}');
        },
      );

      final cellDay = DateTime.utc(2021, 7, 15);
      expect(builderDay, isNull);

      await tester.pumpWidget(
        setupTestWidget(
          cellDay,
          calendarBuilders: calendarBuilders,
          isRangeEnd: true,
        ),
      );

      expect(builderDay, cellDay);
    });

    testWidgets('withinRangeBuilder', (tester) async {
      DateTime? builderDay;

      final calendarBuilders = CalendarBuilders(
        withinRangeBuilder: (context, day, focusedDay) {
          builderDay = day;
          return Text('${day.day}');
        },
      );

      final cellDay = DateTime.utc(2021, 7, 15);
      expect(builderDay, isNull);

      await tester.pumpWidget(
        setupTestWidget(
          cellDay,
          calendarBuilders: calendarBuilders,
          isWithinRange: true,
        ),
      );

      expect(builderDay, cellDay);
    });

    testWidgets('todayBuilder', (tester) async {
      DateTime? builderDay;

      final calendarBuilders = CalendarBuilders(
        todayBuilder: (context, day, focusedDay) {
          builderDay = day;
          return Text('${day.day}');
        },
      );

      final cellDay = DateTime.utc(2021, 7, 15);
      expect(builderDay, isNull);

      await tester.pumpWidget(
        setupTestWidget(
          cellDay,
          calendarBuilders: calendarBuilders,
          isToday: true,
        ),
      );

      expect(builderDay, cellDay);
    });

    testWidgets('holidayBuilder', (tester) async {
      DateTime? builderDay;

      final calendarBuilders = CalendarBuilders(
        holidayBuilder: (context, day, focusedDay) {
          builderDay = day;
          return Text('${day.day}');
        },
      );

      final cellDay = DateTime.utc(2021, 7, 15);
      expect(builderDay, isNull);

      await tester.pumpWidget(
        setupTestWidget(
          cellDay,
          calendarBuilders: calendarBuilders,
          isHoliday: true,
        ),
      );

      expect(builderDay, cellDay);
    });

    testWidgets('outsideBuilder', (tester) async {
      DateTime? builderDay;

      final calendarBuilders = CalendarBuilders(
        outsideBuilder: (context, day, focusedDay) {
          builderDay = day;
          return Text('${day.day}');
        },
      );

      final cellDay = DateTime.utc(2021, 7, 15);
      expect(builderDay, isNull);

      await tester.pumpWidget(
        setupTestWidget(
          cellDay,
          calendarBuilders: calendarBuilders,
          isOutside: true,
        ),
      );

      expect(builderDay, cellDay);
    });

    testWidgets(
      'defaultBuilder gets triggered when no other flags are active',
      (tester) async {
        DateTime? builderDay;

        final calendarBuilders = CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            builderDay = day;
            return Text('${day.day}');
          },
        );

        final cellDay = DateTime.utc(2021, 7, 15);
        expect(builderDay, isNull);

        await tester.pumpWidget(
          setupTestWidget(
            cellDay,
            calendarBuilders: calendarBuilders,
          ),
        );

        expect(builderDay, cellDay);
      },
    );

    testWidgets(
      'disabledBuilder has higher build order priority than selectedBuilder',
      (tester) async {
        DateTime? builderDay;
        String builderName = '';

        final calendarBuilders = CalendarBuilders(
          selectedBuilder: (context, day, focusedDay) {
            builderName = 'selectedBuilder';
            builderDay = day;
            return Text('${day.day}');
          },
          disabledBuilder: (context, day, focusedDay) {
            builderName = 'disabledBuilder';
            builderDay = day;
            return Text('${day.day}');
          },
        );

        final cellDay = DateTime.utc(2021, 7, 15);
        expect(builderDay, isNull);

        await tester.pumpWidget(
          setupTestWidget(
            cellDay,
            calendarBuilders: calendarBuilders,
            isDisabled: true,
            isSelected: true,
          ),
        );

        expect(builderDay, cellDay);
        expect(builderName, 'disabledBuilder');
      },
    );

    testWidgets(
      'prioritizedBuilder has the highest build order priority',
      (tester) async {
        DateTime? builderDay;
        String builderName = '';

        final calendarBuilders = CalendarBuilders(
          prioritizedBuilder: (context, day, focusedDay) {
            builderName = 'prioritizedBuilder';
            builderDay = day;
            return Text('${day.day}');
          },
          disabledBuilder: (context, day, focusedDay) {
            builderName = 'disabledBuilder';
            builderDay = day;
            return Text('${day.day}');
          },
        );

        final cellDay = DateTime.utc(2021, 7, 15);
        expect(builderDay, isNull);

        await tester.pumpWidget(
          setupTestWidget(
            cellDay,
            calendarBuilders: calendarBuilders,
            isDisabled: true,
          ),
        );

        expect(builderDay, cellDay);
        expect(builderName, 'prioritizedBuilder');
      },
    );
  });
}
