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

library quiver.time.clock_test;

import 'package:quiver/src/time/clock.dart';
import 'package:test/test.dart';

Clock from(int y, int m, int d) => Clock.fixed(DateTime(y, m, d));

void expectDate(DateTime date, int y, [int m = 1, int d = 1]) {
  expect(date, DateTime(y, m, d));
}

void main() {
  group('clock', () {
    late Clock subject;

    setUp(() {
      subject = Clock.fixed(DateTime(2013));
    });

    test('should return a non-null value from system clock', () {
      expect(const Clock().now(), isNotNull);
    });

    // This test may be flaky on certain systems. I ran it over 10 million
    // cycles on my machine without any failures, but that's no guarantee.
    test('should be close enough to system clock', () {
      // At 10ms the test doesn't seem to be flaky.
      var epsilon = 10;
      expect(
          DateTime.now().difference(const Clock().now()).inMilliseconds.abs(),
          lessThan(epsilon));
      expect(
          DateTime.now().difference(const Clock().now()).inMilliseconds.abs(),
          lessThan(epsilon));
    });

    test('should return time provided by custom TimeFunction', () {
      var time = DateTime(2013);
      var fixedClock = Clock(() => time);
      expect(fixedClock.now(), DateTime(2013));

      time = DateTime(2014);
      expect(fixedClock.now(), DateTime(2014));
    });

    test('should return fixed time', () {
      expect(Clock.fixed(DateTime(2013)).now(), DateTime(2013));
    });

    test('should return time Duration ago', () {
      expect(subject.agoBy(const Duration(days: 366)), DateTime(2012));
    });

    test('should return time Duration from now', () {
      expect(subject.fromNowBy(const Duration(days: 365)), DateTime(2014));
    });

    test('should return time parts ago', () {
      expect(
          subject.ago(
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
          subject.fromNow(
              days: 1,
              hours: 1,
              minutes: 1,
              seconds: 1,
              milliseconds: 1,
              microseconds: 1000),
          DateTime(2013, 1, 2, 1, 1, 1, 2));
    });

    test('should return time micros ago', () {
      expect(subject.microsAgo(1000), DateTime(2012, 12, 31, 23, 59, 59, 999));
    });

    test('should return time micros from now', () {
      expect(subject.microsFromNow(1000), DateTime(2013, 1, 1, 0, 0, 0, 1));
    });

    test('should return time millis ago', () {
      expect(subject.millisAgo(1000), DateTime(2012, 12, 31, 23, 59, 59, 000));
    });

    test('should return time millis from now', () {
      expect(subject.millisFromNow(3), DateTime(2013, 1, 1, 0, 0, 0, 3));
    });

    test('should return time seconds ago', () {
      expect(subject.secondsAgo(10), DateTime(2012, 12, 31, 23, 59, 50, 000));
    });

    test('should return time seconds from now', () {
      expect(subject.secondsFromNow(3), DateTime(2013, 1, 1, 0, 0, 3, 0));
    });

    test('should return time minutes ago', () {
      expect(subject.minutesAgo(10), DateTime(2012, 12, 31, 23, 50, 0, 000));
    });

    test('should return time minutes from now', () {
      expect(subject.minutesFromNow(3), DateTime(2013, 1, 1, 0, 3, 0, 0));
    });

    test('should return time hours ago', () {
      expect(subject.hoursAgo(10), DateTime(2012, 12, 31, 14, 0, 0, 000));
    });

    test('should return time hours from now', () {
      expect(subject.hoursFromNow(3), DateTime(2013, 1, 1, 3, 0, 0, 0));
    });

    test('should return time days ago', () {
      expectDate(subject.daysAgo(10), 2012, 12, 22);
    });

    test('should return time days from now', () {
      expectDate(subject.daysFromNow(3), 2013, 1, 4);
    });

    test('should return time months ago on the same date', () {
      expectDate(subject.monthsAgo(1), 2012, 12, 1);
      expectDate(subject.monthsAgo(2), 2012, 11, 1);
      expectDate(subject.monthsAgo(3), 2012, 10, 1);
      expectDate(subject.monthsAgo(4), 2012, 9, 1);
    });

    test('should return time months from now on the same date', () {
      expectDate(subject.monthsFromNow(1), 2013, 2, 1);
      expectDate(subject.monthsFromNow(2), 2013, 3, 1);
      expectDate(subject.monthsFromNow(3), 2013, 4, 1);
      expectDate(subject.monthsFromNow(4), 2013, 5, 1);
    });

    test('should go from 2013-05-31 to 2012-11-30', () {
      expectDate(from(2013, 5, 31).monthsAgo(6), 2012, 11, 30);
    });

    test('should go from 2013-03-31 to 2013-02-28 (common year)', () {
      expectDate(from(2013, 3, 31).monthsAgo(1), 2013, 2, 28);
    });

    test('should go from 2013-05-31 to 2013-02-28 (common year)', () {
      expectDate(from(2013, 5, 31).monthsAgo(3), 2013, 2, 28);
    });

    test('should go from 2004-03-31 to 2004-02-29 (leap year)', () {
      expectDate(from(2004, 3, 31).monthsAgo(1), 2004, 2, 29);
    });

    test('should go from 2013-03-31 to 2013-06-30', () {
      expectDate(from(2013, 3, 31).monthsFromNow(3), 2013, 6, 30);
    });

    test('should go from 2003-12-31 to 2004-02-29 (common to leap)', () {
      expectDate(from(2003, 12, 31).monthsFromNow(2), 2004, 2, 29);
    });

    test('should go from 2004-02-29 to 2003-02-28 by year', () {
      expectDate(from(2004, 2, 29).yearsAgo(1), 2003, 2, 28);
    });

    test('should go from 2004-02-29 to 2003-02-28 by month', () {
      expectDate(from(2004, 2, 29).monthsAgo(12), 2003, 2, 28);
    });

    test('should go from 2004-02-29 to 2005-02-28 by year', () {
      expectDate(from(2004, 2, 29).yearsFromNow(1), 2005, 2, 28);
    });

    test('should go from 2004-02-29 to 2005-02-28 by month', () {
      expectDate(from(2004, 2, 29).monthsFromNow(12), 2005, 2, 28);
    });

    test('should return time years ago on the same date', () {
      expectDate(subject.yearsAgo(1), 2012, 1, 1); // leap year
      expectDate(subject.yearsAgo(2), 2011, 1, 1);
      expectDate(subject.yearsAgo(3), 2010, 1, 1);
      expectDate(subject.yearsAgo(4), 2009, 1, 1);
      expectDate(subject.yearsAgo(5), 2008, 1, 1); // leap year
      expectDate(subject.yearsAgo(6), 2007, 1, 1);
      expectDate(subject.yearsAgo(30), 1983, 1, 1);
      expectDate(subject.yearsAgo(2013), 0, 1, 1);
    });

    test('should return time years from now on the same date', () {
      expectDate(subject.yearsFromNow(1), 2014, 1, 1);
      expectDate(subject.yearsFromNow(2), 2015, 1, 1);
      expectDate(subject.yearsFromNow(3), 2016, 1, 1);
      expectDate(subject.yearsFromNow(4), 2017, 1, 1);
      expectDate(subject.yearsFromNow(5), 2018, 1, 1);
      expectDate(subject.yearsFromNow(6), 2019, 1, 1);
      expectDate(subject.yearsFromNow(30), 2043, 1, 1);
      expectDate(subject.yearsFromNow(1000), 3013, 1, 1);
    });
  });
}
