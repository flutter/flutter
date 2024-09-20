// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show checkNotNullable, patch, unsafeCast;

// VM implementation of DateTime.
@patch
class DateTime {
  // Natives.
  // The natives have been moved up here to work around Issue 10401.
  @pragma("vm:external-name", "DateTime_currentTimeMicros")
  external static int _getCurrentMicros();

  @pragma("vm:external-name", "DateTime_timeZoneName")
  external static String _timeZoneNameForClampedSeconds(int secondsSinceEpoch);

  @pragma("vm:external-name", "DateTime_timeZoneOffsetInSeconds")
  external static int _timeZoneOffsetInSecondsForClampedSeconds(
      int secondsSinceEpoch);

  static const _MICROSECOND_INDEX = 0;
  static const _MILLISECOND_INDEX = 1;
  static const _SECOND_INDEX = 2;
  static const _MINUTE_INDEX = 3;
  static const _HOUR_INDEX = 4;
  static const _DAY_INDEX = 5;
  static const _WEEKDAY_INDEX = 6;
  static const _MONTH_INDEX = 7;
  static const _YEAR_INDEX = 8;

  /// The value of this DateTime, equal to [microsecondsSinceEpoch].
  final int _value;

  List<int>? __parts;

  /// Constructor for pre-validated components.
  DateTime._(this._value, {required this.isUtc});

  /// Constructs a new [DateTime] instance with the given value.
  ///
  /// If [isUtc] is false, then the date is in the local time zone.
  DateTime._withValue(this._value, {required this.isUtc}) {
    _validate(millisecondsSinceEpoch, microsecond, isUtc);
  }

