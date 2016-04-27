// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'expression.dart';
import 'constraint.dart';

/// Base class for the various parts of cassowary equations.
abstract class EquationMember {
  Expression asExpression();

  bool get isConstant;

  double get value;

  Constraint operator >=(EquationMember m) => asExpression() >= m;

  Constraint operator <=(EquationMember m) => asExpression() <= m;

  Constraint equals(EquationMember m) => asExpression().equals(m);

  Expression operator +(EquationMember m) => asExpression() + m;

  Expression operator -(EquationMember m) => asExpression() - m;

  Expression operator *(EquationMember m) => asExpression() * m;

  Expression operator /(EquationMember m) => asExpression() / m;
}
