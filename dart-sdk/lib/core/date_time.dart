// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// An instant in time, such as July 20, 1969, 8:18pm GMT.
///
/// DateTimes can represent time values that are at a distance of at most
/// 100,000,000 days from epoch (1970-01-01 UTC): -271821-04-20 to 275760-09-13.
///
/// Create a `DateTime` object by using one of the constructors
/// or by parsing a correctly formatted string,
/// which complies with a subset of ISO 8601.
/// **Note:** hours are specified between 0 and 23,
/// as in a 24-hour clock.
///
/// For example:
/// ```dart
/// final now = DateTime.now();
/// final berlinWallFell = DateTime.utc(1989, 11, 9);
/// final moonLanding = DateTime.parse('1969-07-20 20:18:04Z'); // 8:18pm
/// ```
///
/// A `DateTime` object is anchored either in the UTC time zone
/// or in the local time zone of the current computer
/// when the object is created.
///
/// Once created, neither the value nor the time zone
/// of a `DateTime` object may be changed.
///
/// You can use properties to get
/// the individual units of a `DateTime` object.
/// ```
/// print(berlinWallFell.year); // 1989
/// print(berlinWallFell.month); // 11
/// print(berlinWallFell.day); // 9
/// print(moonLanding.hour); // 20
/// print(moonLanding.minute); // 18
/// ```
/// For convenience and readability,
/// the `DateTime` class provides a constant for each `day` and `month`
/// name - for example, [august] and [friday].
/// You can use these constants to improve code readability:
/// ```dart
/// final berlinWallFell = DateTime.utc(1989, DateTime.november, 9);
/// print(DateTime.november); // 11
/// assert(berlinWallFell.month == DateTime.november);
/// assert(berlinWallFell.weekday == DateTime.thursday);
/// ```
///
/// `Day` and `month` values begin at 1, and the week starts on `Monday`.
/// That is, the constants [january] and [monday] are both 1.
///
/// ## Working with UTC and local time
///
/// A `DateTime` object is in the local time zone
/// unless explicitly created in the UTC time zone.
/// Use [isUtc] to determine whether a `DateTime` object is based in UTC.
///
/// ```dart
/// final dDay = DateTime.utc(1944, 6, 6);
/// print(dDay.isUtc); // true
///
/// final dDayLocal = DateTime(1944, 6, 6);
/// print(dDayLocal.isUtc); // false
/// ```
/// Use the methods [toLocal] and [toUtc]
/// to get the equivalent date/time value specified in the other time zone.
/// ```
/// final localDay = dDay.toLocal(); // e.g. 1944-06-06 02:00:00.000
/// print(localDay.isUtc); // false
///
/// final utcFromLocal = localDay.toUtc(); // 1944-06-06 00:00:00.000Z
/// print(utcFromLocal.isUtc); // true
/// ```
/// Use [timeZoneName] to get an abbreviated name of the time zone
/// for the `DateTime` object.
/// ```
/// print(dDay.timeZoneName); // UTC
/// print(localDay.timeZoneName); // e.g. EET
/// ```
/// To find the difference
/// between UTC and the time zone of a `DateTime` object
/// call [timeZoneOffset].
/// ```
/// print(dDay.timeZoneOffset); // 0:00:00.000000
/// print(localDay.timeZoneOffset); // e.g. 2:00:00.000000
/// ```
///
/// ## Comparing DateTime objects
///
/// The `DateTime` class contains methods for comparing `DateTime`s
/// chronologically, such as [isAfter], [isBefore], and [isAtSameMomentAs].
/// ```
/// print(berlinWallFell.isAfter(moonLanding)); // true
/// print(berlinWallFell.isBefore(moonLanding)); // false
/// print(dDay.isAtSameMomentAs(localDay)); // true
/// ```
///
/// ## Using DateTime with Duration
///
/// Use the [add] and [subtract] methods with a [Duration] object
/// to create a `DateTime` object based on another.
/// For example, to find the point in time that is 36 hours after now,
/// you can write:
/// ```dart
/// final now = DateTime.now();
/// final later = now.add(const Duration(hours: 36));
/// ```
///
/// To find out how much time is between two `DateTime` objects use
/// [difference], which returns a [Duration] object:
/// ```
/// final difference = berlinWallFell.difference(moonLanding);
/// print(difference.inDays); // 7416
/// ```
///
/// The difference between two dates in different time zones
/// is just the number of nanoseconds between the two points in time.
/// It doesn't take calendar days into account.
/// That means that the difference between two midnights in local time may be
/// less than 24 hours times the number of days between them,
/// if there is a daylight saving change in between.
/// If the difference above is calculated using Australian local time, the
/// difference is 7415 days and 23 hours, which is only 7415 whole days as
/// reported by `inDays`.
///
/// ## Other resources
///
///  * See [Duration] to represent a span of time.
///  * See [Stopwatch] to measure timespans.
///  * The `DateTime` class does not provide internationalization.
///  To internationalize your code, use
///  the [intl](https://pub.dev/packages/intl) package.
class DateTime implements Comparable<DateTime> {
  // Weekday constants that are returned by [weekday] method:
  static const int monday = 1;
  static const int tuesday = 2;
  static const int wednesday = 3;
  static const int thursday = 4;
  static const int friday = 5;
  static const int saturday = 6;
  static const int sunday = 7;
  static const int daysPerWeek = 7;

