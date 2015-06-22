// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library cassowary.test;

import 'package:test/test.dart';

import 'package:cassowary/cassowary.dart';

void main() {
  test('variable', () {
    var v = new Variable(22.0);
    expect(v.value, 22);
  });

  test('variable1', () {
    var v = new Variable(22.0);
    expect((v + CM(22.0)).value, 44.0);
    expect((v - CM(20.0)).value, 2.0);
  });

  test('term', () {
    var t = new Term(new Variable(22.0), 2.0);
    expect(t.value, 44);
  });

  test('expression', () {
    var terms = [
      new Term(new Variable(22.0), 2.0),
      new Term(new Variable(1.0), 1.0),
    ];
    var e = new Expression(terms, 40.0);
    expect(e.value, 85.0);
  });

  test('expression1', () {
    var v1 = new Variable(10.0);
    var v2 = new Variable(10.0);
    var v3 = new Variable(22.0);

    expect(v1 is Variable, true);
    expect(v1 + CM(20.0) is Expression, true);
    expect(v1 + v2 is Expression, true);

    expect((v1 + v2).value, 20.0);
    expect((v1 - v2).value, 0.0);

    expect((v1 + v2 + v3) is Expression, true);
    expect((v1 + v2 + v3).value, 42.0);
  });

  test('expression2', () {
    var e = new Variable(10.0) + CM(5.0);
    expect(e.value, 15.0);
    expect(e is Expression, true);

    // Constant
    expect((e + CM(2.0)) is Expression, true);
    expect((e + CM(2.0)).value, 17.0);
    expect((e - CM(2.0)) is Expression, true);
    expect((e - CM(2.0)).value, 13.0);

    expect(e.value, 15.0);

    // Variable
    var v = new Variable(2.0);
    expect((e + v) is Expression, true);
    expect((e + v).value, 17.0);
    expect((e - v) is Expression, true);
    expect((e - v).value, 13.0);

    expect(e.value, 15.0);

    // Term
    var t = new Term(v, 2.0);
    expect((e + t) is Expression, true);
    expect((e + t).value, 19.0);
    expect((e - t) is Expression, true);
    expect((e - t).value, 11.0);

    expect(e.value, 15.0);

    // Expression
    var e2 = new Variable(7.0) + new Variable(3.0);
    expect((e + e2) is Expression, true);
    expect((e + e2).value, 25.0);
    expect((e - e2) is Expression, true);
    expect((e - e2).value, 5.0);

    expect(e.value, 15.0);
  });

  test('term2', () {
    var t = new Term(new Variable(12.0), 1.0);

    // Constant
    var c = CM(2.0);
    expect((t + c) is Expression, true);
    expect((t + c).value, 14.0);
    expect((t - c) is Expression, true);
    expect((t - c).value, 10.0);

    // Variable
    var v = new Variable(2.0);
    expect((t + v) is Expression, true);
    expect((t + v).value, 14.0);
    expect((t - v) is Expression, true);
    expect((t - v).value, 10.0);

    // Term
    var t2 = new Term(new Variable(1.0), 2.0);
    expect((t + t2) is Expression, true);
    expect((t + t2).value, 14.0);
    expect((t - t2) is Expression, true);
    expect((t - t2).value, 10.0);

    // Expression
    var exp = new Variable(1.0) + CM(1.0);
    expect((t + exp) is Expression, true);
    expect((t + exp).value, 14.0);
    expect((t - exp) is Expression, true);
    expect((t - exp).value, 10.0);
  });

  test('variable3', () {
    var v = new Variable(3.0);

    // Constant
    var c = CM(2.0);
    expect((v + c) is Expression, true);
    expect((v + c).value, 5.0);
    expect((v - c) is Expression, true);
    expect((v - c).value, 1.0);

    // Variable
    var v2 = new Variable(2.0);
    expect((v + v2) is Expression, true);
    expect((v + v2).value, 5.0);
    expect((v - v2) is Expression, true);
    expect((v - v2).value, 1.0);

    // Term
    var t2 = new Term(new Variable(1.0), 2.0);
    expect((v + t2) is Expression, true);
    expect((v + t2).value, 5.0);
    expect((v - t2) is Expression, true);
    expect((v - t2).value, 1.0);

    // Expression
    var exp = new Variable(1.0) + CM(1.0);
    expect(exp.terms.length, 1);

    expect((v + exp) is Expression, true);
    expect((v + exp).value, 5.0);
    expect((v - exp) is Expression, true);
    expect((v - exp).value, 1.0);
  });

  test('constantmember', () {
    var c = CM(3.0);

    // Constant
    var c2 = CM(2.0);
    expect((c + c2) is Expression, true);
    expect((c + c2).value, 5.0);
    expect((c - c2) is Expression, true);
    expect((c - c2).value, 1.0);

    // Variable
    var v2 = new Variable(2.0);
    expect((c + v2) is Expression, true);
    expect((c + v2).value, 5.0);
    expect((c - v2) is Expression, true);
    expect((c - v2).value, 1.0);

    // Term
    var t2 = new Term(new Variable(1.0), 2.0);
    expect((c + t2) is Expression, true);
    expect((c + t2).value, 5.0);
    expect((c - t2) is Expression, true);
    expect((c - t2).value, 1.0);

    // Expression
    var exp = new Variable(1.0) + CM(1.0);

    expect((c + exp) is Expression, true);
    expect((c + exp).value, 5.0);
    expect((c - exp) is Expression, true);
    expect((c - exp).value, 1.0);
  });

  test('constraint2', () {
    var left = new Variable(10.0);
    var right = new Variable(100.0);

    var c = right - left >= 25.0;
    expect(c is Constraint, true);
  });

  // TODO(csg): Address API inconsistency where the multipliers and divisors
  // are doubles instead of equation members

  test('simple_multiplication', () {
    // Constant
    var c = CM(20.0);
    expect((c * 2.0).value, 40.0);

    // Variable
    var v = new Variable(20.0);
    expect((v * 2.0).value, 40.0);

    // Term
    var t = new Term(v, 1.0);
    expect((t * 2.0).value, 40.0);

    // Expression
    var e = new Expression([t], 0.0);
    expect((e * 2.0).value, 40.0);
  });

  test('simple_division', () {
    // Constant
    var c = CM(20.0);
    expect((c / 2.0).value, 10.0);

    // Variable
    var v = new Variable(20.0);
    expect((v / 2.0).value, 10.0);

    // Term
    var t = new Term(v, 1.0);
    expect((t / 2.0).value, 10.0);

    // Expression
    var e = new Expression([t], 0.0);
    expect((e / 2.0).value, 10.0);
  });

  // TODO: Support and test cases where the multipliers and divisors are more
  // than just simple constants.

  test('full_constraints_setup', () {
    var left = new Variable(2.0);
    var right = new Variable(10.0);

    var c1 = right - left >= 20.0;
    expect(c1 is Constraint, true);
    expect(c1.expression.constant, -20.0);
    expect(c1.relation, Relation.greaterThanOrEqualTo);

    var c2 = (right - left == 30.0) as Constraint;
    expect(c2 is Constraint, true);
    expect(c2.expression.constant, -30.0);
    expect(c2.relation, Relation.equalTo);

    var c3 = right - left <= 30.0;
    expect(c3 is Constraint, true);
    expect(c3.expression.constant, -30.0);
    expect(c3.relation, Relation.lessThanOrEqualTo);
  });

  test('constraint_strength_update', () {
    var left = new Variable(2.0);
    var right = new Variable(10.0);

    var c = (right - left >= 200.0) | 750.0;
    expect(c is Constraint, true);
    expect(c.expression.terms.length, 2);
    expect(c.expression.constant, -200.0);
    expect(c.priority, 750.0);
  });
}
