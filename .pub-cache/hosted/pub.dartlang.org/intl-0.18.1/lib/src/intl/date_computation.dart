// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Given a month and day number, return the day of the year, all one-based.
///
/// For example,
///  * January 2nd (1, 2) -> 2.
///  * February 5th (2, 5) -> 36.
///  * March 1st of a non-leap year (3, 1) -> 60.
int dayOfYear(int month, int day, bool leapYear) {
  if (month == 1) return day;
  if (month == 2) return day + 31;
  return ordinalDayFromMarchFirst(month, day) + 59 + (leapYear ? 1 : 0);
}

/// Return true if this is a leap year. Rely on [DateTime] to do the
/// underlying calculation, even though it doesn't expose the test to us.
bool isLeapYear(DateTime date) {
  var feb29 = DateTime(date.year, 2, 29);
  return feb29.month == 2;
}

/// Return the day of the year counting March 1st as 1, after which the
/// number of days per month is constant, so it's easier to calculate.
/// Formula from http://en.wikipedia.org/wiki/Ordinal_date
int ordinalDayFromMarchFirst(int month, int day) =>
    ((30.6 * month) - 91.4).floor() + day;