  // Month constants that are returned by the [month] getter.
  static const int january = 1;
  static const int february = 2;
  static const int march = 3;
  static const int april = 4;
  static const int may = 5;
  static const int june = 6;
  static const int july = 7;
  static const int august = 8;
  static const int september = 9;
  static const int october = 10;
  static const int november = 11;
  static const int december = 12;
  static const int monthsPerYear = 12;

  /// True if this [DateTime] is set to UTC time.
  ///
  /// ```dart
  /// final dDay = DateTime.utc(1944, 6, 6);
  /// print(dDay.isUtc); // true
  ///
  /// final local = DateTime(1944, 6, 6);
  /// print(local.isUtc); // false
  /// ```
  final bool isUtc;

  /// Constructs a [DateTime] instance specified in the local time zone.
  ///
  /// For example,
  /// to create a `DateTime` object representing the 7th of September 2017,
  /// 5:30pm
  ///
  /// ```dart
  /// final dentistAppointment = DateTime(2017, 9, 7, 17, 30);
  /// ```
  DateTime(int year,
      [int month = 1,
      int day = 1,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0])
      : this._internal(year, month, day, hour, minute, second, millisecond,
            microsecond, false);

  /// Constructs a [DateTime] instance specified in the UTC time zone.
  ///
  /// ```dart
  /// final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
  /// ```
  ///
  /// When dealing with dates or historic events, preferably use UTC DateTimes,
  /// since they are unaffected by daylight-saving changes and are unaffected
  /// by the local timezone.
  DateTime.utc(int year,
      [int month = 1,
      int day = 1,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0])
      : this._internal(year, month, day, hour, minute, second, millisecond,
            microsecond, true);

  /// Constructs a [DateTime] instance with current date and time in the
  /// local time zone.
  ///
  /// ```dart
  /// final now = DateTime.now();
  /// ```
  DateTime.now() : this._now();

  /// Constructs a [DateTime] with the current UTC date and time.
  ///
  ///
  /// ```dart
  /// final mark = DateTime.timestamp();
  /// ```
  @Since("3.0")
  DateTime.timestamp() : this._nowUtc();

  external DateTime._nowUtc();

