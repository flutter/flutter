// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// A span of time, such as 27 days, 4 hours, 12 minutes, and 3 seconds.
///
/// A `Duration` represents a difference from one point in time to another. The
/// duration may be "negative" if the difference is from a later time to an
/// earlier.
///
/// Durations are context independent. For example, a duration of 2 days is
/// always 48 hours, even when it is added to a `DateTime` just when the
/// time zone is about to make a daylight-savings switch. (See [DateTime.add]).
///
/// Despite the same name, a `Duration` object does not implement "Durations"
/// as specified by ISO 8601. In particular, a duration object does not keep
/// track of the individually provided members (such as "days" or "hours"), but
/// only uses these arguments to compute the length of the corresponding time
/// interval.
///
/// To create a new `Duration` object, use this class's single constructor
/// giving the appropriate arguments:
/// ```dart
/// const fastestMarathon = Duration(hours: 2, minutes: 3, seconds: 2);
/// ```
/// The [Duration] represents a single number of microseconds,
/// which is the sum of all the individual arguments to the constructor.
///
/// Properties can access that single number in different ways.
/// For example the [inMinutes] gives the number of whole minutes
/// in the total duration, which includes the minutes that were provided
/// as "hours" to the constructor, and can be larger than 59.
///
/// ```dart
/// const fastestMarathon = Duration(hours: 2, minutes: 3, seconds: 2);
/// print(fastestMarathon.inDays); // 0
/// print(fastestMarathon.inHours); // 2
/// print(fastestMarathon.inMinutes); // 123
/// print(fastestMarathon.inSeconds); // 7382
/// print(fastestMarathon.inMilliseconds); // 7382000
/// ```
/// The duration can be negative, in which case
/// all the properties derived from the duration are also non-positive.
/// ```dart
/// const overDayAgo = Duration(days: -1, hours: -10);
/// print(overDayAgo.inDays); // -1
/// print(overDayAgo.inHours); // -34
/// print(overDayAgo.inMinutes); // -2040
/// ```
/// Use one of the properties, such as [inDays],
/// to retrieve the integer value of the `Duration` in the specified time unit.
/// Note that the returned value is rounded down.
/// For example,
/// ```dart
/// const aLongWeekend = Duration(hours: 88);
/// print(aLongWeekend.inDays); // 3
/// ```
/// This class provides a collection of arithmetic
/// and comparison operators,
/// plus a set of constants useful for converting time units.
/// ```dart
/// const firstHalf = Duration(minutes: 45); // 00:45:00.000000
/// const secondHalf = Duration(minutes: 45); // 00:45:00.000000
/// const overTime = Duration(minutes: 30); // 00:30:00.000000
/// final maxGameTime = firstHalf + secondHalf + overTime;
/// print(maxGameTime.inMinutes); // 120
///
/// // The duration of the firstHalf and secondHalf is the same, returns 0.
/// var result = firstHalf.compareTo(secondHalf);
/// print(result); // 0
///
/// // Duration of overTime is shorter than firstHalf, returns < 0.
/// result = overTime.compareTo(firstHalf);
/// print(result); // < 0
///
/// // Duration of secondHalf is longer than overTime, returns > 0.
/// result = secondHalf.compareTo(overTime);
/// print(result); // > 0
/// ```
///
/// **See also:**
/// * [DateTime] to represent a point in time.
/// * [Stopwatch] to measure time-spans.
class Duration implements Comparable<Duration> {
  /// The number of microseconds per millisecond.
  static const int microsecondsPerMillisecond = 1000;

  /// The number of milliseconds per second.
  static const int millisecondsPerSecond = 1000;

  /// The number of seconds per minute.
  ///
  /// Notice that some minutes of official clock time might
  /// differ in length because of leap seconds.
  /// The [Duration] and [DateTime] classes ignore leap seconds
  /// and consider all minutes to have 60 seconds.
  static const int secondsPerMinute = 60;

  /// The number of minutes per hour.
  static const int minutesPerHour = 60;

  /// The number of hours per day.
  ///
  /// Notice that some days may differ in length because
  /// of time zone changes due to daylight saving.
  /// The [Duration] class is time zone agnostic and
  /// considers all days to have 24 hours.
  static const int hoursPerDay = 24;

  /// The number of microseconds per second.
  static const int microsecondsPerSecond =
      microsecondsPerMillisecond * millisecondsPerSecond;

  /// The number of microseconds per minute.
  static const int microsecondsPerMinute =
      microsecondsPerSecond * secondsPerMinute;

  /// The number of microseconds per hour.
  static const int microsecondsPerHour = microsecondsPerMinute * minutesPerHour;

  /// The number of microseconds per day.
  static const int microsecondsPerDay = microsecondsPerHour * hoursPerDay;

  /// The number of milliseconds per minute.
  static const int millisecondsPerMinute =
      millisecondsPerSecond * secondsPerMinute;

