// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Forked from https://github.com/dart-lang/sdk/blob/master/samples-dev/swarm/swarm_ui_lib/util/DateUtils.dart
class DateUtils {

  static const WEEKDAYS = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
                                 'Friday', 'Saturday', 'Sunday'];

  static const YESTERDAY = 'Yesterday';

  static const MS_IN_WEEK = DateTime.DAYS_PER_WEEK * Duration.MILLISECONDS_PER_DAY;

  // TODO(jmesserly): locale specific date format
  static String _twoDigits(int n) {
    if (n >= 10)
      return '$n';
    return '0$n';
  }

  /// Formats a time in H:MM A format
  static String toHourMinutesString(Duration duration) {
    assert(duration.inDays == 0);
    int hours = duration.inHours;
    String a;
    if (hours >= 12) {
      a = 'pm';
      if (hours != 12)
        hours -= 12;
    } else {
      a = 'am';
      if (hours == 0)
        hours += 12;
    }
    String twoDigits(int n) {
      if (n >= 10)
        return '$n';
      return '0$n';
    }
    String mm = twoDigits(duration.inMinutes.remainder(Duration.MINUTES_PER_HOUR));
    return '$hours:$mm $a';
  }

  /// A date/time formatter that takes into account the current date/time:
  ///  - if it's from today, just show the time
  ///  - if it's from yesterday, just show 'Yesterday'
  ///  - if it's from the same week, just show the weekday
  ///  - otherwise, show just the date
  static String toRecentTimeString(DateTime then) {
    bool datesAreEqual(DateTime d1, DateTime d2) {
      return (d1.year == d2.year) &&
             (d1.month == d2.month) &&
             (d1.day == d2.day);
    }

    final now = new DateTime.now();
    if (datesAreEqual(then, now)) {
      return toHourMinutesString(new Duration(
        days: 0,
        hours: then.hour,
        minutes: then.minute,
        seconds: then.second,
        milliseconds: then.millisecond)
      );
    }

    final today = new DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
    Duration delta = today.difference(then);
    if (delta.inMilliseconds < Duration.MILLISECONDS_PER_DAY) {
      return YESTERDAY;
    } else if (delta.inMilliseconds < MS_IN_WEEK) {
      return WEEKDAYS[then.weekday];
    } else {
      String twoDigitMonth = _twoDigits(then.month);
      String twoDigitDay = _twoDigits(then.day);
      return '${then.year}-$twoDigitMonth-$twoDigitDay';
    }
  }

  static String toDateString(DateTime then) {
    // TODO(jmesserly): locale specific date format
    String twoDigitMonth = _twoDigits(then.month);
    String twoDigitDay = _twoDigits(then.day);
    return '${then.year}-$twoDigitMonth-$twoDigitDay';
  }
}
