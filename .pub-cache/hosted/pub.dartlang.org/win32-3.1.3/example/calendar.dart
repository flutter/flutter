// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simple example of calling WinRT APIs

import 'package:win32/winrt.dart';

String calendarData(Calendar calendar) =>
    'Calendar: ${calendar.getCalendarSystem()}\n'
    'Name of Month: ${calendar.monthAsFullSoloString()}\n'
    'Day of Month: ${calendar.dayAsPaddedString(2)}\n'
    'Day of Week: ${calendar.dayOfWeekAsFullSoloString()}\n'
    'Year: ${calendar.yearAsString()}\n'
    'Time Zone: ${calendar.timeZoneAsFullString()}\n';

void main() {
  winrtInitialize();
  try {
    print('Windows Runtime demo. Calling Windows.Globalization.Calendar...\n');
    final calendar = Calendar();
    print(calendarData(calendar));

    final clonedCalendar = calendar.clone();
    final comparisonResult = clonedCalendar.compare(calendar);
    print('Comparison result of calendar and its clone: $comparisonResult');

    print('Languages: ${calendar.languages}\n');

    calendar.changeCalendarSystem('JapaneseCalendar');
    print(calendarData(calendar));

    calendar.changeCalendarSystem('HebrewCalendar');
    print(calendarData(calendar));

    final dateTime = calendar.getDateTime();
    print(dateTime);

    free(calendar.ptr);
    free(clonedCalendar.ptr);
  } finally {
    winrtUninitialize();
  }
}
