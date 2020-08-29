// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('lerpDouble should return null if and only if both inputs are null', () {
    expect(lerpDouble(null, null, 1.0), isNull);
    expect(lerpDouble(5.0, null, 0.25), isNotNull);
    expect(lerpDouble(null, 5.0, 0.25), isNotNull);

    expect(lerpDouble(5, null, 0.25), isNotNull);
    expect(lerpDouble(null, 5, 0.25), isNotNull);
  });

  test('lerpDouble should treat a null input as 0 if the other input is non-null', () {
    expect(lerpDouble(null, 10.0, 0.25), 2.5);
    expect(lerpDouble(10.0, null, 0.25), 7.5);

    expect(lerpDouble(null, 10, 0.25), 2.5);
    expect(lerpDouble(10, null, 0.25), 7.5);
  });

  test('lerpDouble should handle interpolation values < 0.0', () {
    expect(lerpDouble(0.0, 10.0, -5.0), -50.0);
    expect(lerpDouble(10.0, 0.0, -5.0), 60.0);

    expect(lerpDouble(0, 10, -5), -50);
    expect(lerpDouble(10, 0, -5), 60);
  });

  test('lerpDouble should return the start value at 0.0', () {
    expect(lerpDouble(2.0, 10.0, 0.0), 2.0);
    expect(lerpDouble(10.0, 2.0, 0.0), 10.0);

    expect(lerpDouble(2, 10, 0), 2);
    expect(lerpDouble(10, 2, 0), 10);
  });

  test('lerpDouble should interpolate between two values', () {
    expect(lerpDouble(0.0, 10.0, 0.25), 2.5);
    expect(lerpDouble(10.0, 0.0, 0.25), 7.5);

    expect(lerpDouble(0, 10, 0.25), 2.5);
    expect(lerpDouble(10, 0, 0.25), 7.5);
  });

  test('lerpDouble should return the end value at 1.0', () {
    expect(lerpDouble(2.0, 10.0, 1.0), 10.0);
    expect(lerpDouble(10.0, 2.0, 1.0), 2.0);

    expect(lerpDouble(0, 10, 5), 50);
    expect(lerpDouble(10, 0, 5), -40);
  });

  test('lerpDouble should handle interpolation values > 1.0', () {
    expect(lerpDouble(0.0, 10.0, 5.0), 50.0);
    expect(lerpDouble(10.0, 0.0, 5.0), -40.0);

    expect(lerpDouble(0, 10, 5), 50);
    expect(lerpDouble(10, 0, 5), -40);
  });

  test('lerpDouble should return NaN if any input is NaN', () {
    expect(lerpDouble(0.0, 10.0, double.nan), isNaN);
    expect(lerpDouble(0.0, double.infinity, double.nan), isNaN);
    expect(lerpDouble(0.0, double.nan, 5.0), isNaN);
    expect(lerpDouble(0.0, double.nan, double.infinity), isNaN);
    expect(lerpDouble(0.0, double.nan, double.nan), isNaN);
    expect(lerpDouble(double.infinity, 10.0, double.nan), isNaN);
    expect(lerpDouble(double.infinity, double.infinity, double.nan), isNaN);
    expect(lerpDouble(double.infinity, double.nan, 5.0), isNaN);
    expect(lerpDouble(double.infinity, double.nan, double.infinity), isNaN);
    expect(lerpDouble(double.infinity, double.nan, double.nan), isNaN);
    expect(lerpDouble(double.nan, 10.0, 5.0), isNaN);
    expect(lerpDouble(double.nan, 10.0, double.infinity), isNaN);
    expect(lerpDouble(double.nan, 10.0, double.nan), isNaN);
    expect(lerpDouble(double.nan, double.infinity, 5.0), isNaN);
    expect(lerpDouble(double.nan, double.infinity, double.infinity), isNaN);
    expect(lerpDouble(double.nan, double.infinity, double.nan), isNaN);
    expect(lerpDouble(double.nan, double.nan, 5.0), isNaN);
    expect(lerpDouble(double.nan, double.nan, double.infinity), isNaN);
    expect(lerpDouble(double.nan, double.nan, double.nan), isNaN);
  });

  test('lerpDouble returns NaN if interpolation results in Infinity - Infinity', () {
    expect(lerpDouble(double.infinity, 10.0, 5.0), isNaN);
    expect(lerpDouble(double.infinity, 10.0, double.infinity), isNaN);
    expect(lerpDouble(-double.infinity, 10.0, 5.0), isNaN);
    expect(lerpDouble(-double.infinity, 10.0, double.infinity), isNaN);
  });

  test('lerpDouble returns +/- infinity if interpolating towards an infinity', () {
    expect(lerpDouble(double.infinity, 10.0, -5.0)?.isInfinite, isTrue);
    expect(lerpDouble(double.infinity, 10.0, -double.infinity)?.isInfinite, isTrue);
    expect(lerpDouble(-double.infinity, 10.0, -5.0)?.isInfinite, isTrue);
    expect(lerpDouble(-double.infinity, 10.0, -double.infinity)?.isInfinite, isTrue);
    expect(lerpDouble(0.0, double.infinity, 5.0)?.isInfinite, isTrue);
    expect(lerpDouble(0.0, double.infinity, -5.0)?.isInfinite, isTrue);
    expect(lerpDouble(0.0, 10.0, double.infinity)?.isInfinite, isTrue);
    expect(lerpDouble(0.0, double.infinity, double.infinity)?.isInfinite, isTrue);
  });

  test('lerpDouble returns NaN if start/end and interpolation value are infinity', () {
    expect(lerpDouble(double.infinity, double.infinity, double.infinity), isNaN);
  });
}
