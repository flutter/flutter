// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/time.dart';

import '../src/common.dart';

void main() {
  group(SystemClock, () {
    test('can set a fixed time', () {
      final SystemClock clock = SystemClock.fixed(DateTime(1991, 8, 23));
      expect(clock.now(), DateTime(1991, 8, 23));
    });

    test('can find a time ago', () {
      final SystemClock clock = SystemClock.fixed(DateTime(1991, 8, 23));
      expect(clock.ago(const Duration(days: 10)), DateTime(1991, 8, 13));
    });
  });

  group('formatting', () {
    test('can round-trip formatted time', () {
      final DateTime time = DateTime(1991, 7, 31);
      expect(time.isUtc, isFalse);
      // formatDateTime() adds a timezone offset to DateTime.toString().
      final String formattedTime = formatDateTime(time);
      // If a date time string has a timezone offset, DateTime.tryParse()
      // converts the parsed time to UTC.
      final DateTime parsedTime = DateTime.tryParse(formattedTime);
      expect(parsedTime, isNotNull);
      expect(parsedTime.isUtc, isTrue);
      // Convert the parsed time (which should be utc) to the local timezone and
      // compare against the original time which is in the local timezone. They
      // should be the same.
      expect(parsedTime.toLocal(), equals(time));
    });
  });
}
