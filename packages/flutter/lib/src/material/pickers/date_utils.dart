// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

// Common date utility functions used by the date picker implementation

// This is an internal implementation file. Even though there are public
// classes and functions defined here, they are only meant to be used by the
// date picker implementation and are not exported as part of the Material library.
// See pickers.dart for exactly what is considered part of the public API.

import '../material_localizations.dart';

import 'date_picker_common.dart';

/// Returns a [DateTime] with just the date of the original, but no time set.
DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// Returns a [DateTimeRange] with the dates of the original without any times set.
DateTimeRange datesOnly(DateTimeRange range) {
  return DateTimeRange(start: dateOnly(range.start), end: dateOnly(range.end));
}

/// Returns true if the two [DateTime] objects have the same day, month, and
/// year, or are both null.
bool isSameDay(DateTime dateA, DateTime dateB) {
  return
    dateA?.year == dateB?.year &&
    dateA?.month == dateB?.month &&
    dateA?.day == dateB?.day;
}

/// Returns true if the two [DateTime] objects have the same month, and
/// year, or are both null.
bool isSameMonth(DateTime dateA, DateTime dateB) {
  return
    dateA?.year == dateB?.year &&
    dateA?.month == dateB?.month;
}

/// Determines the number of months between two [DateTime] objects.
///
/// For example:
/// ```
/// DateTime date1 = DateTime(year: 2019, month: 6, day: 15);
/// DateTime date2 = DateTime(year: 2020, month: 1, day: 15);
/// int delta = monthDelta(date1, date2);
/// ```
///
/// The value for `delta` would be `7`.
int monthDelta(DateTime startDate, DateTime endDate) {
  return (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;
}

/// Returns a [DateTime] with the added number of months and truncates any day
/// and time information.
///
/// For example:
/// ```
/// DateTime date = DateTime(year: 2019, month: 1, day: 15);
/// DateTime futureDate = _addMonthsToMonthDate(date, 3);
/// ```
///
/// `date` would be January 15, 2019.
/// `futureDate` would be April 1, 2019 since it adds 3 months and truncates
/// any additional date information.
DateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
  return DateTime(monthDate.year, monthDate.month + monthsToAdd);
}

/// Returns a [DateTime] with the added number of days and no time set.
DateTime addDaysToDate(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days);
}

/// Computes the offset from the first day of the week that the first day of
/// the [month] falls on.
///
/// For example, September 1, 2017 falls on a Friday, which in the calendar
/// localized for United States English appears as:
///
/// ```
/// S M T W T F S
/// _ _ _ _ _ 1 2
/// ```
///
/// The offset for the first day of the months is the number of leading blanks
/// in the calendar, i.e. 5.
///
/// The same date localized for the Russian calendar has a different offset,
/// because the first day of week is Monday rather than Sunday:
///
/// ```
/// M T W T F S S
/// _ _ _ _ 1 2 3
/// ```
///
/// So the offset is 4, rather than 5.
///
/// This code consolidates the following:
///
/// - [DateTime.weekday] provides a 1-based index into days of week, with 1
///   falling on Monday.
/// - [MaterialLocalizations.firstDayOfWeekIndex] provides a 0-based index
///   into the [MaterialLocalizations.narrowWeekdays] list.
/// - [MaterialLocalizations.narrowWeekdays] list provides localized names of
///   days of week, always starting with Sunday and ending with Saturday.
int firstDayOffset(int year, int month, MaterialLocalizations localizations) {
  // 0-based day of week for the month and year, with 0 representing Monday.
  final int weekdayFromMonday = DateTime(year, month).weekday - 1;

  // 0-based start of week depending on the locale, with 0 representing Sunday.
  int firstDayOfWeekIndex = localizations.firstDayOfWeekIndex;

  // firstDayOfWeekIndex recomputed to be Monday-based, in order to compare with
  // weekdayFromMonday.
  firstDayOfWeekIndex = (firstDayOfWeekIndex - 1) % 7;

  // Number of days between the first day of week appearing on the calendar,
  // and the day corresponding to the first of the month.
  return (weekdayFromMonday - firstDayOfWeekIndex) % 7;
}

/// Returns the number of days in a month, according to the proleptic
/// Gregorian calendar.
///
/// This applies the leap year logic introduced by the Gregorian reforms of
/// 1582. It will not give valid results for dates prior to that time.
int getDaysInMonth(int year, int month) {
  if (month == DateTime.february) {
    final bool isLeapYear = (year % 4 == 0) && (year % 100 != 0) ||
        (year % 400 == 0);
    if (isLeapYear)
      return 29;
    return 28;
  }
  const List<int> daysInMonth = <int>[31, -1, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  return daysInMonth[month - 1];
}

/// Returns a locale-appropriate string to describe the start of a date range.
///
/// If `startDate` is null, then it defaults to 'Start Date', otherwise if it
/// is in the same year as the `endDate` then it will use the short month
/// day format (i.e. 'Jan 21'). Otherwise it will return the short date format
/// (i.e. 'Jan 21, 2020').
String formatRangeStartDate(MaterialLocalizations localizations, DateTime startDate, DateTime endDate) {
  return startDate == null
    ? localizations.dateRangeStartLabel
    : (endDate == null || startDate.year == endDate.year)
      ? localizations.formatShortMonthDay(startDate)
      : localizations.formatShortDate(startDate);
}

/// Returns an locale-appropriate string to describe the end of a date range.
///
/// If `endDate` is null, then it defaults to 'End Date', otherwise if it
/// is in the same year as the `startDate` and the `currentDate` then it will
/// just use the short month day format (i.e. 'Jan 21'), otherwise it will
/// include the year (i.e. 'Jan 21, 2020').
String formatRangeEndDate(MaterialLocalizations localizations, DateTime startDate, DateTime endDate, DateTime currentDate) {
  return endDate == null
    ? localizations.dateRangeEndLabel
    : (startDate != null && startDate.year == endDate.year && startDate.year == currentDate.year)
      ? localizations.formatShortMonthDay(endDate)
      : localizations.formatShortDate(endDate);
}