  /// The number of milliseconds per hour.
  static const int millisecondsPerHour = millisecondsPerMinute * minutesPerHour;

  /// The number of milliseconds per day.
  static const int millisecondsPerDay = millisecondsPerHour * hoursPerDay;

  /// The number of seconds per hour.
  static const int secondsPerHour = secondsPerMinute * minutesPerHour;

  /// The number of seconds per day.
  static const int secondsPerDay = secondsPerHour * hoursPerDay;

  /// The number of minutes per day.
  static const int minutesPerDay = minutesPerHour * hoursPerDay;

  /// An empty duration, representing zero time.
  static const Duration zero = Duration(seconds: 0);

  /// The total microseconds of this [Duration] object.
  final int _duration;

  /// Creates a new [Duration] object whose value
  /// is the sum of all individual parts.
  ///
  /// Individual parts can be larger than the number of those
  /// parts in the next larger unit.
  /// For example, [hours] can be greater than 23.
  /// If this happens, the value overflows into the next larger
  /// unit, so 26 [hours] is the same as 2 [hours] and
  /// one more [days].
  /// Likewise, values can be negative, in which case they
  /// underflow and subtract from the next larger unit.
  ///
  /// If the total number of microseconds cannot be represented
  /// as an integer value, the number of microseconds might overflow
  /// and be truncated to a smaller number of bits,
  /// or it might lose precision.
  ///
  /// All arguments are 0 by default.
  /// ```dart
  /// const duration = Duration(days: 1, hours: 8, minutes: 56, seconds: 59,
  ///   milliseconds: 30, microseconds: 10);
  /// print(duration); // 32:56:59.030010
  /// ```
  const Duration(
      {int days = 0,
      int hours = 0,
      int minutes = 0,
      int seconds = 0,
      int milliseconds = 0,
      int microseconds = 0})
      : this._microseconds(microseconds +
            microsecondsPerMillisecond * milliseconds +
            microsecondsPerSecond * seconds +
            microsecondsPerMinute * minutes +
            microsecondsPerHour * hours +
            microsecondsPerDay * days);

  // Fast path internal direct constructor to avoids the optional arguments
  // and [_microseconds] recomputation.
  // The `+ 0` prevents -0.0 on the web, if the incoming duration happens to be -0.0.
  const Duration._microseconds(int duration) : _duration = duration + 0;

  /// Adds this Duration and [other] and
  /// returns the sum as a new Duration object.
  Duration operator +(Duration other) {
    return Duration._microseconds(_duration + other._duration);
  }

  /// Subtracts [other] from this Duration and
  /// returns the difference as a new Duration object.
  Duration operator -(Duration other) {
    return Duration._microseconds(_duration - other._duration);
  }

  /// Multiplies this Duration by the given [factor] and returns the result
  /// as a new Duration object.
  ///
  /// Note that when [factor] is a double, and the duration is greater than
  /// 53 bits, precision is lost because of double-precision arithmetic.
  Duration operator *(num factor) {
    return Duration._microseconds((_duration * factor).round());
  }

  /// Divides this Duration by the given [quotient] and returns the truncated
  /// result as a new Duration object.
  ///
  /// The [quotient] must not be `0`.
  Duration operator ~/(int quotient) {
    // By doing the check here instead of relying on "~/" below we get the
    // exception even with dart2js.
    if (quotient == 0) throw IntegerDivisionByZeroException();
    return Duration._microseconds(_duration ~/ quotient);
  }

  /// Whether this [Duration] is shorter than [other].
  bool operator <(Duration other) => this._duration < other._duration;

  /// Whether this [Duration] is longer than [other].
  bool operator >(Duration other) => this._duration > other._duration;

  /// Whether this [Duration] is shorter than or equal to [other].
  bool operator <=(Duration other) => this._duration <= other._duration;

  /// Whether this [Duration] is longer than or equal to [other].
  bool operator >=(Duration other) => this._duration >= other._duration;

  /// The number of entire days spanned by this [Duration].
  ///
  /// For example, a duration of four days and three hours
  /// has four entire days.
  /// ```dart
  /// const duration = Duration(days: 4, hours: 3);
  /// print(duration.inDays); // 4
  /// ```
  int get inDays => _duration ~/ Duration.microsecondsPerDay;

  /// The number of entire hours spanned by this [Duration].
  ///
  /// The returned value can be greater than 23.
  /// For example, a duration of four days and three hours
  /// has 99 entire hours.
  /// ```dart
  /// const duration = Duration(days: 4, hours: 3);
  /// print(duration.inHours); // 99
  /// ```
  int get inHours => _duration ~/ Duration.microsecondsPerHour;

