// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Term extends EquationMember {
  final Variable variable;
  final double coefficient;
  double get value => coefficient * variable.value;

  Term(this.variable, this.coefficient);

  Expression operator +(EquationMember m) {
    if (m is ConstantMember) {
      return new Expression([this], m.value);
    }

    if (m is Variable) {
      return new Expression([this, new Term(m, 1.0)], 0.0);
    }

    if (m is Term) {
      return new Expression([this, m], 0.0);
    }

    if (m is Expression) {
      return new Expression(
          new List.from(m.terms)..insert(0, this), m.constant);
    }

    assert(false);
    return null;
  }

  Expression operator -(EquationMember m) {
    if (m is ConstantMember) {
      return new Expression([this], -m.value);
    }

    if (m is Variable) {
      return new Expression([this, new Term(m, -1.0)], 0.0);
    }

    if (m is Term) {
      return new Expression([this, new Term(m.variable, -m.coefficient)], 0.0);
    }

    if (m is Expression) {
      var negatedTerms = m.terms.fold(new List<Term>(),
          (list, t) => list..add(new Term(t.variable, -t.coefficient)));
      return new Expression(negatedTerms..insert(0, this), -m.constant);
    }

    assert(false);
    return null;
  }

  EquationMember operator *(double m) {
    return new Term(this.variable, this.coefficient * m);
  }

  EquationMember operator /(double m) {
    return new Term(this.variable, this.coefficient / m);
  }
}
