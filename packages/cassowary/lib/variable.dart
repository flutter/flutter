// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Variable extends EquationMember {
  double value = 0.0;
  Variable(this.value);

  Expression asExpression() => new Expression([new Term(this, 1.0)], 0.0);

  EquationMember operator *(double m) {
    return new Term(this, m);
  }

  EquationMember operator /(double m) {
    return new Term(this, 1.0 / m);
  }
}
