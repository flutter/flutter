// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

abstract class EquationMember {
  Expression asExpression();

  Constraint operator >=(EquationMember m) => asExpression() >= m;

  Constraint operator <=(EquationMember m) => asExpression() <= m;

  operator ==(EquationMember m) => asExpression() == m;

  Expression operator +(EquationMember m) => asExpression() + m;

  Expression operator -(EquationMember m) => asExpression() - m;
}
