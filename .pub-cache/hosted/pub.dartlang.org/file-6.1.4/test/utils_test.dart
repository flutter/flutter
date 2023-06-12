// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('floorAndCeilProduceExactSecondDateTime', () {
    DateTime time = DateTime.fromMicrosecondsSinceEpoch(1001);
    DateTime lower = floor(time);
    DateTime upper = ceil(time);
    expect(lower.millisecond, 0);
    expect(upper.millisecond, 0);
    expect(lower.microsecond, 0);
    expect(upper.microsecond, 0);
  });

  test('floorAndCeilWorkWithNow', () {
    DateTime time = DateTime.now();
    int lower = time.difference(floor(time)).inMicroseconds;
    int upper = ceil(time).difference(time).inMicroseconds;
    expect(lower, lessThan(1000000));
    expect(upper, lessThanOrEqualTo(1000000));
  });

  test('floorAndCeilWorkWithExactSecondDateTime', () {
    DateTime time = DateTime.parse('1999-12-31 23:59:59');
    DateTime lower = floor(time);
    DateTime upper = ceil(time);
    expect(lower, time);
    expect(upper, time);
  });

  test('floorAndCeilWorkWithInexactSecondDateTime', () {
    DateTime time = DateTime.parse('1999-12-31 23:59:59.500');
    DateTime lower = floor(time);
    DateTime upper = ceil(time);
    Duration difference = upper.difference(lower);
    expect(difference.inMicroseconds, 1000000);
  });
}
