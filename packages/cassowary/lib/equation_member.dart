// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

abstract class EquationMember {
  Expression asExpression();

  bool get isConstant;

  double get value;

  Constraint operator >=(EquationMember m) => asExpression() >= m;

  Constraint operator <=(EquationMember m) => asExpression() <= m;

  /* Constraint */ operator ==(EquationMember m) => asExpression() == m;

  Expression operator +(EquationMember m) => asExpression() + m;

  Expression operator -(EquationMember m) => asExpression() - m;

  Expression operator *(EquationMember m) => asExpression() * m;

  Expression operator /(EquationMember m) => asExpression() / m;

  int get hashCode =>
      throw "An equation member is not comparable and cannot be added to collections";
}
