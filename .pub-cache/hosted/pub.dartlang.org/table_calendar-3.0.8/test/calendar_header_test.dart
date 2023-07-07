// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;
import 'package:table_calendar/src/customization/header_style.dart';
import 'package:table_calendar/src/shared/utils.dart';
import 'package:table_calendar/src/widgets/calendar_header.dart';
import 'package:table_calendar/src/widgets/custom_icon_button.dart';
import 'package:table_calendar/src/widgets/format_button.dart';

import 'common.dart';

final focusedMonth = DateTime.utc(2021, 7, 15);

Widget setupTestWidget({
  HeaderStyle headerStyle = const HeaderStyle(),
  VoidCallback? onLeftChevronTap,
  VoidCallback? onRightChevronTap,
  VoidCallback? onHeaderTap,
  VoidCallback? onHeaderLongPress,
  Function(CalendarFormat)? onFormatButtonTap,
  Map<CalendarFormat, String> availableCalendarFormats = calendarFormatMap,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Material(
      child: CalendarHeader(
        focusedMonth: focusedMonth,
        calendarFormat: CalendarFormat.month,
        headerStyle: headerStyle,
        onLeftChevronTap: () => onLeftChevronTap?.call(),
        onRightChevronTap: () => onRightChevronTap?.call(),
        onHeaderTap: () => onHeaderTap?.call(),
        onHeaderLongPress: () => onHeaderLongPress?.call(),
        onFormatButtonTap: (format) => onFormatButtonTap?.call(format),
        availableCalendarFormats: availableCalendarFormats,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Displays corrent month and year for given focusedMonth',
    (tester) async {
      await tester.pumpWidget(setupTestWidget());

      final headerText = intl.DateFormat.yMMMM().format(focusedMonth);

      expect(find.byType(CalendarHeader), findsOneWidget);
      expect(find.text(headerText), findsOneWidget);
    },
  );
  testWidgets(
    'Ensure chevrons and FormatButton are visible by default, test onTap callbacks',
    (tester) async {
      bool leftChevronTapped = false;
      bool rightChevronTapped = false;
      bool headerTapped = false;
      bool headerLongPressed = false;
      bool formatButtonTapped = false;

      await tester.pumpWidget(
        setupTestWidget(
          onLeftChevronTap: () => leftChevronTapped = true,
          onRightChevronTap: () => rightChevronTapped = true,
          onHeaderTap: () => headerTapped = true,
          onHeaderLongPress: () => headerLongPressed = true,
          onFormatButtonTap: (_) => formatButtonTapped = true,
        ),
      );

      final leftChevron = find.widgetWithIcon(
        CustomIconButton,
        Icons.chevron_left,
      );

      final rightChevron = find.widgetWithIcon(
        CustomIconButton,
        Icons.chevron_right,
      );

      final header = find.byType(CalendarHeader);
      final formatButton = find.byType(FormatButton);

      expect(leftChevron, findsOneWidget);
      expect(rightChevron, findsOneWidget);
      expect(header, findsOneWidget);
      expect(formatButton, findsOneWidget);

      expect(leftChevronTapped, false);
      expect(rightChevronTapped, false);
      expect(headerTapped, false);
      expect(headerLongPressed, false);
      expect(formatButtonTapped, false);

      await tester.tap(leftChevron);
      await tester.pumpAndSettle();

      await tester.tap(rightChevron);
      await tester.pumpAndSettle();

      await tester.tap(header);
      await tester.pumpAndSettle();

      await tester.longPress(header);
      await tester.pumpAndSettle();

      await tester.tap(formatButton);
      await tester.pumpAndSettle();

      expect(leftChevronTapped, true);
      expect(rightChevronTapped, true);
      expect(headerTapped, true);
      expect(headerLongPressed, true);
      expect(formatButtonTapped, true);
    },
  );

  testWidgets(
    'When leftChevronVisible is false, do not show the left chevron',
    (tester) async {
      await tester.pumpWidget(
        setupTestWidget(
          headerStyle: HeaderStyle(
            leftChevronVisible: false,
          ),
        ),
      );

      final leftChevron = find.widgetWithIcon(
        CustomIconButton,
        Icons.chevron_left,
      );

      final rightChevron = find.widgetWithIcon(
        CustomIconButton,
        Icons.chevron_right,
      );

      expect(leftChevron, findsNothing);
      expect(rightChevron, findsOneWidget);
    },
  );

  testWidgets(
    'When rightChevronVisible is false, do not show the right chevron',
    (tester) async {
      await tester.pumpWidget(
        setupTestWidget(
          headerStyle: HeaderStyle(
            rightChevronVisible: false,
          ),
        ),
      );

      final leftChevron = find.widgetWithIcon(
        CustomIconButton,
        Icons.chevron_left,
      );

      final rightChevron = find.widgetWithIcon(
        CustomIconButton,
        Icons.chevron_right,
      );

      expect(leftChevron, findsOneWidget);
      expect(rightChevron, findsNothing);
    },
  );

  testWidgets(
    'When availableCalendarFormats has a single format, do not show the FormatButton',
    (tester) async {
      await tester.pumpWidget(
        setupTestWidget(
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        ),
      );

      final formatButton = find.byType(FormatButton);
      expect(formatButton, findsNothing);
    },
  );

  testWidgets(
    'When formatButtonVisible is false, do not show the FormatButton',
    (tester) async {
      await tester.pumpWidget(
        setupTestWidget(
          headerStyle: HeaderStyle(formatButtonVisible: false),
        ),
      );

      final formatButton = find.byType(FormatButton);
      expect(formatButton, findsNothing);
    },
  );
}
