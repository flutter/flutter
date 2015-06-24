// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Expression extends EquationMember {
  final List<Term> terms;

  final double constant;
  double get value => terms.fold(constant, (value, term) => value + term.value);

  Expression(this.terms, this.constant);
  Expression.fromExpression(Expression expr)
      : this.terms = new List<Term>.from(expr.terms),
        this.constant = expr.constant;

  Expression asExpression() => this;

  Constraint _createConstraint(
      EquationMember /* rhs */ value, Relation relation) {
    if (value is ConstantMember) {
      return new Constraint(
          new Expression(new List.from(terms), constant - value.value),
          relation);
    }

    if (value is Variable) {
      var newTerms = new List<Term>.from(terms)..add(new Term(value, -1.0));
      return new Constraint(new Expression(newTerms, constant), relation);
    }

    if (value is Term) {
      var newTerms = new List<Term>.from(terms)
        ..add(new Term(value.variable, -value.coefficient));
      return new Constraint(new Expression(newTerms, constant), relation);
    }

    if (value is Expression) {
      var newTerms = value.terms.fold(new List<Term>.from(terms),
          (list, t) => list..add(new Term(t.variable, -t.coefficient)));
      return new Constraint(
          new Expression(newTerms, constant - value.constant), relation);
    }

    assert(false);
    return null;
  }

  Constraint operator >=(EquationMember value) =>
      _createConstraint(value, Relation.greaterThanOrEqualTo);

  Constraint operator <=(EquationMember value) =>
      _createConstraint(value, Relation.lessThanOrEqualTo);

  operator ==(EquationMember value) =>
      _createConstraint(value, Relation.equalTo);

  Expression operator +(EquationMember m) {
    if (m is ConstantMember) {
      return new Expression(new List.from(terms), constant + m.value);
    }

    if (m is Variable) {
      return new Expression(
          new List.from(terms)..add(new Term(m, 1.0)), constant);
    }

    if (m is Term) {
      return new Expression(new List.from(terms)..add(m), constant);
    }

    if (m is Expression) {
      return new Expression(
          new List.from(terms)..addAll(m.terms), constant + m.constant);
    }

    assert(false);
    return null;
  }

  Expression operator -(EquationMember m) {
    if (m is ConstantMember) {
      return new Expression(new List.from(terms), constant - m.value);
    }

    if (m is Variable) {
      return new Expression(
          new List.from(terms)..add(new Term(m, -1.0)), constant);
    }

    if (m is Term) {
      return new Expression(new List.from(terms)
        ..add(new Term(m.variable, -m.coefficient)), constant);
    }

    if (m is Expression) {
      var copiedTerms = new List<Term>.from(terms);
      m.terms.forEach(
          (t) => copiedTerms.add(new Term(t.variable, -t.coefficient)));
      return new Expression(copiedTerms, constant - m.constant);
    }

    assert(false);
    return null;
  }

  EquationMember operator *(double m) {
    var newTerms = terms.fold(new List<Term>(), (list, term) => list
      ..add(new Term(term.variable, term.coefficient * m)));
    return new Expression(newTerms, constant * m);
  }

  EquationMember operator /(double m) {
    var newTerms = terms.fold(new List<Term>(), (list, term) => list
      ..add(new Term(term.variable, term.coefficient / m)));
    return new Expression(newTerms, constant / m);
  }
}