  /// Constructs a new [DateTime] instance based on [formattedString].
  ///
  /// Throws a [FormatException] if the input string cannot be parsed.
  ///
  /// The function parses a subset of ISO 8601,
  /// which includes the subset accepted by RFC 3339.
  ///
  /// The accepted inputs are currently:
  ///
  /// * A date: A signed four-to-six digit year, two digit month and
  ///   two digit day, optionally separated by `-` characters.
  ///   Examples: "19700101", "-0004-12-24", "81030-04-01".
  /// * An optional time part, separated from the date by either `T` or a space.
  ///   The time part is a two digit hour,
  ///   then optionally a two digit minutes value,
  ///   then optionally a two digit seconds value, and
  ///   then optionally a '.' or ',' followed by at least a one digit
  ///   second fraction.
  ///   The minutes and seconds may be separated from the previous parts by a
  ///   ':'.
  ///   Examples: "12", "12:30:24.124", "12:30:24,124", "123010.50".
  /// * An optional time-zone offset part,
  ///   possibly separated from the previous by a space.
  ///   The time zone is either 'z' or 'Z', or it is a signed two digit hour
  ///   part and an optional two digit minute part. The sign must be either
  ///   "+" or "-", and cannot be omitted.
  ///   The minutes may be separated from the hours by a ':'.
  ///   Examples: "Z", "-10", "+01:30", "+1130".
  ///
  /// This includes the output of both [toString] and [toIso8601String], which
  /// will be parsed back into a `DateTime` object with the same time as the
  /// original.
  ///
  /// The result is always in either local time or UTC.
  /// If a time zone offset other than UTC is specified,
  /// the time is converted to the equivalent UTC time.
  ///
  /// Examples of accepted strings:
  ///
  /// * `"2012-02-27"`
  /// * `"2012-02-27 13:27:00"`
  /// * `"2012-02-27 13:27:00.123456789z"`
  /// * `"2012-02-27 13:27:00,123456789z"`
  /// * `"20120227 13:27:00"`
  /// * `"20120227T132700"`
  /// * `"20120227"`
  /// * `"+20120227"`
  /// * `"2012-02-27T14Z"`
  /// * `"2012-02-27T14+00:00"`
  /// * `"-123450101 00:00:00 Z"`: in the year -12345.
  /// * `"2002-02-27T14:00:00-0500"`: Same as `"2002-02-27T19:00:00Z"`
  ///
  /// This method accepts out-of-range component values and interprets
  /// them as overflows into the next larger component.
  /// For example, "2020-01-42" will be parsed as 2020-02-11, because
  /// the last valid date in that month is 2020-01-31, so 42 days is
  /// interpreted as 31 days of that month plus 11 days into the next month.
  ///
  /// To detect and reject invalid component values, use
  /// [DateFormat.parseStrict](https://pub.dev/documentation/intl/latest/intl/DateFormat/parseStrict.html)
  /// from the [intl](https://pub.dev/packages/intl) package.
  static DateTime parse(String formattedString) {
    var re = _parseFormat;
    Match? match = re.firstMatch(formattedString);
    if (match != null) {
      int parseIntOrZero(String? matched) {
        if (matched == null) return 0;
        return int.parse(matched);
      }

      // Parses fractional second digits of '.(\d+)' into the combined
      // microseconds. We only use the first 6 digits because of DateTime
      // precision of 999 milliseconds and 999 microseconds.
      int parseMilliAndMicroseconds(String? matched) {
        if (matched == null) return 0;
        int length = matched.length;
        assert(length >= 1);
        int result = 0;
        for (int i = 0; i < 6; i++) {
          result *= 10;
          if (i < matched.length) {
            result += matched.codeUnitAt(i) ^ 0x30;
          }
        }
        return result;
      }

      int years = int.parse(match[1]!);
      int month = int.parse(match[2]!);
      int day = int.parse(match[3]!);
      int hour = parseIntOrZero(match[4]);
      int minute = parseIntOrZero(match[5]);
      int second = parseIntOrZero(match[6]);
      int milliAndMicroseconds = parseMilliAndMicroseconds(match[7]);
      int millisecond =
          milliAndMicroseconds ~/ Duration.microsecondsPerMillisecond;
      int microsecond = milliAndMicroseconds
          .remainder(Duration.microsecondsPerMillisecond) as int;
      bool isUtc = false;
      if (match[8] != null) {
        // timezone part
        isUtc = true;
        String? tzSign = match[9];
        if (tzSign != null) {
          // timezone other than 'Z' and 'z'.
          int sign = (tzSign == '-') ? -1 : 1;
          int hourDifference = int.parse(match[10]!);
          int minuteDifference = parseIntOrZero(match[11]);
          minuteDifference += 60 * hourDifference;
          minute -= sign * minuteDifference;
        }
      }
      DateTime? result = _finishParse(years, month, day, hour, minute, second,
          millisecond, microsecond, isUtc);
      if (result == null) {
        throw FormatException("Time out of range", formattedString);
      }
      return result;
    } else {
      throw FormatException("Invalid date format", formattedString);
    }
  }

  /// Constructs a new [DateTime] instance based on [formattedString].
  ///
  /// Works like [parse] except that this function returns `null`
  /// where [parse] would throw a [FormatException].
  static DateTime? tryParse(String formattedString) {
    // TODO: Optimize to avoid throwing.
    try {
      return parse(formattedString);
    } on FormatException {
      return null;
    }
  }

