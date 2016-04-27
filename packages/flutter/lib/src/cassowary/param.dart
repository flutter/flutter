// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'equation_member.dart';
import 'expression.dart';
import 'term.dart';

class Variable {
  static int _total = 0;

  Variable(this.value) : _tick = _total++;

  final int _tick;

  double value;

  String name;

  Param get owner => _owner;
  Param _owner;

  bool applyUpdate(double updated) {
    bool res = updated != value;
    value = updated;
    return res;
  }

  String get debugName => name ?? 'variable$_tick';

  @override
  String toString() => debugName;
}

class Param extends EquationMember {
  Param([double value = 0.0]) : variable = new Variable(value) {
    variable._owner = this;
  }

  Param.withContext(dynamic context, [double value = 0.0])
    : variable = new Variable(value),
      context = context {
    variable._owner = this;
  }

  final Variable variable;

  dynamic context;

  @override
  Expression asExpression() => new Expression(<Term>[new Term(variable, 1.0)], 0.0);

  @override
  bool get isConstant => false;

  @override
  double get value => variable.value;

  String get name => variable.name;
  void set name(String name) { variable.name = name; }
}
