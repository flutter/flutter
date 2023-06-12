// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simple example of calling WinRT APIs

import 'package:win32/win32.dart';

String calendarData(Calendar calendar) =>
    'Calendar: ${calendar.GetCalendarSystem()}\n'
    'Name of Month: ${calendar.MonthAsFullSoloString()}\n'
    'Day of Month: ${calendar.DayAsPaddedString(2)}\n'
    'Day of Week: ${calendar.DayOfWeekAsFullSoloString()}\n'
    'Year: ${calendar.YearAsString()}\n'
    'Time Zone: ${calendar.TimeZoneAsFullString()}\n';

void main() {
  winrtInitialize();
  try {
    print('Windows Runtime demo. Calling Windows.Globalization.Calendar...\n');
    final calendar = Calendar();
    print(calendarData(calendar));

    final clonedCalendar = Calendar.fromPointer(calendar.Clone());
    final comparisonResult = clonedCalendar.Compare(calendar.ptr);
    print('Comparison result of calendar and its clone: $comparisonResult');

    print('Languages: ${calendar.Languages}\n');

    calendar.ChangeCalendarSystem('JapaneseCalendar');
    print(calendarData(calendar));

    calendar.ChangeCalendarSystem('HebrewCalendar');
    print(calendarData(calendar));

    final dateTime = calendar.GetDateTime();
    print(dateTime);

    free(calendar.ptr);
    free(clonedCalendar.ptr);
  } finally {
    winrtUninitialize();
  }
}
