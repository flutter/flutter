// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class ConstantMember extends EquationMember {
  double value = 0.0;

  ConstantMember(this.value);

  Expression asExpression() => new Expression([], this.value);
}

ConstantMember CM(num value) {
  return new ConstantMember(value);
}
