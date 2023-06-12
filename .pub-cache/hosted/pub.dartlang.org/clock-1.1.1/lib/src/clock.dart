// Copyright 2018 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import '../clock.dart';
import 'stopwatch.dart';
import 'utils.dart';

/// A provider for the "current time" and points relative to the current time.
///
/// This class is designed with testability in mind. The current point in time
/// (or [now()]) is defined by a function that returns a [DateTime]. By
/// supplying your own time function or using [new Clock.fixed], you can control
/// exactly what time a [Clock] returns and base your test expectations on that.
///
/// Most users should use the top-level [clock] field, which provides access to
/// a default implementation of [Clock] which can be overridden using
/// [withClock].
class Clock {
  /// The function that's called to determine this clock's notion of the current
  /// time.
  final DateTime Function() _time;

  /// Creates a clock based on the given [currentTime], or on the system clock
  /// by default.
  // ignore: deprecated_member_use_from_same_package
  const Clock([DateTime Function() currentTime = systemTime])
      : _time = currentTime;

  /// Creates [Clock] that always considers the current time to be [time].
  Clock.fixed(DateTime time) : _time = (() => time);

  /// Returns current time.
  DateTime now() => _time();

  /// Returns the point in time [Duration] amount of time ago.
  DateTime agoBy(Duration duration) => now().subtract(duration);

  /// Returns the point in time [Duration] amount of time from now.
  DateTime fromNowBy(Duration duration) => now().add(duration);

  /// Returns the point in time that's given amount of time ago.
  ///
  /// The amount of time is the sum of the individual parts.
  DateTime ago(
          {int days = 0,
          int hours = 0,
          int minutes = 0,
          int seconds = 0,
          int milliseconds = 0,
          int microseconds = 0}) =>
      agoBy(Duration(
          days: days,
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
          microseconds: microseconds));

  /// Returns the point in time that's given amount of time from now.
  ///
  /// The amount of time is the sum of the individual parts.
  DateTime fromNow(
          {int days = 0,
          int hours = 0,
          int minutes = 0,
          int seconds = 0,
          int milliseconds = 0,
          int microseconds = 0}) =>
      fromNowBy(Duration(
          days: days,
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
          microseconds: microseconds));

  /// Return the point in time [microseconds] ago.
  DateTime microsAgo(int microseconds) => ago(microseconds: microseconds);

  /// Return the point in time [microseconds] from now.
  DateTime microsFromNow(int microseconds) =>
      fromNow(microseconds: microseconds);

  /// Return the point in time [milliseconds] ago.
  DateTime millisAgo(int milliseconds) => ago(milliseconds: milliseconds);

  /// Return the point in time [milliseconds] from now.
  DateTime millisFromNow(int milliseconds) =>
      fromNow(milliseconds: milliseconds);

  /// Return the point in time [seconds] ago.
  DateTime secondsAgo(int seconds) => ago(seconds: seconds);

  /// Return the point in time [seconds] from now.
  DateTime secondsFromNow(int seconds) => fromNow(seconds: seconds);

  /// Return the point in time [minutes] ago.
  DateTime minutesAgo(int minutes) => ago(minutes: minutes);

  /// Return the point in time [minutes] from now.
  DateTime minutesFromNow(int minutes) => fromNow(minutes: minutes);

  /// Return the point in time [hours] ago.
  DateTime hoursAgo(int hours) => ago(hours: hours);

  /// Return the point in time [hours] from now.
  DateTime hoursFromNow(int hours) => fromNow(hours: hours);

  /// Return the point in time [days] ago.
  DateTime daysAgo(int days) => ago(days: days);

  /// Return the point in time [days] from now.
  DateTime daysFromNow(int days) => fromNow(days: days);

  /// Return the point in time [weeks] ago.
  DateTime weeksAgo(int weeks) => ago(days: 7 * weeks);

  /// Return the point in time [weeks] from now.
  DateTime weeksFromNow(int weeks) => fromNow(days: 7 * weeks);

  /// Return the point in time [months] ago on the same date.
  ///
  /// If the current day of the month isn't valid in the new month, the nearest
  /// valid day in the new month will be used.
  DateTime monthsAgo(int months) {
    var time = now();
    var month = (time.month - months - 1) % 12 + 1;
    var year = time.year - (months + 12 - time.month) ~/ 12;
    var day = clampDayOfMonth(year: year, month: month, day: time.day);
    return DateTime(year, month, day, time.hour, time.minute, time.second,
        time.millisecond);
  }

  /// Return the point in time [months] from now on the same date.
  ///
  /// If the current day of the month isn't valid in the new month, the nearest
  /// valid day in the new month will be used.
  DateTime monthsFromNow(int months) {
    var time = now();
    var month = (time.month + months - 1) % 12 + 1;
    var year = time.year + (months + time.month - 1) ~/ 12;
    var day = clampDayOfMonth(year: year, month: month, day: time.day);
    return DateTime(year, month, day, time.hour, time.minute, time.second,
        time.millisecond);
  }

  /// Return the point in time [years] ago on the same date.
  ///
  /// If the current day of the month isn't valid in the new year, the nearest
  /// valid day in the original month will be used.
  DateTime yearsAgo(int years) {
    var time = now();
    var year = time.year - years;
    var day = clampDayOfMonth(year: year, month: time.month, day: time.day);
    return DateTime(year, time.month, day, time.hour, time.minute, time.second,
        time.millisecond);
  }

  /// Return the point in time [years] from now on the same date.
  ///
  /// If the current day of the month isn't valid in the new year, the nearest
  /// valid day in the original month will be used.
  DateTime yearsFromNow(int years) => yearsAgo(-years);

  /// Returns a new stopwatch that uses the current time as reported by `this`.
  Stopwatch stopwatch() => ClockStopwatch(this);

  /// Returns a new stopwatch that uses the current time as reported by `this`.
  @Deprecated('Use stopwatch() instead.')
  Stopwatch getStopwatch() => stopwatch();
}