  static const int _maxMillisecondsSinceEpoch = 8640000000000000;
  static const int _maxMicrosecondsSinceEpoch =
      _maxMillisecondsSinceEpoch * Duration.microsecondsPerMillisecond;

  /// Constructs a new [DateTime] instance
  /// with the given [millisecondsSinceEpoch].
  ///
  /// If [isUtc] is false then the date is in the local time zone.
  ///
  /// The constructed [DateTime] represents
  /// 1970-01-01T00:00:00Z + [millisecondsSinceEpoch] ms in the given
  /// time zone (local or UTC).
  /// ```dart
  /// final newYearsDay =
  ///     DateTime.fromMillisecondsSinceEpoch(1641031200000, isUtc:true);
  /// print(newYearsDay); // 2022-01-01 10:00:00.000Z
  /// ```
  external DateTime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
      {bool isUtc = false});

  /// Constructs a new [DateTime] instance
  /// with the given [microsecondsSinceEpoch].
  ///
  /// If [isUtc] is false, then the date is in the local time zone.
  ///
  /// The constructed [DateTime] represents
  /// 1970-01-01T00:00:00Z + [microsecondsSinceEpoch] us in the given
  /// time zone (local or UTC).
  /// ```dart
  /// final newYearsEve =
  ///     DateTime.fromMicrosecondsSinceEpoch(1640979000000000, isUtc:true);
  /// print(newYearsEve); // 2021-12-31 19:30:00.000Z
  /// ```
  external DateTime.fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch,
      {bool isUtc = false});

  /// Throws an error if the millisecondsSinceEpoch and microsecond components
  /// are out of range.
  ///
  /// Returns the millisecondsSinceEpoch component.
  static int _validate(
      int millisecondsSinceEpoch, int microsecond, bool isUtc) {
    if (microsecond < 0 || microsecond > 999) {
      throw RangeError.range(microsecond, 0, 999, "microsecond");
    }
    if (millisecondsSinceEpoch < -_maxMillisecondsSinceEpoch ||
        millisecondsSinceEpoch > _maxMillisecondsSinceEpoch) {
      throw RangeError.range(
          millisecondsSinceEpoch,
          -_maxMillisecondsSinceEpoch,
          _maxMillisecondsSinceEpoch,
          "millisecondsSinceEpoch");
    }
    if (millisecondsSinceEpoch == _maxMillisecondsSinceEpoch &&
        microsecond != 0) {
      throw ArgumentError.value(microsecond, "microsecond",
          "Time including microseconds is outside valid range");
    }

    // For backwards compatibility with legacy mode.
    checkNotNullable(isUtc, "isUtc");

    return millisecondsSinceEpoch;
  }

  /// Whether [other] is a [DateTime] at the same moment and in the
  /// same time zone (UTC or local).
  ///
  /// ```dart
  /// final dDayUtc = DateTime.utc(1944, 6, 6);
  /// final dDayLocal = dDayUtc.toLocal();
  ///
  /// // These two dates are at the same moment, but are in different zones.
  /// assert(dDayUtc != dDayLocal);
  /// print(dDayUtc != dDayLocal); // true
  /// ```
  ///
  /// See [isAtSameMomentAs] for a comparison that compares moments in time
  /// independently of their zones.
  external bool operator ==(Object other);

  external int get hashCode;

  /// Whether this [DateTime] occurs before [other].
  ///
  /// The comparison is independent
  /// of whether the time is in UTC or in the local time zone.
  ///
  /// ```dart
  /// final now = DateTime.now();
  /// final earlier = now.subtract(const Duration(seconds: 5));
  /// print(earlier.isBefore(now)); // true
  /// print(!now.isBefore(now)); // true
  ///
  /// // This relation stays the same, even when changing timezones.
  /// print(earlier.isBefore(now.toUtc())); // true
  /// print(earlier.toUtc().isBefore(now)); // true
  ///
  /// print(!now.toUtc().isBefore(now)); // true
  /// print(!now.isBefore(now.toUtc())); // true
  /// ```
  external bool isBefore(DateTime other);

  /// Whether this [DateTime] occurs after [other].
  ///
  /// The comparison is independent
  /// of whether the time is in UTC or in the local time zone.
  ///
  /// ```dart
  /// final now = DateTime.now();
  /// final later = now.add(const Duration(seconds: 5));
  /// print(later.isAfter(now)); // true
  /// print(!now.isBefore(now)); // true
  ///
  /// // This relation stays the same, even when changing timezones.
  /// print(later.isAfter(now.toUtc())); // true
  /// print(later.toUtc().isAfter(now)); // true
  ///
  /// print(!now.toUtc().isAfter(now)); // true
  /// print(!now.isAfter(now.toUtc())); // true
  /// ```
  external bool isAfter(DateTime other);

  /// Whether this [DateTime] occurs at the same moment as [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in the local
  /// time zone.
  ///
  /// ```dart
  /// final now = DateTime.now();
  /// final later = now.add(const Duration(seconds: 5));
  /// print(!later.isAtSameMomentAs(now)); // true
  /// print(now.isAtSameMomentAs(now)); // true
  ///
  /// // This relation stays the same, even when changing timezones.
  /// print(!later.isAtSameMomentAs(now.toUtc())); // true
  /// print(!later.toUtc().isAtSameMomentAs(now)); // true
  ///
  /// print(now.toUtc().isAtSameMomentAs(now)); // true
  /// print(now.isAtSameMomentAs(now.toUtc())); // true
  /// ```
  external bool isAtSameMomentAs(DateTime other);

  /// Compares this DateTime object to [other],
  /// returning zero if the values are equal.
  ///
  /// A [compareTo] function returns:
  ///  * a negative value if this DateTime [isBefore] [other].
  ///  * `0` if this DateTime [isAtSameMomentAs] [other], and
  ///  * a positive value otherwise (when this DateTime [isAfter] [other]).
  ///
  /// ```dart
  /// final now = DateTime.now();
  /// final future = now.add(const Duration(days: 2));
  /// final past = now.subtract(const Duration(days: 2));
  /// final newDate = now.toUtc();
  ///
  /// print(now.compareTo(future)); // -1
  /// print(now.compareTo(past)); // 1
  /// print(now.compareTo(newDate)); // 0
  /// ```
  external int compareTo(DateTime other);

  /// Returns this DateTime value in the local time zone.
  ///
  /// Returns this [DateTime] if it is already in the local time zone.
  /// Otherwise this method is equivalent to:
  ///
  /// ```dart template:expression
  /// DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch,
  ///                                     isUtc: false)
  /// ```
  DateTime toLocal() {
    if (isUtc) {
      return _withUtc(isUtc: false);
    }
    return this;
  }

  /// Returns this DateTime value in the UTC time zone.
  ///
  /// Returns this [DateTime] if it is already in UTC.
  /// Otherwise this method is equivalent to:
  ///
  /// ```dart template:expression
  /// DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch,
  ///                                     isUtc: true)
  /// ```
  DateTime toUtc() {
    if (isUtc) return this;
    return _withUtc(isUtc: true);
  }

  external DateTime _withUtc({required bool isUtc});

  static String _fourDigits(int n) {
    int absN = n.abs();
    String sign = n < 0 ? "-" : "";
    if (absN >= 1000) return "$n";
    if (absN >= 100) return "${sign}0$absN";
    if (absN >= 10) return "${sign}00$absN";
    return "${sign}000$absN";
  }

  static String _sixDigits(int n) {
    assert(n < -9999 || n > 9999);
    int absN = n.abs();
    String sign = n < 0 ? "-" : "+";
    if (absN >= 100000) return "$sign$absN";
    return "${sign}0$absN";
  }

  static String _threeDigits(int n) {
    if (n >= 100) return "${n}";
    if (n >= 10) return "0${n}";
    return "00${n}";
  }

  static String _twoDigits(int n) {
    if (n >= 10) return "${n}";
    return "0${n}";
  }

  /// Returns a human-readable string for this instance.
  ///
  /// The returned string is constructed for the time zone of this instance.
  /// The `toString()` method provides a simply formatted string.
  /// It does not support internationalized strings.
  /// Use the [intl](https://pub.dev/packages/intl) package
  /// at the pub shared packages repo.
  ///
  /// The resulting string can be parsed back using [parse].
  String toString() {
    String y = _fourDigits(year);
    String m = _twoDigits(month);
    String d = _twoDigits(day);
    String h = _twoDigits(hour);
    String min = _twoDigits(minute);
    String sec = _twoDigits(second);
    String ms = _threeDigits(millisecond);
    String us = microsecond == 0 ? "" : _threeDigits(microsecond);
    if (isUtc) {
      return "$y-$m-$d $h:$min:$sec.$ms${us}Z";
    } else {
      return "$y-$m-$d $h:$min:$sec.$ms$us";
    }
  }

  /// Returns an ISO-8601 full-precision extended format representation.
  ///
  /// The format is `yyyy-MM-ddTHH:mm:ss.mmmuuuZ` for UTC time, and
  /// `yyyy-MM-ddTHH:mm:ss.mmmuuu` (no trailing "Z") for local/non-UTC time,
  /// where:
  ///
  /// * `yyyy` is a, possibly negative, four digit representation of the year,
  ///   if the year is in the range -9999 to 9999,
  ///   otherwise it is a signed six digit representation of the year.
  /// * `MM` is the month in the range 01 to 12,
  /// * `dd` is the day of the month in the range 01 to 31,
  /// * `HH` are hours in the range 00 to 23,
  /// * `mm` are minutes in the range 00 to 59,
  /// * `ss` are seconds in the range 00 to 59 (no leap seconds),
  /// * `mmm` are milliseconds in the range 000 to 999, and
  /// * `uuu` are microseconds in the range 001 to 999. If [microsecond] equals
  ///   0, then this part is omitted.
  ///
  /// The resulting string can be parsed back using [parse].
  /// ```dart
  /// final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
  /// final isoDate = moonLanding.toIso8601String();
  /// print(isoDate); // 1969-07-20T20:18:04.000Z
  /// ```
  String toIso8601String() {
    String y =
        (year >= -9999 && year <= 9999) ? _fourDigits(year) : _sixDigits(year);
    String m = _twoDigits(month);
    String d = _twoDigits(day);
    String h = _twoDigits(hour);
    String min = _twoDigits(minute);
    String sec = _twoDigits(second);
    String ms = _threeDigits(millisecond);
    String us = microsecond == 0 ? "" : _threeDigits(microsecond);
    if (isUtc) {
      return "$y-$m-${d}T$h:$min:$sec.$ms${us}Z";
    } else {
      return "$y-$m-${d}T$h:$min:$sec.$ms$us";
    }
  }

  /// Returns a new [DateTime] instance with [duration] added to this [DateTime].
  ///
  /// ```dart
  /// final today = DateTime.now();
  /// final fiftyDaysFromNow = today.add(const Duration(days: 50));
  /// ```
  ///
  /// Notice that the duration being added is actually 50 * 24 * 60 * 60
  /// seconds. If the resulting `DateTime` has a different daylight saving offset
  /// than `this`, then the result won't have the same time-of-day as `this`, and
  /// may not even hit the calendar date 50 days later.
  ///
  /// Be careful when working with dates in local time.
  external DateTime add(Duration duration);

  /// Returns a new [DateTime] instance with [duration] subtracted from this
  /// [DateTime].
  ///
  /// ```dart
  /// final today = DateTime.now();
  /// final fiftyDaysAgo = today.subtract(const Duration(days: 50));
  /// ```
  ///
  /// Notice that the duration being subtracted is actually 50 * 24 * 60 * 60
  /// seconds. If the resulting `DateTime` has a different daylight saving offset
  /// than `this`, then the result won't have the same time-of-day as `this`, and
  /// may not even hit the calendar date 50 days earlier.
  ///
  /// Be careful when working with dates in local time.
  external DateTime subtract(Duration duration);

  /// Returns a [Duration] with the difference when subtracting [other] from
  /// this [DateTime].
  ///
  /// The returned [Duration] will be negative if [other] occurs after this
  /// [DateTime].
  ///
  /// ```dart
  /// final berlinWallFell = DateTime.utc(1989, DateTime.november, 9);
  /// final dDay = DateTime.utc(1944, DateTime.june, 6);
  ///
  /// final difference = berlinWallFell.difference(dDay);
  /// print(difference.inDays); // 16592
  /// ```
  ///
  /// The difference is measured in seconds and fractions of seconds.
  /// The difference above counts the number of fractional seconds between
  /// midnight at the beginning of those dates.
  /// If the dates above had been in local time, not UTC, then the difference
  /// between two midnights may not be a multiple of 24 hours due to daylight
  /// saving differences.
  ///
  /// For example, in Australia, similar code using local time instead of UTC:
  ///
  /// ```dart
  /// final berlinWallFell = DateTime(1989, DateTime.november, 9);
  /// final dDay = DateTime(1944, DateTime.june, 6);
  /// final difference = berlinWallFell.difference(dDay);
  /// print(difference.inDays); // 16591
  /// assert(difference.inDays == 16592);
  /// ```
  /// will fail because the difference is actually 16591 days and 23 hours, and
  /// [Duration.inDays] only returns the number of whole days.
  external Duration difference(DateTime other);

  external DateTime._internal(int year, int month, int day, int hour,
      int minute, int second, int millisecond, int microsecond, bool isUtc);

  external DateTime._now();

  /// Returns the [DateTime] corresponding to the given components, or `null` if
  /// the values are out of range.
  external static DateTime? _finishParse(int year, int month, int day, int hour,
      int minute, int second, int millisecond, int microsecond, bool isUtc);

  /// The number of milliseconds since
  /// the "Unix epoch" 1970-01-01T00:00:00Z (UTC).
  ///
  /// This value is independent of the time zone.
  ///
  /// This value is at most
  /// 8,640,000,000,000,000ms (100,000,000 days) from the Unix epoch.
  /// In other words: `millisecondsSinceEpoch.abs() <= 8640000000000000`.
  external int get millisecondsSinceEpoch;

  /// The number of microseconds since
  /// the "Unix epoch" 1970-01-01T00:00:00Z (UTC).
  ///
  /// This value is independent of the time zone.
  ///
  /// This value is at most
  /// 8,640,000,000,000,000,000us (100,000,000 days) from the Unix epoch.
  /// In other words: `microsecondsSinceEpoch.abs() <= 8640000000000000000`.
  ///
  /// Note that this value does not always fit into 53 bits (the size of a IEEE
  /// double).  On the web JavaScript platforms, there may be a rounding error
  /// for DateTime values sufficiently far from the epoch. The year range close
  /// to the epoch to avoid rounding is approximately 1685..2254.
  external int get microsecondsSinceEpoch;

  /// The time zone name.
  ///
  /// This value is provided by the operating system and may be an
  /// abbreviation or a full name.
  ///
  /// In the browser or on Unix-like systems commonly returns abbreviations,
  /// such as "CET" or "CEST". On Windows returns the full name, for example
  /// "Pacific Standard Time".
  external String get timeZoneName;

  /// The time zone offset, which
  /// is the difference between local time and UTC.
  ///
  /// The offset is positive for time zones east of UTC.
  ///
  /// Note, that JavaScript, Python and C return the difference between UTC and
  /// local time. Java, C# and Ruby return the difference between local time and
  /// UTC.
  ///
  /// For example, using local time in San Francisco, United States:
  /// ```dart
  /// final dateUS = DateTime.parse('2021-11-01 20:18:04Z').toLocal();
  /// print(dateUS); // 2021-11-01 13:18:04.000
  /// print(dateUS.timeZoneName); // PDT ( Pacific Daylight Time )
  /// print(dateUS.timeZoneOffset.inHours); // -7
  /// print(dateUS.timeZoneOffset.inMinutes); // -420
  /// ```
  ///
  /// For example, using local time in Canberra, Australia:
  /// ```dart
  /// final dateAus = DateTime.parse('2021-11-01 20:18:04Z').toLocal();
  /// print(dateAus); // 2021-11-02 07:18:04.000
  /// print(dateAus.timeZoneName); // AEDT ( Australian Eastern Daylight Time )
  /// print(dateAus.timeZoneOffset.inHours); // 11
  /// print(dateAus.timeZoneOffset.inMinutes); // 660
  /// ```
  external Duration get timeZoneOffset;

  /// The year.
  ///
  /// ```dart
  /// final moonLanding = DateTime.parse('1969-07-20 20:18:04Z');
  /// print(moonLanding.year); // 1969
  /// ```
  external int get year;

  /// The month `[1..12]`.
  ///
  /// ```dart
  /// final moonLanding = DateTime.parse('1969-07-20 20:18:04Z');
  /// print(moonLanding.month); // 7
  /// assert(moonLanding.month == DateTime.july);
  /// ```
  external int get month;

  /// The day of the month `[1..31]`.
  ///
  /// ```dart
  /// final moonLanding = DateTime.parse('1969-07-20 20:18:04Z');
  /// print(moonLanding.day); // 20
  /// ```
  external int get day;

  /// The hour of the day, expressed as in a 24-hour clock `[0..23]`.
  ///
  /// ```dart
  /// final moonLanding = DateTime.parse('1969-07-20 20:18:04Z');
  /// print(moonLanding.hour); // 20
  /// ```
  external int get hour;

  /// The minute `[0...59]`.
  ///
  /// ```dart
  /// final moonLanding = DateTime.parse('1969-07-20 20:18:04Z');
  /// print(moonLanding.minute); // 18
  /// ```
  external int get minute;

  /// The second `[0...59]`.
  ///
  /// ```dart
  /// final moonLanding = DateTime.parse('1969-07-20 20:18:04Z');
  /// print(moonLanding.second); // 4
  /// ```
  external int get second;

  /// The millisecond `[0...999]`.
  ///
  /// ```dart
  /// final date = DateTime.parse('1970-01-01 05:01:01.234567Z');
  /// print(date.millisecond); // 234
  /// ```
  external int get millisecond;

  /// The microsecond `[0...999]`.
  ///
  /// ```dart
  /// final date = DateTime.parse('1970-01-01 05:01:01.234567Z');
  /// print(date.microsecond); // 567
  /// ```
  external int get microsecond;

  /// The day of the week [monday]..[sunday].
  ///
  /// In accordance with ISO 8601
  /// a week starts with Monday, which has the value 1.
  ///
  /// ```dart
  /// final moonLanding = DateTime.parse('1969-07-20 20:18:04Z');
  /// print(moonLanding.weekday); // 7
  /// assert(moonLanding.weekday == DateTime.sunday);
  /// ```
  external int get weekday;

  /*
   * date ::= yeardate time_opt timezone_opt
   * yeardate ::= year colon_opt month colon_opt day
   * year ::= sign_opt digit{4,6}
   * colon_opt :: <empty> | ':'
   * sign ::= '+' | '-'
   * sign_opt ::=  <empty> | sign
   * month ::= digit{2}
   * day ::= digit{2}
   * time_opt ::= <empty> | (' ' | 'T') hour minutes_opt
   * minutes_opt ::= <empty> | colon_opt digit{2} seconds_opt
   * seconds_opt ::= <empty> | colon_opt digit{2} millis_opt
   * micros_opt ::= <empty> | ('.' | ',') digit+
   * timezone_opt ::= <empty> | space_opt timezone
   * space_opt :: ' ' | <empty>
   * timezone ::= 'z' | 'Z' | sign digit{2} timezonemins_opt
   * timezonemins_opt ::= <empty> | colon_opt digit{2}
   */
  static final RegExp _parseFormat =
      RegExp(r'^([+-]?\d{4,6})-?(\d\d)-?(\d\d)' // Day part.
          r'(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(?:[.,](\d+))?)?)?' // Time part.
          r'( ?[zZ]| ?([-+])(\d\d)(?::?(\d\d))?)?)?$'); // Timezone part.
}

