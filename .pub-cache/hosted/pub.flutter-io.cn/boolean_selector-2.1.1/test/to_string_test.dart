// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:boolean_selector/boolean_selector.dart';
import 'package:test/test.dart';

void main() {
  group('toString() for', () {
    test('a variable is its name', () {
      _expectToString('foo');
      _expectToString('a-b');
    });

    group('not', () {
      test("doesn't parenthesize a variable", () => _expectToString('!a'));
      test("doesn't parenthesize a nested not", () => _expectToString('!!a'));
      test('parenthesizes an or', () => _expectToString('!(a || b)'));
      test('parenthesizes an and', () => _expectToString('!(a && b)'));
      test('parenthesizes a condition', () => _expectToString('!(a ? b : c)'));
    });

    group('or', () {
      test("doesn't parenthesize variables", () => _expectToString('a || b'));
      test("doesn't parenthesize nots", () => _expectToString('!a || !b'));

      test("doesn't parenthesize ors", () {
        _expectToString('a || b || c || d');
        _expectToString('((a || b) || c) || d', 'a || b || c || d');
      });

      test('parenthesizes ands',
          () => _expectToString('a && b || c && d', '(a && b) || (c && d)'));

      test('parenthesizes conditions',
          () => _expectToString('(a ? b : c) || (e ? f : g)'));
    });

    group('and', () {
      test("doesn't parenthesize variables", () => _expectToString('a && b'));
      test("doesn't parenthesize nots", () => _expectToString('!a && !b'));

      test(
          'parenthesizes ors',
          () =>
              _expectToString('(a || b) && (c || d)', '(a || b) && (c || d)'));

      test("doesn't parenthesize ands", () {
        _expectToString('a && b && c && d');
        _expectToString('((a && b) && c) && d', 'a && b && c && d');
      });

      test('parenthesizes conditions',
          () => _expectToString('(a ? b : c) && (e ? f : g)'));
    });

    group('conditional', () {
      test(
          "doesn't parenthesize variables", () => _expectToString('a ? b : c'));

      test("doesn't parenthesize nots", () => _expectToString('!a ? !b : !c'));

      test("doesn't parenthesize ors",
          () => _expectToString('a || b ? c || d : e || f'));

      test("doesn't parenthesize ands",
          () => _expectToString('a && b ? c && d : e && f'));

      test('parenthesizes non-trailing conditions', () {
        _expectToString('(a ? b : c) ? (e ? f : g) : h ? i : j');
        _expectToString('(a ? b : c) ? (e ? f : g) : (h ? i : j)',
            '(a ? b : c) ? (e ? f : g) : h ? i : j');
      });
    });
  });
}

void _expectToString(String selector, [String? result]) {
  result ??= selector;
  expect(_toString(selector), equals(result),
      reason: 'Expected toString of "$selector" to be "$result".');
}

String _toString(String selector) => BooleanSelector.parse(selector).toString();
