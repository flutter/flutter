// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'constant_member.dart';
import 'constraint.dart';
import 'equation_member.dart';
import 'param.dart';
import 'parser_exception.dart';
import 'term.dart';

class _Multiplication {
  const _Multiplication(this.multiplier, this.multiplicand);
  final Expression multiplier;
  final double multiplicand;
}

class Expression extends EquationMember {
  Expression(this.terms, this.constant);

  Expression.fromExpression(Expression expr)
    : this.terms = new List<Term>.from(expr.terms),
      this.constant = expr.constant;

  final List<Term> terms;

  final double constant;

  @override
  Expression asExpression() => this;

  @override
  bool get isConstant => terms.length == 0;

  @override
  double get value => terms.fold(constant, (double value, Term term) => value + term.value);

  @override
  Constraint operator >=(EquationMember value) {
    return _createConstraint(value, Relation.greaterThanOrEqualTo);
  }

  @override
  Constraint operator <=(EquationMember value) {
    return _createConstraint(value, Relation.lessThanOrEqualTo);
  }

  @override
  Constraint equals(EquationMember value) {
    return _createConstraint(value, Relation.equalTo);
  }

  Constraint _createConstraint(EquationMember /* rhs */ value, Relation relation) {
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
  Expression operator +(EquationMember m) {
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
  Expression operator -(EquationMember m) {
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

  @override
  EquationMember operator *(EquationMember m) {
    _Multiplication args = _findMulitplierAndMultiplicand(m);

    if (args == null) {
      throw new ParserException(
        'Could not find constant multiplicand or multiplier',
        <EquationMember>[this, m]
      );
    }

    return args.multiplier._applyMultiplicand(args.multiplicand);
  }

  @override
  EquationMember operator /(EquationMember m) {
    if (!m.isConstant) {
      throw new ParserException(
          'The divisor was not a constant expression', [this, m]);
      return null;
    }

    return this._applyMultiplicand(1.0 / m.value);
  }

  _Multiplication _findMulitplierAndMultiplicand(EquationMember m) {
    // At least one of the the two members must be constant for the resulting
    // expression to be linear

    if (!this.isConstant && !m.isConstant)
      return null;

    if (this.isConstant)
      return new _Multiplication(m.asExpression(), this.value);

    if (m.isConstant)
      return new _Multiplication(this.asExpression(), m.value);
    assert(false);
    return null;
  }

  EquationMember _applyMultiplicand(double m) {
    List<Term> newTerms = terms.fold(
      new List<Term>(),
      (List<Term> list, Term term) {
        return list..add(new Term(term.variable, term.coefficient * m));
      }
    );
    return new Expression(newTerms, constant * m);
  }

  @override
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