/// Adds [copyWith] method to [DateTime] objects.
@Since("2.19")
extension DateTimeCopyWith on DateTime {
  /// Creates a new [DateTime] from this one by updating individual properties.
  ///
  /// The [copyWith] method creates a new [DateTime] object with values
  /// for the properties [DateTime.year], [DateTime.hour], etc, provided by
  /// similarly named arguments, or using the existing value of the property
  /// if no argument, or `null`, is provided.
  ///
  /// Example:
  /// ```dart
  /// final now = DateTime.now();
  /// final sameTimeOnMoonLandingDay =
  ///     now.copyWith(year: 1969, month: 07, day: 20);
  /// ```
  ///
  /// Like for the [DateTime] and [DateTime.utc] constructors,
  /// which this operation uses to create the new value,
  /// property values are allowed to overflow or underflow the range
  /// of the property (like a [month] outside the 1 to 12 range),
  /// which can affect the more significant properties
  /// (for example, a month of 13 will result in the month of January
  /// of the next year.)
  ///
  /// Notice also that if the result is a local-time DateTime,
  /// seasonal time-zone adjustments (daylight saving) can cause some
  /// combinations of dates, hours and minutes to not exist, or to exist
  /// more than once.
  /// In the former case, a corresponding time in one of the two adjacent time
  /// zones is used instead. In the latter, one of the two options is chosen.
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
    bool? isUtc,
  }) {
    return ((isUtc ?? this.isUtc) ? DateTime.utc : DateTime.new)(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }
}
