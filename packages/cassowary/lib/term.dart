// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Term extends _EquationMember {
  Term(this.variable, this.coefficient);

  final Variable variable;
  final double coefficient;

  @override
  bool get isConstant => false;

  @override
  double get value => coefficient * variable.value;

  @override
  Expression asExpression() =>
      new Expression([new Term(this.variable, this.coefficient)], 0.0);

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
