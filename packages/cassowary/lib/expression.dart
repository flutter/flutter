// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Expression extends EquationMember {
  final List<Term> terms;

  final double constant;
  double get value => terms.fold(constant, (value, term) => value + term.value);

  Expression(this.terms, this.constant);

  Constraint _createConstraint(double value, Relation relation) {
    return new Constraint(
        new Expression(this.terms, this.constant + value), relation);
  }

  Constraint operator >=(double value) =>
      _createConstraint(-value, Relation.greaterThanOrEqualTo);

  Constraint operator <=(double value) =>
      _createConstraint(-value, Relation.lessThanOrEqualTo);

  operator ==(double value) => _createConstraint(-value, Relation.equalTo);

  Expression operator +(EquationMember m) {
    if (m is ConstantMember) {
      return new Expression(new List.from(this.terms), this.constant + m.value);
    }

    if (m is Variable) {
      return new Expression(
          new List.from(this.terms)..add(new Term(m, 1.0)), this.constant);
    }

    if (m is Term) {
      return new Expression(new List.from(this.terms)..add(m), this.constant);
    }

    if (m is Expression) {
      return new Expression(new List.from(this.terms)..addAll(m.terms),
          this.constant + m.constant);
    }

    assert(false);
    return null;
  }

  Expression operator -(EquationMember m) {
    if (m is ConstantMember) {
      return new Expression(new List.from(this.terms), this.constant - m.value);
    }

    if (m is Variable) {
      return new Expression(
          new List.from(this.terms)..add(new Term(m, -1.0)), this.constant);
    }

    if (m is Term) {
      return new Expression(new List.from(this.terms)
        ..add(new Term(m.variable, -m.coefficient)), this.constant);
    }

    if (m is Expression) {
      var copiedTerms = new List<Term>.from(this.terms);
      m.terms.forEach(
          (t) => copiedTerms.add(new Term(t.variable, -t.coefficient)));
      return new Expression(copiedTerms, this.constant - m.constant);
    }

    assert(false);
    return null;
  }

  EquationMember operator *(double m) {
    var terms = this.terms.fold(new List<Term>(), (list, term) => list
      ..add(new Term(term.variable, term.coefficient * m)));
    return new Expression(terms, this.constant);
  }

  // TODO(csg): Figure out how to dry this up.
  EquationMember operator /(double m) {
    var terms = this.terms.fold(new List<Term>(), (list, term) => list
      ..add(new Term(term.variable, term.coefficient / m)));
    return new Expression(terms, this.constant);
  }
}
