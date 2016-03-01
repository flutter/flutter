// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class ConstantMember extends _EquationMember {
  @override
  final double value;

  @override
  bool get isConstant => true;

  ConstantMember(this.value);

  @override
  Expression asExpression() => new Expression([], this.value);
}

ConstantMember cm(double value) {
  return new ConstantMember(value);
}