  /// The number of whole minutes spanned by this [Duration].
  ///
  /// The returned value can be greater than 59.
  /// For example, a duration of three hours and 12 minutes
  /// has 192 minutes.
  /// ```dart
  /// const duration = Duration(hours: 3, minutes: 12);
  /// print(duration.inMinutes); // 192
  /// ```
  int get inMinutes => _duration ~/ Duration.microsecondsPerMinute;

  /// The number of whole seconds spanned by this [Duration].
  ///
  /// The returned value can be greater than 59.
  /// For example, a duration of three minutes and 12 seconds
  /// has 192 seconds.
  /// ```dart
  /// const duration = Duration(minutes: 3, seconds: 12);
  /// print(duration.inSeconds); // 192
  /// ```
  int get inSeconds => _duration ~/ Duration.microsecondsPerSecond;

  /// The number of whole milliseconds spanned by this [Duration].
  ///
  /// The returned value can be greater than 999.
  /// For example, a duration of three seconds and 125 milliseconds
  /// has 3125 milliseconds.
  /// ```dart
  /// const duration = Duration(seconds: 3, milliseconds: 125);
  /// print(duration.inMilliseconds); // 3125
  /// ```
  int get inMilliseconds => _duration ~/ Duration.microsecondsPerMillisecond;

  /// The number of whole microseconds spanned by this [Duration].
  ///
  /// The returned value can be greater than 999999.
  /// For example, a duration of three seconds, 125 milliseconds and
  /// 369 microseconds has 3125369 microseconds.
  /// ```dart
  /// const duration = Duration(seconds: 3, milliseconds: 125,
  ///     microseconds: 369);
  /// print(duration.inMicroseconds); // 3125369
  /// ```
  int get inMicroseconds => _duration;

  /// Whether this [Duration] has the same length as [other].
  ///
  /// Durations have the same length if they have the same number
  /// of microseconds, as reported by [inMicroseconds].
  bool operator ==(Object other) =>
      other is Duration && _duration == other.inMicroseconds;

  int get hashCode => _duration.hashCode;

  /// Compares this [Duration] to [other], returning zero if the values are equal.
  ///
  /// Returns a negative integer if this [Duration] is shorter than
  /// [other], or a positive integer if it is longer.
  ///
  /// A negative [Duration] is always considered shorter than a positive one.
  ///
  /// It is always the case that `duration1.compareTo(duration2) < 0` iff
  /// `(someDate + duration1).compareTo(someDate + duration2) < 0`.
  int compareTo(Duration other) => _duration.compareTo(other._duration);

  /// Returns a string representation of this [Duration].
  ///
  /// Returns a string with hours, minutes, seconds, and microseconds, in the
  /// following format: `H:MM:SS.mmmmmm`. For example,
  /// ```dart
  /// var d = const Duration(days: 1, hours: 1, minutes: 33, microseconds: 500);
  /// print(d.toString()); // 25:33:00.000500
  ///
  /// d = const Duration(hours: 1, minutes: 10, microseconds: 500);
  /// print(d.toString()); // 1:10:00.000500
  /// ```
  String toString() {
    var microseconds = inMicroseconds;
    var sign = "";
    var negative = microseconds < 0;

    var hours = microseconds ~/ microsecondsPerHour;
    microseconds = microseconds.remainder(microsecondsPerHour);

    // Correcting for being negative after first division, instead of before,
    // to avoid negating min-int, -(2^31-1), of a native int64.
    if (negative) {
      hours = 0 - hours; // Not using `-hours` to avoid creating -0.0 on web.
      microseconds = 0 - microseconds;
      sign = "-";
    }

    var minutes = microseconds ~/ microsecondsPerMinute;
    microseconds = microseconds.remainder(microsecondsPerMinute);

    var minutesPadding = minutes < 10 ? "0" : "";

    var seconds = microseconds ~/ microsecondsPerSecond;
    microseconds = microseconds.remainder(microsecondsPerSecond);

    var secondsPadding = seconds < 10 ? "0" : "";

    // Padding up to six digits for microseconds.
    var microsecondsText = microseconds.toString().padLeft(6, "0");

    return "$sign$hours:"
        "$minutesPadding$minutes:"
        "$secondsPadding$seconds."
        "$microsecondsText";
  }

  /// Whether this [Duration] is negative.
  ///
  /// A negative [Duration] represents the difference from a later time to an
  /// earlier time.
  bool get isNegative => _duration < 0;

  /// Creates a new [Duration] representing the absolute length of this
  /// [Duration].
  ///
  /// The returned [Duration] has the same length as this one, but is always
  /// positive where possible.
  Duration abs() => Duration._microseconds(_duration.abs());

  /// Creates a new [Duration] with the opposite direction of this [Duration].
  ///
  /// The returned [Duration] has the same length as this one, but will have the
  /// opposite sign (as reported by [isNegative]) as this one where possible.
  // Using subtraction helps dart2js avoid negative zeros.
  Duration operator -() => Duration._microseconds(0 - _duration);
}
