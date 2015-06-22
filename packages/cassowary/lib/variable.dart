// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Variable extends EquationMember {
  double value = 0.0;
  Variable(this.value);

  Expression operator +(EquationMember m) {
    if (m is ConstantMember) {
      return new Expression([new Term(this, 1.0)], m.value);
    }

    if (m is Variable) {
      return new Expression([new Term(this, 1.0), new Term(m, 1.0)], 0.0);
    }

    if (m is Term) {
      return new Expression([new Term(this, 1.0), m], 0.0);
    }

    if (m is Expression) {
      return new Expression(
          new List.from(m.terms)..insert(0, new Term(this, 1.0)), m.constant);
    }

    assert(false);
    return null;
  }

  Expression operator -(EquationMember m) {
    if (m is ConstantMember) {
      return new Expression([new Term(this, 1.0)], -m.value);
    }

    if (m is Variable) {
      return new Expression([new Term(this, 1.0), new Term(m, -1.0)], 0.0);
    }

    if (m is Term) {
      return new Expression(
          [new Term(this, 1.0), new Term(m.variable, -m.coefficient)], 0.0);
    }

    if (m is Expression) {
      var negatedTerms = m.terms.fold(new List<Term>(),
          (list, t) => list..add(new Term(t.variable, -t.coefficient)));
      negatedTerms.insert(0, new Term(this, 1.0));
      return new Expression(negatedTerms, -m.constant);
    }

    assert(false);
    return null;
  }

  EquationMember operator *(double m) {
    return new Term(this, m);
  }

  EquationMember operator /(double m) {
    return new Term(this, 1.0 / m);
  }
}
