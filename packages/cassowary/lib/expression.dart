// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Expression extends _EquationMember {
  final List<Term> terms;

  final double constant;

  bool get isConstant => terms.length == 0;

  double get value => terms.fold(constant, (value, term) => value + term.value);

  Expression(this.terms, this.constant);
  Expression.fromExpression(Expression expr)
      : this.terms = new List<Term>.from(expr.terms),
        this.constant = expr.constant;

  Expression asExpression() => this;

  Constraint _createConstraint(
      _EquationMember /* rhs */ value, Relation relation) {
    if (value is ConstantMember) {
      return new Constraint(
          new Expression(new List.from(terms), constant - value.value),
          relation);
    }

    if (value is Param) {
      var newTerms = new List<Term>.from(terms)
        ..add(new Term(value.variable, -1.0));
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

  Constraint operator >=(_EquationMember value) =>
      _createConstraint(value, Relation.greaterThanOrEqualTo);

  Constraint operator <=(_EquationMember value) =>
      _createConstraint(value, Relation.lessThanOrEqualTo);

  operator ==(_EquationMember value) =>
    _createConstraint(value, Relation.equalTo); // analyzer says "Type check failed" // analyzer says "The return type 'Constraint' is not a 'bool', as defined by the method '=='"

  Expression operator +(_EquationMember m) {
    if (m is ConstantMember) {
      return new Expression(new List.from(terms), constant + m.value);
    }

    if (m is Param) {
      return new Expression(
          new List.from(terms)..add(new Term(m.variable, 1.0)), constant);
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

  Expression operator -(_EquationMember m) {
    if (m is ConstantMember) {
      return new Expression(new List.from(terms), constant - m.value);
    }

    if (m is Param) {
      return new Expression(
          new List.from(terms)..add(new Term(m.variable, -1.0)), constant);
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

  _EquationMember _applyMultiplicand(double m) {
    var newTerms = terms.fold(new List<Term>(), (list, term) => list
      ..add(new Term(term.variable, term.coefficient * m)));
    return new Expression(newTerms, constant * m);
  }

  _Pair<Expression, double> _findMulitplierAndMultiplicand(_EquationMember m) {
    // At least on of the the two members must be constant for the resulting
    // expression to be linear

    if (!this.isConstant && !m.isConstant) {
      return null;
    }

    if (this.isConstant) {
      return new _Pair(m.asExpression(), this.value);
    }

    if (m.isConstant) {
      return new _Pair(this.asExpression(), m.value);
    }

    assert(false);
    return null;
  }

  _EquationMember operator *(_EquationMember m) {
    _Pair<Expression, double> args = _findMulitplierAndMultiplicand(m);

    if (args == null) {
      throw new ParserException(
          'Could not find constant multiplicand or multiplier', [this, m]);
      return null;
    }

    return args.first._applyMultiplicand(args.second);
  }

  _EquationMember operator /(_EquationMember m) {
    if (!m.isConstant) {
      throw new ParserException(
          'The divisor was not a constant expression', [this, m]);
      return null;
    }

    return this._applyMultiplicand(1.0 / m.value);
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();

    terms.forEach((t) => buffer.write('$t'));

    if (constant != 0.0) {
      buffer.write(constant.sign > 0.0 ? '+' : '-');
      buffer.write(constant.abs());
    }

    return buffer.toString();
  }
}
