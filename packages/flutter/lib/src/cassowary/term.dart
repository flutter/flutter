// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'equation_member.dart';
import 'expression.dart';
import 'param.dart';

class Term extends EquationMember {
  Term(this.variable, this.coefficient);

  final Variable variable;

  final double coefficient;

  @override
  Expression asExpression() =>
      new Expression([new Term(this.variable, this.coefficient)], 0.0);

  @override
  bool get isConstant => false;

  @override
  double get value => coefficient * variable.value;

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();

    buffer.write(coefficient.sign > 0.0 ? "+" : "-");

    if (coefficient.abs() != 1.0) {
      buffer.write(coefficient.abs());
      buffer.write("*");
    }

    buffer.write(variable);

    return buffer.toString();
  }
}
