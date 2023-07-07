// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:clock/clock.dart';

import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late Clock clock;
  setUp(() {
    clock = Clock.fixed(date(2013));
  });

  test('should return a non-null value from system clock', () {
    expect(const Clock().now(), isNotNull);
  });

  // This test may be flaky on certain systems. I ran it over 10 million
  // cycles on my machine without any failures, but that's no guarantee.
  test('should be close enough to system clock', () {
    // At 10ms the test doesn't seem to be flaky.
    var epsilon = 10;
    expect(DateTime.now().difference(const Clock().now()).inMilliseconds.abs(),
        lessThan(epsilon));
    expect(DateTime.now().difference(const Clock().now()).inMilliseconds.abs(),
        lessThan(epsilon));
  });

  test('should return time provided by a custom function', () {
    var time = date(2013);
    var fixedClock = Clock(() => time);
    expect(fixedClock.now(), date(2013));

    time = date(2014);
    expect(fixedClock.now(), date(2014));
  });

  test('should return fixed time', () {
    expect(Clock.fixed(date(2013)).now(), date(2013));
  });

  test('should return time Duration ago', () {
    expect(clock.agoBy(const Duration(days: 366)), date(2012));
  });

  test('should return time Duration from now', () {
    expect(clock.fromNowBy(const Duration(days: 365)), date(2014));
  });

  test('should return time parts ago', () {
    expect(
        clock.ago(
            days: 1,
            hours: 1,
            minutes: 1,
            seconds: 1,
            milliseconds: 1,
            microseconds: 1000),
        DateTime(2012, 12, 30, 22, 58, 58, 998));
  });

  test('should return time parts from now', () {
    expect(
        clock.fromNow(
            days: 1,
            hours: 1,
            minutes: 1,
            seconds: 1,
            milliseconds: 1,
            microseconds: 1000),
        DateTime(2013, 1, 2, 1, 1, 1, 2));
  });

  test('should return time micros ago', () {
    expect(clock.microsAgo(1000), DateTime(2012, 12, 31, 23, 59, 59, 999));
  });

  test('should return time micros from now', () {
    expect(clock.microsFromNow(1000), DateTime(2013, 1, 1, 0, 0, 0, 1));
  });

  test('should return time millis ago', () {
    expect(clock.millisAgo(1000), DateTime(2012, 12, 31, 23, 59, 59, 000));
  });

  test('should return time millis from now', () {
    expect(clock.millisFromNow(3), DateTime(2013, 1, 1, 0, 0, 0, 3));
  });

  test('should return time seconds ago', () {
    expect(clock.secondsAgo(10), DateTime(2012, 12, 31, 23, 59, 50, 000));
  });

  test('should return time seconds from now', () {
    expect(clock.secondsFromNow(3), DateTime(2013, 1, 1, 0, 0, 3, 0));
  });

  test('should return time minutes ago', () {
    expect(clock.minutesAgo(10), DateTime(2012, 12, 31, 23, 50, 0, 000));
  });

  test('should return time minutes from now', () {
    expect(clock.minutesFromNow(3), DateTime(2013, 1, 1, 0, 3, 0, 0));
  });

  test('should return time hours ago', () {
    expect(clock.hoursAgo(10), DateTime(2012, 12, 31, 14, 0, 0, 000));
  });

  test('should return time hours from now', () {
    expect(clock.hoursFromNow(3), DateTime(2013, 1, 1, 3, 0, 0, 0));
  });

  test('should return time days ago', () {
    expect(clock.daysAgo(10), date(2012, 12, 22));
  });

  test('should return time days from now', () {
    expect(clock.daysFromNow(3), date(2013, 1, 4));
  });

  test('should return time months ago on the same date', () {
    expect(clock.monthsAgo(1), date(2012, 12, 1));
    expect(clock.monthsAgo(2), date(2012, 11, 1));
    expect(clock.monthsAgo(3), date(2012, 10, 1));
    expect(clock.monthsAgo(4), date(2012, 9, 1));
  });

  test('should return time months from now on the same date', () {
    expect(clock.monthsFromNow(1), date(2013, 2, 1));
    expect(clock.monthsFromNow(2), date(2013, 3, 1));
    expect(clock.monthsFromNow(3), date(2013, 4, 1));
    expect(clock.monthsFromNow(4), date(2013, 5, 1));
  });

  test('should go from 2013-05-31 to 2012-11-30', () {
    expect(fixed(2013, 5, 31).monthsAgo(6), date(2012, 11, 30));
  });

  test('should go from 2013-03-31 to 2013-02-28 (common year)', () {
    expect(fixed(2013, 3, 31).monthsAgo(1), date(2013, 2, 28));
  });

  test('should go from 2013-05-31 to 2013-02-28 (common year)', () {
    expect(fixed(2013, 5, 31).monthsAgo(3), date(2013, 2, 28));
  });

  test('should go from 2004-03-31 to 2004-02-29 (leap year)', () {
    expect(fixed(2004, 3, 31).monthsAgo(1), date(2004, 2, 29));
  });

  test('should go from 2013-03-31 to 2013-06-30', () {
    expect(fixed(2013, 3, 31).monthsFromNow(3), date(2013, 6, 30));
  });

  test('should go from 2003-12-31 to 2004-02-29 (common to leap)', () {
    expect(fixed(2003, 12, 31).monthsFromNow(2), date(2004, 2, 29));
  });

  test('should go from 2004-02-29 to 2003-02-28 by year', () {
    expect(fixed(2004, 2, 29).yearsAgo(1), date(2003, 2, 28));
  });

  test('should go from 2004-02-29 to 2003-02-28 by month', () {
    expect(fixed(2004, 2, 29).monthsAgo(12), date(2003, 2, 28));
  });

  test('should go from 2004-02-29 to 2005-02-28 by year', () {
    expect(fixed(2004, 2, 29).yearsFromNow(1), date(2005, 2, 28));
  });

  test('should go from 2004-02-29 to 2005-02-28 by month', () {
    expect(fixed(2004, 2, 29).monthsFromNow(12), date(2005, 2, 28));
  });

  test('should return time years ago on the same date', () {
    expect(clock.yearsAgo(1), date(2012, 1, 1)); // leap year
    expect(clock.yearsAgo(2), date(2011, 1, 1));
    expect(clock.yearsAgo(3), date(2010, 1, 1));
    expect(clock.yearsAgo(4), date(2009, 1, 1));
    expect(clock.yearsAgo(5), date(2008, 1, 1)); // leap year
    expect(clock.yearsAgo(6), date(2007, 1, 1));
    expect(clock.yearsAgo(30), date(1983, 1, 1));
    expect(clock.yearsAgo(2013), date(0, 1, 1));
  });

  test('should return time years from now on the same date', () {
    expect(clock.yearsFromNow(1), date(2014, 1, 1));
    expect(clock.yearsFromNow(2), date(2015, 1, 1));
    expect(clock.yearsFromNow(3), date(2016, 1, 1));
    expect(clock.yearsFromNow(4), date(2017, 1, 1));
    expect(clock.yearsFromNow(5), date(2018, 1, 1));
    expect(clock.yearsFromNow(6), date(2019, 1, 1));
    expect(clock.yearsFromNow(30), date(2043, 1, 1));
    expect(clock.yearsFromNow(1000), date(3013, 1, 1));
  });
}