  @patch
  DateTime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
      {bool isUtc = false})
      : this._withValue(
            _validateMilliseconds(millisecondsSinceEpoch) *
                Duration.microsecondsPerMillisecond,
            isUtc: isUtc);

  @patch
  DateTime.fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch,
      {bool isUtc = false})
      : this._withValue(microsecondsSinceEpoch, isUtc: isUtc);

  static const _sentinel = -_maxMicrosecondsSinceEpoch - 1;
  static const _sentinelConstraint = _sentinel < -_maxMicrosecondsSinceEpoch ||
      _sentinel > _maxMicrosecondsSinceEpoch;
  static const _sentinelAssertion = 1 ~/ (_sentinelConstraint ? 1 : 0);

  @patch
  DateTime._internal(int year, int month, int day, int hour, int minute,
      int second, int millisecond, int microsecond, bool isUtc)
      : this.isUtc = checkNotNullable(isUtc, "isUtc"),
        this._value = _brokenDownDateToValue(year, month, day, hour, minute,
                second, millisecond, microsecond, isUtc) ??
            _sentinel {
    if (_value == _sentinel) {
      throw ArgumentError('($year, $month, $day,'
          ' $hour, $minute, $second, $millisecond, $microsecond)');
    }
  }

  static int _validateMilliseconds(int millisecondsSinceEpoch) =>
      RangeError.checkValueInInterval(
          millisecondsSinceEpoch,
          -_maxMillisecondsSinceEpoch,
          _maxMillisecondsSinceEpoch,
          "millisecondsSinceEpoch");

  @patch
  DateTime._now()
      : isUtc = false,
        _value = _getCurrentMicros();

  @patch
  DateTime._nowUtc()
      : isUtc = true,
        _value = _getCurrentMicros();

  @patch
  DateTime _withUtc({required bool isUtc}) {
    return DateTime._(_value, isUtc: isUtc);
  }

  @patch
  String get timeZoneName {
    if (isUtc) return "UTC";
    return _timeZoneName(microsecondsSinceEpoch);
  }

  @patch
  Duration get timeZoneOffset {
    if (isUtc) return Duration();
    int offsetInSeconds = _timeZoneOffsetInSeconds(microsecondsSinceEpoch);
    return Duration(seconds: offsetInSeconds);
  }

  @patch
  bool operator ==(dynamic other) =>
      other is DateTime &&
      _value == other.microsecondsSinceEpoch &&
      isUtc == other.isUtc;

  @patch
  int get hashCode => (_value ^ (_value >> 30)) & 0x3FFFFFFF;

  @patch
  bool isBefore(DateTime other) => _value < other.microsecondsSinceEpoch;

  @patch
  bool isAfter(DateTime other) => _value > other.microsecondsSinceEpoch;

  @patch
  bool isAtSameMomentAs(DateTime other) =>
      _value == other.microsecondsSinceEpoch;

  @patch
  int compareTo(DateTime other) =>
      _value.compareTo(other.microsecondsSinceEpoch);

  /// The first list contains the days until each month in non-leap years. The
  /// second list contains the days in leap years.
  static const List<List<int>> _DAYS_UNTIL_MONTH = [
    [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334],
    [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
  ];

  static List<int> _computeUpperPart(int localMicros) {
    const int DAYS_IN_4_YEARS = 4 * 365 + 1;
    const int DAYS_IN_100_YEARS = 25 * DAYS_IN_4_YEARS - 1;
    const int DAYS_IN_400_YEARS = 4 * DAYS_IN_100_YEARS + 1;
    const int DAYS_1970_TO_2000 = 30 * 365 + 7;
    const int DAYS_OFFSET =
        1000 * DAYS_IN_400_YEARS + 5 * DAYS_IN_400_YEARS - DAYS_1970_TO_2000;
    const int YEARS_OFFSET = 400000;

    int resultYear = 0;
    int resultMonth = 0;
    int resultDay = 0;

    // Always round down.
    final int daysSince1970 =
        _flooredDivision(localMicros, Duration.microsecondsPerDay);
    int days = daysSince1970;
    days += DAYS_OFFSET;
    resultYear = 400 * (days ~/ DAYS_IN_400_YEARS) - YEARS_OFFSET;
    days = unsafeCast<int>(days.remainder(DAYS_IN_400_YEARS));
    days--;
    int yd1 = days ~/ DAYS_IN_100_YEARS;
    days = unsafeCast<int>(days.remainder(DAYS_IN_100_YEARS));
    resultYear += 100 * yd1;
    days++;
    int yd2 = days ~/ DAYS_IN_4_YEARS;
    days = unsafeCast<int>(days.remainder(DAYS_IN_4_YEARS));
    resultYear += 4 * yd2;
    days--;
    int yd3 = days ~/ 365;
    days = unsafeCast<int>(days.remainder(365));
    resultYear += yd3;

    bool isLeap = (yd1 == 0 || yd2 != 0) && yd3 == 0;
    if (isLeap) days++;

    List<int> daysUntilMonth = _DAYS_UNTIL_MONTH[isLeap ? 1 : 0];
    for (resultMonth = 12;
        daysUntilMonth[resultMonth - 1] > days;
        resultMonth--) {
      // Do nothing.
    }
    resultDay = days - daysUntilMonth[resultMonth - 1] + 1;

    int resultMicrosecond = localMicros % Duration.microsecondsPerMillisecond;
    int resultMillisecond =
        _flooredDivision(localMicros, Duration.microsecondsPerMillisecond) %
            Duration.millisecondsPerSecond;
    int resultSecond =
        _flooredDivision(localMicros, Duration.microsecondsPerSecond) %
            Duration.secondsPerMinute;

    int resultMinute =
        _flooredDivision(localMicros, Duration.microsecondsPerMinute);
    resultMinute %= Duration.minutesPerHour;

    int resultHour =
        _flooredDivision(localMicros, Duration.microsecondsPerHour);
    resultHour %= Duration.hoursPerDay;

    // In accordance with ISO 8601 a week
    // starts with Monday. Monday has the value 1 up to Sunday with 7.
    // 1970-1-1 was a Thursday.
    int resultWeekday = ((daysSince1970 + DateTime.thursday - DateTime.monday) %
            DateTime.daysPerWeek) +
        DateTime.monday;

    List<int> list = List<int>.filled(_YEAR_INDEX + 1, 0);
    list[_MICROSECOND_INDEX] = resultMicrosecond;
    list[_MILLISECOND_INDEX] = resultMillisecond;
    list[_SECOND_INDEX] = resultSecond;
    list[_MINUTE_INDEX] = resultMinute;
    list[_HOUR_INDEX] = resultHour;
    list[_DAY_INDEX] = resultDay;
    list[_WEEKDAY_INDEX] = resultWeekday;
    list[_MONTH_INDEX] = resultMonth;
    list[_YEAR_INDEX] = resultYear;
    return list;
  }

  List<int> get _parts {
    return __parts ??= _computeUpperPart(_localDateInUtcMicros);
  }

  @patch
  DateTime add(Duration duration) {
    return DateTime._withValue(_value + duration.inMicroseconds, isUtc: isUtc);
  }

  @patch
  DateTime subtract(Duration duration) {
    return DateTime._withValue(_value - duration.inMicroseconds, isUtc: isUtc);
  }

  @patch
  Duration difference(DateTime other) {
    return Duration(microseconds: _value - other.microsecondsSinceEpoch);
  }

  @patch
  int get millisecondsSinceEpoch =>
      _flooredDivision(_value, Duration.microsecondsPerMillisecond);

  @patch
  int get microsecondsSinceEpoch => _value;

  @patch
  int get microsecond => _parts[_MICROSECOND_INDEX];

  @patch
  int get millisecond => _parts[_MILLISECOND_INDEX];

  @patch
  int get second => _parts[_SECOND_INDEX];

  @patch
  int get minute => _parts[_MINUTE_INDEX];

  @patch
  int get hour => _parts[_HOUR_INDEX];

  @patch
  int get day => _parts[_DAY_INDEX];

  @patch
  int get weekday => _parts[_WEEKDAY_INDEX];

  @patch
  int get month => _parts[_MONTH_INDEX];

  @patch
  int get year => _parts[_YEAR_INDEX];

  /// Returns the amount of microseconds in UTC that represent the same values
  /// as this [DateTime].
  ///
  /// Say `t` is the result of this function, then
  /// * `this.year == new DateTime.fromMicrosecondsSinceEpoch(t, true).year`,
  /// * `this.month == new DateTime.fromMicrosecondsSinceEpoch(t, true).month`,
  /// * `this.day == new DateTime.fromMicrosecondsSinceEpoch(t, true).day`,
  /// * `this.hour == new DateTime.fromMicrosecondsSinceEpoch(t, true).hour`,
  /// * ...
  ///
  /// Daylight savings is computed as if the date was computed in [1970..2037].
  /// If this [DateTime] lies outside this range then a year with similar
  /// properties (leap year, weekdays) is used instead.
  int get _localDateInUtcMicros {
    int micros = _value;
    if (isUtc) return micros;
    int offset =
        _timeZoneOffsetInSeconds(micros) * Duration.microsecondsPerSecond;
    return micros + offset;
  }

  static int _flooredDivision(int a, int b) {
    return (a - (a < 0 ? b - 1 : 0)) ~/ b;
  }

  // Returns the days since 1970 for the start of the given [year].
  // [year] may be before epoch.
  static int _dayFromYear(int year) {
    return 365 * (year - 1970) +
        _flooredDivision(year - 1969, 4) -
        _flooredDivision(year - 1901, 100) +
        _flooredDivision(year - 1601, 400);
  }

  static bool _isLeapYear(int y) {
    // (y % 16 == 0) matches multiples of 400, and is faster than % 400.
    return (y % 4 == 0) && ((y % 16 == 0) || (y % 100 != 0));
  }

  /// Converts the given broken down date to microseconds.
  static int? _brokenDownDateToValue(int year, int month, int day, int hour,
      int minute, int second, int millisecond, int microsecond, bool isUtc) {
    // Simplify calculations by working with zero-based month.
    --month;
    // Deal with under and overflow.
    if (month >= 12) {
      year += month ~/ 12;
      month = month % 12;
    } else if (month < 0) {
      int realMonth = month % 12;
      year += (month - realMonth) ~/ 12;
      month = realMonth;
    }

    // First compute the seconds in UTC, independent of the [isUtc] flag. If
    // necessary we will add the time-zone offset later on.
    int days = day - 1;
    days += _DAYS_UNTIL_MONTH[_isLeapYear(year) ? 1 : 0][month];
    days += _dayFromYear(year);
    int microsecondsSinceEpoch = days * Duration.microsecondsPerDay +
        hour * Duration.microsecondsPerHour +
        minute * Duration.microsecondsPerMinute +
        second * Duration.microsecondsPerSecond +
        millisecond * Duration.microsecondsPerMillisecond +
        microsecond;

    if (!isUtc) {
      // Since [_timeZoneOffsetInSeconds] will crash if the input is far out of
      // the valid range we do a preliminary test that weeds out values that can
      // not become valid even with timezone adjustments.
      // The timezone adjustment is always less than a day, so adding a security
      // margin of one day should be enough.
      if (microsecondsSinceEpoch.abs() >
          _maxMillisecondsSinceEpoch * Duration.microsecondsPerMillisecond +
              Duration.microsecondsPerDay) {
        return null;
      }

      microsecondsSinceEpoch -= _toLocalTimeOffset(microsecondsSinceEpoch);
    }
    if (microsecondsSinceEpoch.abs() >
        _maxMillisecondsSinceEpoch * Duration.microsecondsPerMillisecond) {
      return null;
    }
    return microsecondsSinceEpoch;
  }

  @patch
  static DateTime? _finishParse(int year, int month, int day, int hour,
      int minute, int second, int millisecond, int microsecond, bool isUtc) {
    final value = _brokenDownDateToValue(year, month, day, hour, minute, second,
        millisecond, microsecond, isUtc);
    if (value == null) return null;
    return DateTime._withValue(value, isUtc: isUtc);
  }

  static int _weekDay(y) {
    // 1/1/1970 was a Thursday.
    return (_dayFromYear(y) + 4) % 7;
  }

  /// Returns a year in the range 2008-2035 matching
  /// * leap year, and
  /// * week day of first day.
  ///
  /// Leap seconds are ignored.
  /// Adapted from V8's date implementation. See ECMA 262 - 15.9.1.9.
  static int _equivalentYear(int year) {
    // Returns year y so that _weekDay(y) == _weekDay(year).
    // _weekDay returns the week day (in range 0 - 6).
    // 1/1/1956 was a Sunday (i.e. weekday 0). 1956 was a leap-year.
    // 1/1/1967 was a Sunday (i.e. weekday 0).
    // Without leap years a subsequent year has a week day + 1 (for example
    // 1/1/1968 was a Monday). With leap-years it jumps over one week day
    // (e.g. 1/1/1957 was a Tuesday).
    // After 12 years the weekdays have advanced by 12 days + 3 leap days =
    // 15 days. 15 % 7 = 1. So after 12 years the week day has always
    // (now independently of leap-years) advanced by one.
    // weekDay * 12 gives thus a year starting with the wanted weekDay.
    int recentYear = (_isLeapYear(year) ? 1956 : 1967) + (_weekDay(year) * 12);
    // Close to the year 2008 the calendar cycles every 4 * 7 years (4 for the
    // leap years, 7 for the weekdays).
    // Find the year in the range 2008..2037 that is equivalent mod 28.
    return 2008 + (recentYear - 2008) % 28;
  }

  /// Returns the UTC year for the corresponding [secondsSinceEpoch].
  /// It is relatively fast for values in the range 0 to year 2098.
  ///
  /// Code is adapted from V8.
  static int _yearsFromSecondsSinceEpoch(int secondsSinceEpoch) {
    const int DAYS_IN_4_YEARS = 4 * 365 + 1;
    const int DAYS_IN_100_YEARS = 25 * DAYS_IN_4_YEARS - 1;
    const int DAYS_YEAR_2098 = DAYS_IN_100_YEARS + 6 * DAYS_IN_4_YEARS;

    int days = secondsSinceEpoch ~/ Duration.secondsPerDay;
    if (days > 0 && days < DAYS_YEAR_2098) {
      // According to V8 this fast case works for dates from 1970 to 2099.
      return 1970 + (4 * days + 2) ~/ DAYS_IN_4_YEARS;
    }
    int micros = secondsSinceEpoch * Duration.microsecondsPerSecond;
    return _computeUpperPart(micros)[_YEAR_INDEX];
  }

  /// Returns a date in seconds that is equivalent to the given
  /// date in microseconds [microsecondsSinceEpoch]. An equivalent
  /// date has the same fields (`month`, `day`, etc.) as the given
  /// date, but the `year` is in the range [1901..2038].
  ///
  /// * The time since the beginning of the year is the same.
  /// * If the given date is in a leap year then the returned
  ///   seconds are in a leap year, too.
  /// * The week day of given date is the same as the one for the
  ///   returned date.
  static int _equivalentSeconds(int microsecondsSinceEpoch) {
    const int CUT_OFF_SECONDS = 0x7FFFFFFF;

    int secondsSinceEpoch = _flooredDivision(
        microsecondsSinceEpoch, Duration.microsecondsPerSecond);

    if (secondsSinceEpoch.abs() > CUT_OFF_SECONDS) {
      int year = _yearsFromSecondsSinceEpoch(secondsSinceEpoch);
      int days = _dayFromYear(year);
      int equivalentYear = _equivalentYear(year);
      int equivalentDays = _dayFromYear(equivalentYear);
      int diffDays = equivalentDays - days;
      secondsSinceEpoch += diffDays * Duration.secondsPerDay;
    }
    return secondsSinceEpoch;
  }

  static int _timeZoneOffsetInSeconds(int microsecondsSinceEpoch) {
    int equivalentSeconds = _equivalentSeconds(microsecondsSinceEpoch);
    return _timeZoneOffsetInSecondsForClampedSeconds(equivalentSeconds);
  }

  static String _timeZoneName(int microsecondsSinceEpoch) {
    int equivalentSeconds = _equivalentSeconds(microsecondsSinceEpoch);
    return _timeZoneNameForClampedSeconds(equivalentSeconds);
  }

  /// Finds the local time corresponding to a UTC date and time.
  ///
  /// The [microsecondsSinceEpoch] represents a particular
  /// calendar date and clock time in UTC.
  /// This methods returns a (usually different) point in time
  /// where the local time had the same calendar date and clock
  /// time (if such a time exists, otherwise it finds the "best"
  /// substitute).
  ///
  /// A valid result is a point in time `microsecondsSinceEpoch - offset`
  /// where the local time zone offset is `+offset`.
  ///
  /// In some cases there are two valid results, due to a time zone
  /// change setting the clock back (for example exiting from daylight
  /// saving time). In that case, we return the *earliest* valid result.
  ///
  /// In some cases there are no valid results, due to a time zone
  /// change setting the clock forward (for example entering daylight
  /// saving time). In that case, we return the time which would have
  /// been correct in the earlier time zone (so asking for 2:30 AM
  /// when clocks move directly from 2:00 to 3:00 will give the
  /// time that *would have been* 2:30 in the earlier time zone,
  /// which is now 3:30 in the local time zone).
  ///
  /// Returns the point in time as a number of microseconds since epoch.
  static int _toLocalTimeOffset(int microsecondsSinceEpoch) {
    // Argument is the UTC time corresponding to the desired
    // calendar date/wall time.
    // We now need to find an UTC time where the difference
    // from `microsecondsSinceEpoch` is the same as the
    // local time offset at that time. That is, we want to
    // find `adjustment` in microseconds such that:
    //
    //  _timeZoneOffsetInSeconds(microsecondsSinceEpoch - offset)
    //      * Duration.microsecondsPerSecond == offset
    //
    // Such an offset might not exist, if that wall time
    // is skipped when a time zone change moves the clock forwards.
    // In that case we pick a time after the switch which would be
    // correct in the previous time zone.
    // Also, there might be more than one solution if a time zone
    // change moves the clock backwards and the same wall clock
    // time occurs twice in the same day.
    // In that case we pick the one in the time zone prior to
    // the switch.

    // Start with the time zone at the current microseconds since
    // epoch. It's within one day of the real time we're looking for.

    int offset = _timeZoneOffsetInSeconds(microsecondsSinceEpoch) *
        Duration.microsecondsPerSecond;

    // If offset is 0 (we're right around the UTC+0, and)
    // we have found one solution.
    if (offset != 0) {
      // If not, try to find an actual solution in the time zone
      // we just discovered.
      int offset2 = _timeZoneOffsetInSeconds(microsecondsSinceEpoch - offset) *
          Duration.microsecondsPerSecond;
      if (offset2 != offset) {
        // Also not a solution. We have found a second time zone
        // within the same day. We assume that's all there are.
        // Try again with the new time zone.
        int offset3 =
            _timeZoneOffsetInSeconds(microsecondsSinceEpoch - offset2) *
                Duration.microsecondsPerSecond;
        // Either offset3 is a solution (equal to offset2),
        // or we have found two different time zones and no solution.
        // In the latter case we choose the lower offset (latter time).
        return (offset2 <= offset3 ? offset2 : offset3);
      }
      // We have found one solution and one time zone.
      offset = offset2;
    }
    // Try to see if there is an earlier time zone which also
    // has a solution.
    // Pretends time zone changes are always at most two hours.
    // (Double daylight saving happened, fx, in part of Canada in 1988).
    int offset4 = _timeZoneOffsetInSeconds(microsecondsSinceEpoch -
            offset -
            2 * Duration.microsecondsPerHour) *
        Duration.microsecondsPerSecond;
    if (offset4 > offset) {
      // The time zone at the earlier time had a greater
      // offset, so it's possible that the desired wall clock
      // occurs in that time zone too.
      if (offset4 == offset + 2 * Duration.microsecondsPerHour) {
        // A second and earlier solution, so use that.
        return offset4;
      }
      // The time zone differs one hour earlier, but not by one
      // hour, so check again in that time zone.
      int offset5 = _timeZoneOffsetInSeconds(microsecondsSinceEpoch - offset4) *
          Duration.microsecondsPerSecond;
      if (offset5 == offset4) {
        // Found a second solution earlier than the first solution, so use that.
        return offset4;
      }
    }
    // Did not find a solution in the earlier time
    // zone, so just use the original result.
    return offset;
  }
}
