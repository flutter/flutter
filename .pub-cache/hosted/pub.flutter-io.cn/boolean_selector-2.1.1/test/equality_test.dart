// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:boolean_selector/boolean_selector.dart';
import 'package:test/test.dart';

void main() {
  test('variable', () {
    _expectEqualsSelf('foo');
  });

  test('not', () {
    _expectEqualsSelf('!foo');
  });

  test('or', () {
    _expectEqualsSelf('foo || bar');
  });

  test('and', () {
    _expectEqualsSelf('foo && bar');
  });

  test('conditional', () {
    _expectEqualsSelf('foo ? bar : baz');
  });

  test('all', () {
    expect(BooleanSelector.all, equals(BooleanSelector.all));
  });

  test('none', () {
    expect(BooleanSelector.none, equals(BooleanSelector.none));
  });

  test("redundant parens don't matter", () {
    expect(BooleanSelector.parse('foo && (bar && baz)'),
        equals(BooleanSelector.parse('foo && (bar && baz)')));
  });

  test('meaningful parens do matter', () {
    expect(BooleanSelector.parse('(foo && bar) || baz'),
        equals(BooleanSelector.parse('foo && bar || baz')));
  });
}

void _expectEqualsSelf(String selector) {
  expect(
      BooleanSelector.parse(selector), equals(BooleanSelector.parse(selector)));
}
