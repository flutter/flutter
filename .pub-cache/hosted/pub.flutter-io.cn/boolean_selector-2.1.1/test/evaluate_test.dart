// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:boolean_selector/boolean_selector.dart';
import 'package:test/test.dart';

void main() {
  group('operator:', () {
    test('conditional', () {
      _expectEval('true ? true : false', true);
      _expectEval('true ? false : true', false);
      _expectEval('false ? true : false', false);
      _expectEval('false ? false : true', true);
    });

    test('or', () {
      _expectEval('true || true', true);
      _expectEval('true || false', true);
      _expectEval('false || true', true);
      _expectEval('false || false', false);
    });

    test('and', () {
      _expectEval('true && true', true);
      _expectEval('true && false', false);
      _expectEval('false && true', false);
      _expectEval('false && false', false);
    });

    test('not', () {
      _expectEval('!true', false);
      _expectEval('!false', true);
    });
  });

  test('with a semantics function', () {
    _expectEval('foo', false, semantics: (variable) => variable.contains('a'));
    _expectEval('bar', true, semantics: (variable) => variable.contains('a'));
    _expectEval('baz', true, semantics: (variable) => variable.contains('a'));
  });
}

/// Asserts that [expression] evaluates to [result] against [semantics].
///
/// By default, "true" is true and all other variables are "false".
void _expectEval(String expression, bool result,
    {bool Function(String variable)? semantics}) {
  expect(_eval(expression, semantics: semantics), equals(result),
      reason: 'Expected "$expression" to evaluate to $result.');
}

/// Returns the result of evaluating [expression] on [semantics].
///
/// By default, "true" is true and all other variables are "false".
bool _eval(String expression, {bool Function(String variable)? semantics}) {
  var selector = BooleanSelector.parse(expression);
  return selector.evaluate(semantics ?? (v) => v == 'true');
}
