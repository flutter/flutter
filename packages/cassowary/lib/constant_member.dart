// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class ConstantMember extends EquationMember {
  double value = 0.0;
  ConstantMember(this.value);

  Expression operator +(EquationMember m) {
    if (m is ConstantMember) {
      return new Expression([], this.value + m.value);
    }

    if (m is Variable) {
      return new Expression([new Term(m, 1.0)], this.value);
    }

    if (m is Term) {
      return new Expression([m], this.value);
    }

    if (m is Expression) {
      return new Expression(new List.from(m.terms), this.value + m.constant);
    }

    assert(false);
    return null;
  }

  Expression operator -(EquationMember m) {
    if (m is ConstantMember) {
      return new Expression([], this.value - m.value);
    }

    if (m is Variable) {
      return new Expression([new Term(m, -1.0)], this.value);
    }

    if (m is Term) {
      return new Expression([new Term(m.variable, -m.coefficient)], this.value);
    }

    if (m is Expression) {
      var negatedTerms = m.terms.fold(new List<Term>(), (list, term) => list
        ..add(new Term(term.variable, -term.coefficient)));
      return new Expression(negatedTerms, this.value - m.constant);
    }

    assert(false);
    return null;
  }

  EquationMember operator *(double m) {
    return new ConstantMember(this.value * m);
  }

  EquationMember operator /(double m) {
    return new ConstantMember(this.value / m);
  }
}

ConstantMember CM(num value) {
  return new ConstantMember(value);
}
