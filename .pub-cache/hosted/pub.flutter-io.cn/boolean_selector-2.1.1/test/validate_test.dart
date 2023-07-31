// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:boolean_selector/boolean_selector.dart';
import 'package:test/test.dart';

var _selector = BooleanSelector.parse('foo && bar && baz');

void main() {
  test('throws if any variables are undefined', () {
    expect(() => _selector.validate((variable) => variable == 'bar'),
        throwsFormatException);
  });

  test("doesn't throw if all variables are defined", () {
    // Should not throw.
    _selector.validate((variable) => true);
  });
}
