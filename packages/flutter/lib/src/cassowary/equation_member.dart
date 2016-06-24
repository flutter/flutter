// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'expression.dart';
import 'constraint.dart';

/// A member that can be used to construct an [Expression] that may be
/// used to create a constraint. This is to facilitate the easy creation of
/// constraints. The use of the operator overloads is completely optional and
/// is only meant as a convenience. The [Constraint] expressions can be created
/// by manually creating instance of [Constraint] variables, then terms and
/// combining those to create expression.
abstract class EquationMember {
  /// The representation of this member after it is hoisted to be an
  /// expression.
  Expression asExpression();

  /// Returns if this member is a constant. Constant members can be combined
  /// more easily without making the expression non-linear. This makes them
  /// easier to use with multiplication and division operators. Constant
  /// expression that have zero value may also eliminate other expressions from
  /// the solver when used with the multiplication operator.
  bool get isConstant;

  /// The current constant value of this member. After a [Solver] flush, this is
  /// value read by entities outside the [Solver].
  double get value;

  /// Creates a [Constraint] by using this member as the left hand side
  /// expression and the argument as the right hand side [Expression] of a
  /// [Constraint] with a [Relation.greaterThanOrEqualTo] relationship between
  /// the two.
  ///
  /// For example: `right - left >= cm(200.0)` would read, "the width of the
  /// object is at least 200."
  Constraint operator >=(EquationMember m) => asExpression() >= m;

  /// Creates a [Constraint] by using this member as the left hand side
  /// expression and the argument as the right hand side [Expression] of a
  /// [Constraint] with a [Relation.lessThanOrEqualTo] relationship between the
  /// two.
  ///
  /// For example: `rightEdgeOfA <= leftEdgeOfB` would read, "the entities A and
  /// B are stacked left to right."
  Constraint operator <=(EquationMember m) => asExpression() <= m;

  /// Creates a [Constraint] by using this member as the left hand side
  /// expression and the argument as the right hand side [Expression] of a
  /// [Constraint] with a [Relation.equalTo] relationship between the two.
  ///
  /// For example: `topEdgeOfBoxA + cm(10.0) == topEdgeOfBoxB` woud read,
  /// "the entities A and B have a padding on top of 10."
  Constraint equals(EquationMember m) => asExpression().equals(m);

  /// Creates a [Expression] by adding this member with the argument. Both
  /// members may need to be hoisted to expressions themselves before this can
  /// occur.
  ///
  /// For example: `(left + right) / cm(2.0)` can be used as an [Expression]
  /// equivalent of the `midPointX` property.
  Expression operator +(EquationMember m) => asExpression() + m;

  /// Creates a [Expression] by subtracting the argument from this member. Both
  /// members may need to be hoisted to expressions themselves before this can
  /// occur.
  ///
  /// For example: `right - left` can be used as an [Expression]
  /// equivalent of the `width` property.
  Expression operator -(EquationMember m) => asExpression() - m;

  /// Creates a [Expression] by multiplying this member with the argument. Both
  /// members may need to be hoisted to expressions themselves before this can
  /// occur.
  ///
  /// Warning: This operation may throw a [ParserException] if the resulting
  /// expression is no longer linear. This is because a non-linear [Expression]
  /// may not be used to create a constraint. At least one of the [Expression]
  /// members must evaluate to a constant.
  ///
  /// For example: `((left + right) >= (cm(2.0) * mid)` declares a `midpoint`
  /// constraint. Notice that at least one the members of the right hand
  /// `Expression` is a constant.
  Expression operator *(EquationMember m) => asExpression() * m;

  /// Creates a [Expression] by dividing this member by the argument. Both
  /// members may need to be hoisted to expressions themselves before this can
  /// occur.
  ///
  /// Warning: This operation may throw a [ParserException] if the resulting
  /// expression is no longer linear. This is because a non-linear [Expression]
  /// may not be used to create a constraint. The divisor (i.e. the argument)
  /// must evaluate to a constant.
  ///
  /// For example: `((left + right) / cm(2.0) >= mid` declares a `midpoint`
  /// constraint. Notice that the divisor of the left hand [Expression] is a
  /// constant.
  Expression operator /(EquationMember m) => asExpression() / m;
}
