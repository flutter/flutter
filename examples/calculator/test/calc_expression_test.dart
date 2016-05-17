// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:calculator/calc_expression.dart';
import 'package:test/test.dart';

void main() {
  test('Test order of operations: 12 + 3 * 4 = 24', () {
    CalcExpression expression = new CalcExpression.Empty();
    expression = expression.appendDigit(1);
    expression = expression.appendDigit(2);
    expression = expression.appendOperation(Operation.Addition);
    expression = expression.appendDigit(3);
    expression = expression.appendOperation(Operation.Multiplication);
    expression = expression.appendDigit(4);
    expression = expression.computeResult();
    expect(expression.state, equals(ExpressionState.Result));
    expect("24", equals(expression.toString()));
  });
}
