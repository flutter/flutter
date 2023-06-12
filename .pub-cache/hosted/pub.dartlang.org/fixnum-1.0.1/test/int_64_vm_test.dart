// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('conversions', () {
    test('toInt', () {
      expect(Int64.parseInt('-10000000000000000').toInt(),
          same(-10000000000000000));
      expect(Int64.parseInt('-10000000000000001').toInt(),
          same(-10000000000000001));
      expect(Int64.parseInt('-10000000000000002').toInt(),
          same(-10000000000000002));
      expect(Int64.parseInt('-10000000000000003').toInt(),
          same(-10000000000000003));
      expect(Int64.parseInt('-10000000000000004').toInt(),
          same(-10000000000000004));
      expect(Int64.parseInt('-10000000000000005').toInt(),
          same(-10000000000000005));
      expect(Int64.parseInt('-10000000000000006').toInt(),
          same(-10000000000000006));
      expect(Int64.parseInt('-10000000000000007').toInt(),
          same(-10000000000000007));
      expect(Int64.parseInt('-10000000000000008').toInt(),
          same(-10000000000000008));
    });
  });

  test('', () {
    void check(int n) {
      // Sign change should commute with conversion.
      expect(-Int64(-n), Int64(n));
      expect(Int64(-n), -Int64(n));
    }

    check(10);
    check(1000000000000000000);
    check(9223372000000000000); // near Int64.MAX_VALUE, has exact double value
    check(9223372036854775807); // Int64.MAX_VALUE, rounds up to -MIN_VALUE
    check(-9223372036854775808); // Int64.MIN_VALUE
  });
}
