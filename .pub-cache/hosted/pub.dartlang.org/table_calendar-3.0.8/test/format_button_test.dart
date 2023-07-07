// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/src/widgets/format_button.dart';
import 'package:table_calendar/table_calendar.dart';

import 'common.dart';

Widget setupTestWidget(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Material(child: child),
  );
}

void main() {
  group('onTap callback tests:', () {
    testWidgets(
      'Initial format month returns twoWeeks when tapped',
      (tester) async {
        final headerStyle = HeaderStyle();
        CalendarFormat? calendarFormat;

        await tester.pumpWidget(
          setupTestWidget(
            FormatButton(
              availableCalendarFormats: calendarFormatMap,
              calendarFormat: CalendarFormat.month,
              decoration: headerStyle.formatButtonDecoration,
              padding: headerStyle.formatButtonPadding,
              textStyle: headerStyle.formatButtonTextStyle,
              showsNextFormat: headerStyle.formatButtonShowsNext,
              onTap: (format) {
                calendarFormat = format;
              },
            ),
          ),
        );

        expect(find.byType(FormatButton), findsOneWidget);
        expect(calendarFormat, isNull);

        await tester.tap(find.byType(FormatButton));
        await tester.pumpAndSettle();
        expect(calendarFormat, CalendarFormat.twoWeeks);
      },
    );

    testWidgets(
      'Initial format twoWeeks returns week when tapped',
      (tester) async {
        final headerStyle = HeaderStyle();
        CalendarFormat? calendarFormat;

        await tester.pumpWidget(
          setupTestWidget(
            FormatButton(
              availableCalendarFormats: calendarFormatMap,
              calendarFormat: CalendarFormat.twoWeeks,
              decoration: headerStyle.formatButtonDecoration,
              padding: headerStyle.formatButtonPadding,
              textStyle: headerStyle.formatButtonTextStyle,
              showsNextFormat: headerStyle.formatButtonShowsNext,
              onTap: (format) {
                calendarFormat = format;
              },
            ),
          ),
        );

        expect(find.byType(FormatButton), findsOneWidget);
        expect(calendarFormat, isNull);

        await tester.tap(find.byType(FormatButton));
        await tester.pumpAndSettle();
        expect(calendarFormat, CalendarFormat.week);
      },
    );

    testWidgets(
      'Initial format week return month when tapped',
      (tester) async {
        final headerStyle = HeaderStyle();
        CalendarFormat? calendarFormat;

        await tester.pumpWidget(
          setupTestWidget(
            FormatButton(
              availableCalendarFormats: calendarFormatMap,
              calendarFormat: CalendarFormat.week,
              decoration: headerStyle.formatButtonDecoration,
              padding: headerStyle.formatButtonPadding,
              textStyle: headerStyle.formatButtonTextStyle,
              showsNextFormat: headerStyle.formatButtonShowsNext,
              onTap: (format) {
                calendarFormat = format;
              },
            ),
          ),
        );

        expect(find.byType(FormatButton), findsOneWidget);
        expect(calendarFormat, isNull);

        await tester.tap(find.byType(FormatButton));
        await tester.pumpAndSettle();
        expect(calendarFormat, CalendarFormat.month);
      },
    );
  });

  group('showsNextFormat tests:', () {
    testWidgets(
      'true - display next calendar format',
      (tester) async {
        final headerStyle = HeaderStyle(formatButtonShowsNext: true);

        final currentFormatIndex = 0;
        final currentFormat =
            calendarFormatMap.keys.elementAt(currentFormatIndex);
        final currentFormatText =
            calendarFormatMap.values.elementAt(currentFormatIndex);

        final nextFormatIndex = 1;
        final nextFormatText =
            calendarFormatMap.values.elementAt(nextFormatIndex);

        await tester.pumpWidget(
          setupTestWidget(
            FormatButton(
              availableCalendarFormats: calendarFormatMap,
              calendarFormat: currentFormat,
              decoration: headerStyle.formatButtonDecoration,
              padding: headerStyle.formatButtonPadding,
              textStyle: headerStyle.formatButtonTextStyle,
              showsNextFormat: headerStyle.formatButtonShowsNext,
              onTap: (format) {},
            ),
          ),
        );

        expect(find.byType(FormatButton), findsOneWidget);
        expect(currentFormatText, isNotNull);
        expect(find.text(currentFormatText), findsNothing);
        expect(nextFormatText, isNotNull);
        expect(find.text(nextFormatText), findsOneWidget);
      },
    );

    testWidgets(
      'false - display current calendar format',
      (tester) async {
        final headerStyle = HeaderStyle(formatButtonShowsNext: false);

        final currentFormatIndex = 0;
        final currentFormat =
            calendarFormatMap.keys.elementAt(currentFormatIndex);
        final currentFormatText =
            calendarFormatMap.values.elementAt(currentFormatIndex);

        await tester.pumpWidget(
          setupTestWidget(
            FormatButton(
              availableCalendarFormats: calendarFormatMap,
              calendarFormat: currentFormat,
              decoration: headerStyle.formatButtonDecoration,
              padding: headerStyle.formatButtonPadding,
              textStyle: headerStyle.formatButtonTextStyle,
              showsNextFormat: headerStyle.formatButtonShowsNext,
              onTap: (format) {},
            ),
          ),
        );

        expect(find.byType(FormatButton), findsOneWidget);
        expect(currentFormatText, isNotNull);
        expect(find.text(currentFormatText), findsOneWidget);
      },
    );
  });
}
