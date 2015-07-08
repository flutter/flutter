// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library cassowary.test;

import 'package:test/test.dart';

import 'package:cassowary/cassowary.dart';

void main() {
  test('variable', () {
    var v = new Param(22.0);
    expect(v.value, 22);
  });

  test('variable1', () {
    var v = new Param(22.0);
    expect((v + cm(22.0)).value, 44.0);
    expect((v - cm(20.0)).value, 2.0);
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
    var v1 = new Param(10.0);
    var v2 = new Param(10.0);
    var v3 = new Param(22.0);

    expect(v1 is Param, true);
    expect(v1 + cm(20.0) is Expression, true);
    expect(v1 + v2 is Expression, true);

    expect((v1 + v2).value, 20.0);
    expect((v1 - v2).value, 0.0);

    expect((v1 + v2 + v3) is Expression, true);
    expect((v1 + v2 + v3).value, 42.0);
  });

  test('expression2', () {
    var e = new Param(10.0) + cm(5.0);
    expect(e.value, 15.0);
    expect(e is Expression, true);

    // Constant
    expect((e + cm(2.0)) is Expression, true);
    expect((e + cm(2.0)).value, 17.0);
    expect((e - cm(2.0)) is Expression, true);
    expect((e - cm(2.0)).value, 13.0);

    expect(e.value, 15.0);

    // Param
    var v = new Param(2.0);
    expect((e + v) is Expression, true);
    expect((e + v).value, 17.0);
    expect((e - v) is Expression, true);
    expect((e - v).value, 13.0);

    expect(e.value, 15.0);

    // Term
    var t = new Term(v.variable, 2.0);
    expect((e + t) is Expression, true);
    expect((e + t).value, 19.0);
    expect((e - t) is Expression, true);
    expect((e - t).value, 11.0);

    expect(e.value, 15.0);

    // Expression
    var e2 = new Param(7.0) + new Param(3.0);
    expect((e + e2) is Expression, true);
    expect((e + e2).value, 25.0);
    expect((e - e2) is Expression, true);
    expect((e - e2).value, 5.0);

    expect(e.value, 15.0);
  });

  test('term2', () {
    var t = new Term(new Variable(12.0), 1.0);

    // Constant
    var c = cm(2.0);
    expect((t + c) is Expression, true);
    expect((t + c).value, 14.0);
    expect((t - c) is Expression, true);
    expect((t - c).value, 10.0);

    // Variable
    var v = new Param(2.0);
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
    var exp = new Param(1.0) + cm(1.0);
    expect((t + exp) is Expression, true);
    expect((t + exp).value, 14.0);
    expect((t - exp) is Expression, true);
    expect((t - exp).value, 10.0);
  });

  test('variable3', () {
    var v = new Param(3.0);

    // Constant
    var c = cm(2.0);
    expect((v + c) is Expression, true);
    expect((v + c).value, 5.0);
    expect((v - c) is Expression, true);
    expect((v - c).value, 1.0);

    // Variable
    var v2 = new Param(2.0);
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
    var exp = new Param(1.0) + cm(1.0);
    expect(exp.terms.length, 1);

    expect((v + exp) is Expression, true);
    expect((v + exp).value, 5.0);
    expect((v - exp) is Expression, true);
    expect((v - exp).value, 1.0);
  });

  test('constantmember', () {
    var c = cm(3.0);

    // Constant
    var c2 = cm(2.0);
    expect((c + c2) is Expression, true);
    expect((c + c2).value, 5.0);
    expect((c - c2) is Expression, true);
    expect((c - c2).value, 1.0);

    // Variable
    var v2 = new Param(2.0);
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
    var exp = new Param(1.0) + cm(1.0);

    expect((c + exp) is Expression, true);
    expect((c + exp).value, 5.0);
    expect((c - exp) is Expression, true);
    expect((c - exp).value, 1.0);
  });

  test('constraint2', () {
    var left = new Param(10.0);
    var right = new Param(100.0);

    var c = right - left >= cm(25.0);
    expect(c is Constraint, true);
  });

  test('simple_multiplication', () {
    // Constant
    var c = cm(20.0);
    expect((c * cm(2.0)).value, 40.0);

    // Variable
    var v = new Param(20.0);
    expect((v * cm(2.0)).value, 40.0);

    // Term
    var t = new Term(v.variable, 1.0);
    expect((t * cm(2.0)).value, 40.0);

    // Expression
    var e = new Expression([t], 0.0);
    expect((e * cm(2.0)).value, 40.0);
  });

  test('simple_division', () {
    // Constant
    var c = cm(20.0);
    expect((c / cm(2.0)).value, 10.0);

    // Variable
    var v = new Param(20.0);
    expect((v / cm(2.0)).value, 10.0);

    // Term
    var t = new Term(v.variable, 1.0);
    expect((t / cm(2.0)).value, 10.0);

    // Expression
    var e = new Expression([t], 0.0);
    expect((e / cm(2.0)).value, 10.0);
  });

  test('full_constraints_setup', () {
    var left = new Param(2.0);
    var right = new Param(10.0);

    var c1 = right - left >= cm(20.0);
    expect(c1 is Constraint, true);
    expect(c1.expression.constant, -20.0);
    expect(c1.relation, Relation.greaterThanOrEqualTo);

    var c2 = (right - left == cm(30.0)) as Constraint;
    expect(c2 is Constraint, true);
    expect(c2.expression.constant, -30.0);
    expect(c2.relation, Relation.equalTo);

    var c3 = right - left <= cm(30.0);
    expect(c3 is Constraint, true);
    expect(c3.expression.constant, -30.0);
    expect(c3.relation, Relation.lessThanOrEqualTo);
  });

  test('constraint_strength_update', () {
    var left = new Param(2.0);
    var right = new Param(10.0);

    var c = (right - left >= cm(200.0)) | 750.0;
    expect(c is Constraint, true);
    expect(c.expression.terms.length, 2);
    expect(c.expression.constant, -200.0);
    expect(c.priority, 750.0);
  });

  test('solver', () {
    var s = new Solver();

    var left = new Param(2.0);
    var right = new Param(100.0);

    var c1 = right - left >= cm(200.0);

    expect((right >= left) is Constraint, true);

    expect(s.addConstraint(c1), Result.success);
  });

  test('constraint_complex', () {
    var e = new Param(200.0) - new Param(100.0);

    // Constant
    var c1 = e >= cm(50.0);
    expect(c1 is Constraint, true);
    expect(c1.expression.terms.length, 2);
    expect(c1.expression.constant, -50.0);

    // Variable
    var c2 = e >= new Param(2.0);
    expect(c2 is Constraint, true);
    expect(c2.expression.terms.length, 3);
    expect(c2.expression.constant, 0.0);

    // Term
    var c3 = e >= new Term(new Variable(2.0), 1.0);
    expect(c3 is Constraint, true);
    expect(c3.expression.terms.length, 3);
    expect(c3.expression.constant, 0.0);

    // Expression
    var c4 = e >= new Expression([new Term(new Variable(2.0), 1.0)], 20.0);
    expect(c4 is Constraint, true);
    expect(c4.expression.terms.length, 3);
    expect(c4.expression.constant, -20.0);
  });

  test('constraint_complex_non_exprs', () {
    // Constant
    var c1 = cm(100.0) >= cm(50.0);
    expect(c1 is Constraint, true);
    expect(c1.expression.terms.length, 0);
    expect(c1.expression.constant, 50.0);

    // Variable
    var c2 = new Param(100.0) >= new Param(2.0);
    expect(c2 is Constraint, true);
    expect(c2.expression.terms.length, 2);
    expect(c2.expression.constant, 0.0);

    // Term
    var t = new Term(new Variable(100.0), 1.0);
    var c3 = t >= new Term(new Variable(2.0), 1.0);
    expect(c3 is Constraint, true);
    expect(c3.expression.terms.length, 2);
    expect(c3.expression.constant, 0.0);

    // Expression
    var e = new Expression([t], 0.0);
    var c4 = e >= new Expression([new Term(new Variable(2.0), 1.0)], 20.0);
    expect(c4 is Constraint, true);
    expect(c4.expression.terms.length, 2);
    expect(c4.expression.constant, -20.0);
  });

  test('constraint_update_in_solver', () {
    var s = new Solver();

    var left = new Param(2.0);
    var right = new Param(100.0);

    var c1 = right - left >= cm(200.0);
    var c2 = right >= right;

    expect(s.addConstraint(c1), Result.success);
    expect(s.addConstraint(c1), Result.duplicateConstraint);
    expect(s.removeConstraint(c2), Result.unknownConstraint);
    expect(s.removeConstraint(c1), Result.success);
    expect(s.removeConstraint(c1), Result.unknownConstraint);
  });

  test('test_multiplication_division_override', () {
    var c = cm(10.0);
    var v = new Param(c.value);
    var t = new Term(v.variable, 1.0);
    var e = new Expression([t], 0.0);

    // Constant
    expect((c * cm(10.0)).value, 100);

    // Variable
    expect((v * cm(10.0)).value, 100);

    // Term
    expect((t * cm(10.0)).value, 100);

    // Expression
    expect((e * cm(10.0)).value, 100);

    // Constant
    expect((c / cm(10.0)).value, 1);

    // Variable
    expect((v / cm(10.0)).value, 1);

    // Term
    expect((t / cm(10.0)).value, 1);

    // Expression
    expect((e / cm(10.0)).value, 1);
  });

  test('test_multiplication_division_exceptions', () {
    var c = cm(10.0);
    var v = new Param(c.value);
    var t = new Term(v.variable, 1.0);
    var e = new Expression([t], 0.0);

    expect((c * c).value, 100);
    expect(() => v * v, throwsA(new isInstanceOf<ParserException>()));
    expect(() => v / v, throwsA(new isInstanceOf<ParserException>()));
    expect(() => v * t, throwsA(new isInstanceOf<ParserException>()));
    expect(() => v / t, throwsA(new isInstanceOf<ParserException>()));
    expect(() => v * e, throwsA(new isInstanceOf<ParserException>()));
    expect(() => v / e, throwsA(new isInstanceOf<ParserException>()));
    expect(() => v * c, returnsNormally);
    expect(() => v / c, returnsNormally);
  });

  test('edit_updates', () {
    Solver s = new Solver();

    var left = new Param(0.0);
    var right = new Param(100.0);
    var mid = new Param(0.0);

    Constraint c = left + right >= cm(2.0) * mid;
    expect(s.addConstraint(c), Result.success);

    expect(s.addEditVariable(mid.variable, 999.0), Result.success);
    expect(
        s.addEditVariable(mid.variable, 999.0), Result.duplicateEditVariable);
    expect(s.removeEditVariable(mid.variable), Result.success);
    expect(s.removeEditVariable(mid.variable), Result.unknownEditVariable);
  });

  test('bug1', () {
    var left = new Param(0.0);
    var right = new Param(100.0);
    var mid = new Param(0.0);

    expect(((left + right) >= (cm(2.0) * mid)) is Constraint, true);
  });

  test('single_item', () {
    var left = new Param(-20.0);
    Solver s = new Solver();
    s.addConstraint(left >= cm(0.0));
    s.flushUpdates();
    expect(left.value, 0.0);
  });

  test('midpoints', () {
    var left = new Param(0.0)..name = "left";
    var right = new Param(0.0)..name = "right";
    var mid = new Param(0.0)..name = "mid";

    Solver s = new Solver();

    expect(s.addConstraint((right + left == mid * cm(2.0)) as Constraint),
        Result.success);
    expect(s.addConstraint(right - left >= cm(100.0)), Result.success);
    expect(s.addConstraint(left >= cm(0.0)), Result.success);

    s.flushUpdates();

    expect(left.value, 0.0);
    expect(mid.value, 50.0);
    expect(right.value, 100.0);
  });

  test('addition_of_multiple', () {
    var left = new Param(0.0);
    var right = new Param(0.0);
    var mid = new Param(0.0);

    Solver s = new Solver();

    var c = (left >= cm(0.0));

    expect(s.addConstraints([
      (left + right == cm(2.0) * mid) as Constraint,
      (right - left >= cm(100.0)),
      c
    ]), Result.success);

    expect(s.addConstraints([(right >= cm(-20.0)), c]),
        Result.duplicateConstraint);
  });

  test('edit_constraints', () {
    var left = new Param(0.0)..name = "left";
    var right = new Param(0.0)..name = "right";
    var mid = new Param(0.0)..name = "mid";

    Solver s = new Solver();

    expect(s.addConstraint((right + left == mid * cm(2.0)) as Constraint),
        Result.success);
    expect(s.addConstraint(right - left >= cm(100.0)), Result.success);
    expect(s.addConstraint(left >= cm(0.0)), Result.success);

    expect(s.addEditVariable(mid.variable, Priority.strong), Result.success);
    expect(s.suggestValueForVariable(mid.variable, 300.0), Result.success);

    s.flushUpdates();

    expect(left.value, 0.0);
    expect(mid.value, 300.0);
    expect(right.value, 600.0);
  });

  test('test_description', () {
    var left = new Param(0.0);
    var right = new Param(100.0);
    var c1 = right >= left;
    var c2 = right <= left;
    var c3 = (right == left) as Constraint;

    Solver s = new Solver();
    expect(s.addConstraint(c1), Result.success);
    expect(s.addConstraint(c2), Result.success);
    expect(s.addConstraint(c3), Result.success);

    expect(s.toString() != null, true);
  });

  test('solution_with_optimize', () {
    Param p1 = new Param();
    Param p2 = new Param();
    Param p3 = new Param();

    Param container = new Param();

    Solver solver = new Solver();

    solver.addEditVariable(container.variable, Priority.strong);
    solver.suggestValueForVariable(container.variable, 100.0);

    solver.addConstraint((p1 >= cm(30.0)) | Priority.strong);
    solver.addConstraint(((p1 == p3) as Constraint) | Priority.medium);
    solver.addConstraint((p2 == cm(2.0) * p1) as Constraint);
    solver.addConstraint((container == (p1 + p2 + p3)) as Constraint);

    solver.flushUpdates();

    expect(container.value, 100.0);

    expect(p1.value, 30.0);
    expect(p2.value, 60.0);
    expect(p3.value, 10.0);
  });

  test('test_updates_collection', () {
    Param left = new Param.withContext("left");
    Param mid = new Param.withContext("mid");
    Param right = new Param.withContext("right");

    Solver s = new Solver();

    expect(s.addEditVariable(mid.variable, Priority.strong), Result.success);

    expect(s.addConstraint((mid * cm(2.0) == left + right) as Constraint),
        Result.success);
    expect(s.addConstraint(left >= cm(0.0)), Result.success);

    expect(s.suggestValueForVariable(mid.variable, 50.0), Result.success);

    var updates = s.flushUpdates();

    expect(updates.length, 2);

    expect(left.value, 0.0);
    expect(mid.value, 50.0);
    expect(right.value, 100.0);
  });

  test('test_updates_collection_is_set', () {
    Param left = new Param.withContext("a");
    Param mid = new Param.withContext("a");
    Param right = new Param.withContext("a");

    Solver s = new Solver();

    expect(s.addEditVariable(mid.variable, Priority.strong), Result.success);

    expect(s.addConstraint((mid * cm(2.0) == left + right) as Constraint),
        Result.success);
    expect(s.addConstraint(left >= cm(10.0)), Result.success);

    expect(s.suggestValueForVariable(mid.variable, 50.0), Result.success);

    var updates = s.flushUpdates();

    expect(updates.length, 1);

    expect(left.value, 10.0);
    expect(mid.value, 50.0);
    expect(right.value, 90.0);
  });

  test('param_context_non_final', () {
    var p = new Param.withContext("a");
    p.context = "b";
    expect(p.context, "b");
  });

  test('check_type_of_eq_result', () {
    Param left = new Param();
    Param right = new Param();

    expect((left == right).runtimeType, Constraint);
  });

  test('bulk_add_edit_variables', () {
    Solver s = new Solver();

    var left = new Param(0.0);
    var right = new Param(100.0);
    var mid = new Param(0.0);

    expect(s.addEditVariables(
         [left.variable, right.variable, mid.variable], 999.0), Result.success);
  });

  test('bulk_remove_constraints_and_variables', () {
    Solver s = new Solver();

    var left = new Param(0.0);
    var right = new Param(100.0);
    var mid = new Param(0.0);

    expect(s.addEditVariables(
         [left.variable, right.variable, mid.variable], 999.0), Result.success);

    var c1 = left <= mid;
    var c2 = mid <= right;

    expect(s.addConstraints([c1, c2]), Result.success);

    expect(s.removeConstraints([c1, c2]), Result.success);

    expect(s.removeEditVariables(
                [left.variable, right.variable, mid.variable]), Result.success);
  });
}
