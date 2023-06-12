// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:boolean_selector/boolean_selector.dart';

void main() {
  test('a variable reports itself', () {
    expect(BooleanSelector.parse('foo').variables, equals(['foo']));
  });

  test('a negation reports its contents', () {
    expect(BooleanSelector.parse('!foo').variables, equals(['foo']));
  });

  test('a parenthesized expression reports its contents', () {
    expect(BooleanSelector.parse('(foo)').variables, equals(['foo']));
  });

  test('an or reports its contents', () {
    expect(
        BooleanSelector.parse('foo || bar').variables, equals(['foo', 'bar']));
  });

  test('an and reports its contents', () {
    expect(
        BooleanSelector.parse('foo && bar').variables, equals(['foo', 'bar']));
  });

  test('a conditional reports its contents', () {
    expect(BooleanSelector.parse('foo ? bar : baz').variables,
        equals(['foo', 'bar', 'baz']));
  });

  test('BooleanSelector.all reports no variables', () {
    expect(BooleanSelector.all.variables, isEmpty);
  });

  test('BooleanSelector.none reports no variables', () {
    expect(BooleanSelector.none.variables, isEmpty);
  });
}
