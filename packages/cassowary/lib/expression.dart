// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Expression extends _EquationMember {
  Expression(this.terms, this.constant);
  Expression.fromExpression(Expression expr)
    : this.terms = new List<Term>.from(expr.terms),
      this.constant = expr.constant;

  final List<Term> terms;

  final double constant;

  @override
  bool get isConstant => terms.length == 0;

  @override
  double get value => terms.fold(constant, (double value, Term term) => value + term.value);

  @override
  Expression asExpression() => this;

  Constraint _createConstraint(_EquationMember /* rhs */ value, Relation relation) {
    if (value is ConstantMember) {
      return new Constraint(
        new Expression(new List<Term>.from(terms), constant - value.value),
        relation
      );
    }

    if (value is Param) {
      List<Term> newTerms = new List<Term>.from(terms)
        ..add(new Term(value.variable, -1.0));
      return new Constraint(new Expression(newTerms, constant), relation);
    }

    if (value is Term) {
      List<Term> newTerms = new List<Term>.from(terms)
        ..add(new Term(value.variable, -value.coefficient));
      return new Constraint(new Expression(newTerms, constant), relation);
    }

    if (value is Expression) {
      List<Term> newTerms = value.terms.fold(
        new List<Term>.from(terms),
        (List<Term> list, Term t) {
          return list..add(new Term(t.variable, -t.coefficient));
        }
      );
      return new Constraint(
        new Expression(newTerms, constant - value.constant),
        relation
      );
    }
    assert(false);
    return null;
  }

  @override
  Constraint operator >=(_EquationMember value) {
    return _createConstraint(value, Relation.greaterThanOrEqualTo);
  }

  @override
  Constraint operator <=(_EquationMember value) {
    return _createConstraint(value, Relation.lessThanOrEqualTo);
  }

  @override
  Constraint equals(_EquationMember value) {
    return _createConstraint(value, Relation.equalTo);
  }

  @override
  Expression operator +(_EquationMember m) {
    if (m is ConstantMember)
      return new Expression(new List<Term>.from(terms), constant + m.value);

    if (m is Param) {
      return new Expression(
        new List<Term>.from(terms)..add(new Term(m.variable, 1.0)),
        constant
      );
    }

    if (m is Term)
      return new Expression(new List<Term>.from(terms)..add(m), constant);

    if (m is Expression) {
      return new Expression(
        new List<Term>.from(terms)..addAll(m.terms),
        constant + m.constant
      );
    }
    assert(false);
    return null;
  }

  @override
  Expression operator -(_EquationMember m) {
    if (m is ConstantMember)
      return new Expression(new List<Term>.from(terms), constant - m.value);

    if (m is Param) {
      return new Expression(
        new List<Term>.from(terms)..add(new Term(m.variable, -1.0)),
        constant
      );
    }

    if (m is Term) {
      return new Expression(new List<Term>.from(terms)
        ..add(new Term(m.variable, -m.coefficient)), constant);
    }

    if (m is Expression) {
      List<Term> copiedTerms = new List<Term>.from(terms);
      for (Term t in m.terms)
        copiedTerms.add(new Term(t.variable, -t.coefficient));
      return new Expression(copiedTerms, constant - m.constant);
    }
    assert(false);
    return null;
  }

  _EquationMember _applyMultiplicand(double m) {
    List<Term> newTerms = terms.fold(
      new List<Term>(),
      (List<Term> list, Term term) {
        return list..add(new Term(term.variable, term.coefficient * m));
      }
    );
    return new Expression(newTerms, constant * m);
  }

  _Pair<Expression, double> _findMulitplierAndMultiplicand(_EquationMember m) {
    // At least on of the the two members must be constant for the resulting
    // expression to be linear

    if (!this.isConstant && !m.isConstant)
      return null;

    if (this.isConstant)
      return new _Pair<Expression, double>(m.asExpression(), this.value);

    if (m.isConstant)
      return new _Pair<Expression, double>(this.asExpression(), m.value);

    assert(false);
    return null;
  }

  _EquationMember operator *(_EquationMember m) {
    _Pair<Expression, double> args = _findMulitplierAndMultiplicand(m);

    if (args == null) {
      throw new ParserException(
        'Could not find constant multiplicand or multiplier',
        <_EquationMember>[this, m]
      );
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

    terms.forEach((Term t) => buffer.write('$t'));

    if (constant != 0.0) {
      buffer.write(constant.sign > 0.0 ? '+' : '-');
      buffer.write(constant.abs());
    }

    return buffer.toString();
  }
}
