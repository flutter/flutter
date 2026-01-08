// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool approx(double value, double expectation) {
    const eps = 1e-6;
    return (value - expectation).abs() < eps;
  }

  test('Least-squares fit: linear polynomial to line', () {
    final x = <double>[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
    final y = <double>[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
    final w = <double>[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];

    final solver = LeastSquaresSolver(x, y, w);
    final PolynomialFit fit = solver.solve(1)!;

    expect(fit.coefficients.length, 2);
    expect(approx(fit.coefficients[0], 1.0), isTrue);
    expect(approx(fit.coefficients[1], 0.0), isTrue);
    expect(approx(fit.confidence, 1.0), isTrue);
  });

  test('Least-squares fit: linear polynomial to sloped line', () {
    final x = <double>[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
    final y = <double>[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0];
    final w = <double>[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];

    final solver = LeastSquaresSolver(x, y, w);
    final PolynomialFit fit = solver.solve(1)!;

    expect(fit.coefficients.length, 2);
    expect(approx(fit.coefficients[0], 1.0), isTrue);
    expect(approx(fit.coefficients[1], 1.0), isTrue);
    expect(approx(fit.confidence, 1.0), isTrue);
  });

  test('Least-squares fit: quadratic polynomial to line', () {
    final x = <double>[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
    final y = <double>[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
    final w = <double>[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];

    final solver = LeastSquaresSolver(x, y, w);
    final PolynomialFit fit = solver.solve(2)!;

    expect(fit.coefficients.length, 3);
    expect(approx(fit.coefficients[0], 1.0), isTrue);
    expect(approx(fit.coefficients[1], 0.0), isTrue);
    expect(approx(fit.coefficients[2], 0.0), isTrue);
    expect(approx(fit.confidence, 1.0), isTrue);
  });

  test('Least-squares fit: quadratic polynomial to sloped line', () {
    final x = <double>[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
    final y = <double>[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0];
    final w = <double>[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];

    final solver = LeastSquaresSolver(x, y, w);
    final PolynomialFit fit = solver.solve(2)!;

    expect(fit.coefficients.length, 3);
    expect(approx(fit.coefficients[0], 1.0), isTrue);
    expect(approx(fit.coefficients[1], 1.0), isTrue);
    expect(approx(fit.coefficients[2], 0.0), isTrue);
    expect(approx(fit.confidence, 1.0), isTrue);
  });

  test('Least-squares fit: toString', () {
    final fit = PolynomialFit(2);
    fit.coefficients[0] = 123.45;
    fit.coefficients[1] = 54.321;
    fit.coefficients[2] = 1.3579;
    fit.confidence = 0.9876;
    expect(fit.toString(), 'PolynomialFit([123, 54.3, 1.36], confidence: 0.988)');
  });
}
