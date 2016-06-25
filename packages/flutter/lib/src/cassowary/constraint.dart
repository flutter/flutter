// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'priority.dart';
import 'expression.dart';

/// Relationships between [Constraint] expressions.
///
/// A [Constraint] is created by specifying a relationship between two
/// expressions. The [Solver] tries to satisfy this relationship after the
/// [Constraint] has been added to it at a set priority.
enum Relation {
  /// The relationship between the left and right hand sides of the expression
  /// is `==`, (lhs == rhs).
  equalTo,
  /// The relationship between the left and right hand sides of the expression
  /// is `<=`, (lhs <= rhs).
  lessThanOrEqualTo,
  /// The relationship between the left and right hand sides of the expression
  /// is `>=`, (lhs => rhs).
  greaterThanOrEqualTo,
}

/// A relationship between two expressions (represented by [Expression]) that
/// the [Solver] tries to hold true. In case of ambiguities, the [Solver] will
/// use priorities to determine [Constraint] precedence. Once a [Constraint] is
/// added to the [Solver], this [Priority] cannot be changed.
class Constraint {
  /// Creates a new [Constraint] by specifying a single [Expression]. This
  /// assumes that the right hand side [Expression] is the constant zero.
  /// (`<expression> <relation> <0>`)
  Constraint(this.expression, this.relation);

  /// The [Relation] between a [Constraint] [Expression] and zero.
  final Relation relation;

  /// The [Constraint] [Expression]. The [Expression] on the right hand side of
  /// constraint must be zero. If the [Expression] on the right is not zero,
  /// it must be negated from the left hand [Expression] before a [Constraint]
  /// can be created.
  final Expression expression;

  /// The [Constraint] [Priority]. The [Priority] can only be modified when the
  /// [Constraint] is being created. Once it is added to the solver,
  /// modifications to the [Constraint] [Priority] will have no effect on the
  /// how the solver evaluates the constraint.
  double priority = Priority.required;

  /// The operator `|` is overloaded as a convenience so that constraint
  /// priorities can be specifed along with the [Constraint] expression.
  ///
  /// For example: `ax + by + cx <= 0 | Priority.weak`. See [Priority].
  Constraint operator |(double p) => this..priority = p;

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write(expression.toString());

    switch (relation) {
      case Relation.equalTo:
        buffer.write(' == 0 ');
        break;
      case Relation.greaterThanOrEqualTo:
        buffer.write(' >= 0 ');
        break;
      case Relation.lessThanOrEqualTo:
        buffer.write(' <= 0 ');
        break;
    }

    buffer.write(' | priority = $priority');

    if (priority == Priority.required)
      buffer.write(' (required)');

    return buffer.toString();
  }
}
