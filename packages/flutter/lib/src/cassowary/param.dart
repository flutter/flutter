// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'equation_member.dart';
import 'expression.dart';
import 'term.dart';

/// A [Variable] inside the layout [Solver]. It represents an indeterminate
/// in the [Expression] that is used to create the [Constraint]. If any entity
/// is interested in watching updates to the value of this indeterminate,
/// it can assign a watcher as the `owner`.
class Variable {
  /// Creates a new [Variable] with the given constant value.
  Variable(this.value);

  /// The current value of the variable.
  double value;

  /// An optional name given to the variable. This is useful in debugging
  /// [Solver] state.
  String name;

  /// Variables represent state inside the solver. This state is usually of
  /// interest to some entity outside the solver. Such entities can (optionally)
  /// associate themselves with these variables. This means that when solver
  /// is flushed, it is easy to obtain a reference to the entity the variable
  /// is associated with.
  Param get owner => _owner;

  Param _owner;

  /// Used by the [Solver] to apply updates to this variable. Only updated
  /// variables show up in [Solver] flush results.
  bool applyUpdate(double updated) {
    bool res = updated != value;
    value = updated;
    return res;
  }
}

/// A [Param] wraps a [Variable] and makes it suitable to be used in an
/// expression.
class Param extends EquationMember {
  /// Creates a new [Param] with the specified constant value.
  Param([double value = 0.0]) : variable = new Variable(value) {
    variable._owner = this;
  }

  /// Creates a new [Param] with the specified constant value that is tied
  /// to some object outside the solver.
  Param.withContext(dynamic context, [double value = 0.0])
    : variable = new Variable(value),
      context = context {
    variable._owner = this;
  }

  /// The [Variable] associated with this [Param].
  final Variable variable;

  /// Some object outside the [Solver] that is associated with this Param.
  dynamic context;

  @override
  Expression asExpression() => new Expression(<Term>[new Term(variable, 1.0)], 0.0);

  @override
  bool get isConstant => false;

  @override
  double get value => variable.value;

  /// The name of the [Variable] associated with this [Param].
  String get name => variable.name;

  /// Set the name of the [Variable] associated with this [Param].
  set name(String name) { variable.name = name; }
}
