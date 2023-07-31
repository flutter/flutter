/// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
/// for details. All rights reserved. Use of this source code is governed by a
/// BSD-style license that can be found in the LICENSE file.

import 'package:intl/intl.dart';
import 'package:test/test.dart';

void main() {
  test('numberOfIntegerDigits calculation', () {
    int n = 1;
    for (var i = 1; i < 20; i++) {
      expect(i, NumberFormat.numberOfIntegerDigits(n));
      n *= 10;
    }
  });
}
