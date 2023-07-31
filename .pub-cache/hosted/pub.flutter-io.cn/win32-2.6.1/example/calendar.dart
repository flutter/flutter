// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simple example of calling WinRT APIs

import 'package:win32/win32.dart';

String calendarData(ICalendar calendar) =>
    'Calendar: ${calendar.GetCalendarSystem()}\n'
    'Name of Month: ${calendar.MonthAsFullSoloString()}\n'
    'Day of Month: ${calendar.DayAsPaddedString(2)}\n'
    'Day of Week: ${calendar.DayOfWeekAsFullSoloString()}\n'
    'Year: ${calendar.YearAsString()}\n';

void main() {
  winrtInitialize();
  final japaneseCalendar = convertToHString('JapaneseCalendar');
  final hebrewCalendar = convertToHString('HebrewCalendar');

  try {
    print('Windows Runtime demo. Calling Windows.Globalization.Calendar...\n');
    final comObject =
        CreateObject('Windows.Globalization.Calendar', IID_ICalendar);
    final calendar = ICalendar(comObject);
    print(calendarData(calendar));

    final clonedCalendar = ICalendar(calendar.Clone());
    final comparisonResult = clonedCalendar.Compare(calendar.ptr);
    print('Comparison result of calendar and its clone: $comparisonResult');

    print('Languages: ${calendar.Languages}\n');

    calendar.ChangeCalendarSystem(japaneseCalendar);
    print(calendarData(calendar));

    calendar.ChangeCalendarSystem(hebrewCalendar);
    print(calendarData(calendar));

    final dateTime = calendar.GetDateTime();
    print(dateTime);

    free(comObject);
    free(clonedCalendar.ptr);
  } finally {
    WindowsDeleteString(japaneseCalendar);
    WindowsDeleteString(hebrewCalendar);
    winrtUninitialize();
  }
}
