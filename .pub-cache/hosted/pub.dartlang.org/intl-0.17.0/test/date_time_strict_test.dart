// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests for the strict option when parsing dates and times, which are
/// relatively locale-independent, depending only on the being a valid date
/// and consuming all the input data.
library date_time_strict_test;

import 'package:intl/intl.dart';
import 'package:test/test.dart';

void main() {
  test('All input consumed', () {
    var format = DateFormat.yMMMd();
    var date = DateTime(2014, 9, 3);
    var formatted = 'Sep 3, 2014';
    expect(format.format(date), formatted);
    var parsed = format.parseStrict(formatted);
    expect(parsed, date);

    void check(String s) {
      expect(() => format.parseStrict(s), throwsFormatException);
      expect(format.parse(s), date);
    }

    check('$formatted,');
    check('${formatted}abc');
    check('$formatted   ');
  });

  test('Invalid dates', () {
    var format = DateFormat.yMd();
    void check(s) => expect(() => format.parseStrict(s), throwsFormatException);
    check('0/3/2014');
    check('13/3/2014');
    check('9/0/2014');
    check('9/31/2014');
    check('09/31/2014');
    check('10/32/2014');
    check('2/29/2014');
    check('1/32/2014');
    expect(format.parseStrict('2/29/2016'), DateTime(2016, 2, 29));
  });

  test('Valid ordinal date is not rejected', () {
    var dayOfYearFormat = DateFormat('MM/DD/yyyy');
    expect(dayOfYearFormat.parseStrict('1/32/2014'), DateTime(2014, 2, 1));
  });

  test('Invalid times am/pm', () {
    var format = DateFormat.jms();
    void check(s) => expect(() => format.parseStrict(s), throwsFormatException);
    check('-1:15:00 AM');
    expect(format.parseStrict('0:15:00 AM'), DateTime(1970, 1, 1, 0, 15));
    check('24:00:00 PM');
    check('24:00:00 AM');
    check('25:00:00 PM');
    check('0:-1:00 AM');
    check('0:60:00 AM');
    expect(format.parseStrict('0:59:00 AM'), DateTime(1970, 1, 1, 0, 59));
    check('0:0:-1 AM');
    check('0:0:60 AM');
    check('2:0:60 PM');
    expect(format.parseStrict('2:0:59 PM'), DateTime(1970, 1, 1, 14, 0, 59));
  });

  test('Invalid times 24 hour', () {
    var format = DateFormat.Hms();
    void check(s) => expect(() => format.parseStrict(s), throwsFormatException);
    check('-1:15:00');
    expect(format.parseStrict('0:15:00'), DateTime(1970, 1, 1, 0, 15));
    check('24:00:00');
    check('24:00:00');
    check('25:00:00');
    check('0:-1:00');
    check('0:60:00');
    expect(format.parseStrict('0:59:00'), DateTime(1970, 1, 1, 0, 59));
    check('0:0:-1');
    check('0:0:60');
    check('14:0:60');
    expect(format.parseStrict('14:0:59'), DateTime(1970, 1, 1, 14, 0, 59));
  });
}
