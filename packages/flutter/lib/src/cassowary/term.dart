// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'equation_member.dart';
import 'expression.dart';
import 'param.dart';

/// Represents a single term in an expression. This term contains a single
/// indeterminate and has degree 1.
class Term extends EquationMember {
  /// Creates term with the given [Variable] and coefficient.
  Term(this.variable, this.coefficient);

  /// The [Variable] (or indeterminate) portion of this term. Variables are
  /// usually tied to an opaque object (via its `context` property). On a
  /// [Solver] flush, these context objects of updated variables are returned by
  /// the solver. An external entity can then choose to interpret these values
  /// in what manner it sees fit.
  final Variable variable;

  /// The coefficient of this term. Before addition of the [Constraint] to the
  /// solver, terms with a zero coefficient are dropped.
  final double coefficient;

  @override
  Expression asExpression() =>
      new Expression(<Term>[new Term(this.variable, this.coefficient)], 0.0);

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
