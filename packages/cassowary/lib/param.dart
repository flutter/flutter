// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Param extends _EquationMember {
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

  bool get isConstant => false;

  double get value => variable.value;

  String get name => variable.name;
  void set name(String name) { variable.name = name; }

  Expression asExpression() => new Expression(<Term>[new Term(variable, 1.0)], 0.0);
}
