// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for what happens when DateTime instance creation does flaky things.

import 'package:intl/intl.dart';
import 'package:test/test.dart';

/// Holds methods we can tear off and use to modify the way DateFormat creates
/// DateTimes and introduce errors.
///
/// It only handles errors being off by integer numbers of hours, which are the
/// cases we've observed. See https://github.com/dart-lang/sdk/issues/15560 ,
/// but this also happens in JavaScript, and can produce other offsets than
/// UTC-current.
class DateCreationTweaks {
  /// When we want a flake that only happens once, use this variable.
  bool firstTime = true;

  /// The error
  final int hoursWrong;

  DateCreationTweaks(this.hoursWrong);

  /// Create a DateTime, but if [firstTime] is true add [hoursWrong] to the
  /// result, simulating a flaky error in the hours on DateTime creation.
  DateTime withFlakyErrors(int year, int month, int day, int hour24, int minute,
      int second, int fractionalSecond, bool utc) {
    DateTime date;
    if (utc) {
      date = DateTime.utc(
          year, month, day, hour24, minute, second, fractionalSecond);
    } else {
      date =
          DateTime(year, month, day, hour24, minute, second, fractionalSecond);
      if (firstTime) {
        date = date.add(Duration(hours: hoursWrong));
      }
    }
    firstTime = false;
    return date;
  }

  /// Create a DateTime, but always add [hoursWrong] to it, simulating a time
  /// zone transition issue.
  DateTime withTimeZoneTransition(int year, int month, int day, int hour24,
      int minute, int second, int fractionalSecond, bool utc) {
    DateTime date;
    if (utc) {
      date = DateTime.utc(
          year, month, day, hour24, minute, second, fractionalSecond);
    } else {
      date =
          DateTime(year, month, day, hour24, minute, second, fractionalSecond);
      date = date.add(Duration(hours: hoursWrong));
    }
    return date;
  }
}

void main() {
  group('Flaky hours in date construction of ', () {
    for (var i = -23; i <= 23; i++) {
      test('$i', () {
        var format = DateFormat('yyyy-MM-dd')
          ..dateTimeConstructor = DateCreationTweaks(i).withFlakyErrors;
        var date = '2037-12-30';
        var parsed = format.parseStrict(date);
        expect(parsed.hour, 0);
        expect(parsed.day, 30);
      });
    }
  });

  group('Time zone errors in date construction of ', () {
    for (var i = -1; i <= 1; i++) {
      test('$i', () {
        var format = DateFormat('yyyy-MM-dd')
          ..dateTimeConstructor = DateCreationTweaks(i).withTimeZoneTransition;
        var date = '2037-12-30';
        var parsed = format.parse(date);
        expect(parsed.day, 30);
        expect(parsed.hour, 0);
      });
    }
  });
}
