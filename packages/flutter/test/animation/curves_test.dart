// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('toString control test', () {
    expect(Curves.linear, hasOneLineDescription);
    expect(const SawTooth(3), hasOneLineDescription);
    expect(const Interval(0.25, 0.75), hasOneLineDescription);
    expect(const Interval(0.25, 0.75, curve: Curves.ease), hasOneLineDescription);
  });

  test('Curve flipped control test', () {
    const Curve ease = Curves.ease;
    final Curve flippedEase = ease.flipped;
    expect(flippedEase.transform(0.0), lessThan(0.001));
    expect(flippedEase.transform(0.5), lessThan(ease.transform(0.5)));
    expect(flippedEase.transform(1.0), greaterThan(0.999));
    expect(flippedEase, hasOneLineDescription);
  });

  test('Threshold has a threshold', () {
    const Curve step = Threshold(0.25);
    expect(step.transform(0.0), 0.0);
    expect(step.transform(0.24), 0.0);
    expect(step.transform(0.25), 1.0);
    expect(step.transform(0.26), 1.0);
    expect(step.transform(1.0), 1.0);
  });

  void assertMaximumSlope(Curve curve, double maximumSlope) {
    const double delta = 0.005;
    for (double x = 0.0; x < 1.0 - delta; x += delta) {
      final double deltaY = curve.transform(x) - curve.transform(x + delta);
      assert(deltaY.abs() < delta * maximumSlope, '${curve.toString()} discontinuous at $x');
    }
  }

  test('Curve is continuous', () {
    assertMaximumSlope(Curves.linear, 20.0);
    assertMaximumSlope(Curves.decelerate, 20.0);
    assertMaximumSlope(Curves.bounceIn, 20.0);
    assertMaximumSlope(Curves.bounceOut, 20.0);
    assertMaximumSlope(Curves.bounceInOut, 20.0);
    assertMaximumSlope(Curves.elasticOut, 20.0);
    assertMaximumSlope(Curves.elasticInOut, 20.0);
    assertMaximumSlope(Curves.ease, 20.0);
    assertMaximumSlope(Curves.easeIn, 20.0);
    assertMaximumSlope(Curves.easeOut, 20.0);
    assertMaximumSlope(Curves.easeInOut, 20.0);
    assertMaximumSlope(Curves.fastOutSlowIn, 20.0);
  });

  void expectStaysInBounds(Curve curve) {
    expect(curve.transform(0.0), inInclusiveRange(0.0, 1.0));
    expect(curve.transform(0.1), inInclusiveRange(0.0, 1.0));
    expect(curve.transform(0.2), inInclusiveRange(0.0, 1.0));
    expect(curve.transform(0.3), inInclusiveRange(0.0, 1.0));
    expect(curve.transform(0.4), inInclusiveRange(0.0, 1.0));
    expect(curve.transform(0.5), inInclusiveRange(0.0, 1.0));
    expect(curve.transform(0.6), inInclusiveRange(0.0, 1.0));
    expect(curve.transform(0.7), inInclusiveRange(0.0, 1.0));
    expect(curve.transform(0.8), inInclusiveRange(0.0, 1.0));
    expect(curve.transform(0.9), inInclusiveRange(0.0, 1.0));
    expect(curve.transform(1.0), inInclusiveRange(0.0, 1.0));
  }

  test('Bounce stays in bounds', () {
    expectStaysInBounds(Curves.bounceIn);
    expectStaysInBounds(Curves.bounceOut);
    expectStaysInBounds(Curves.bounceInOut);
  });

  List<double> estimateBounds(Curve curve) {
    final List<double> values = <double>[];

    values.add(curve.transform(0.0));
    values.add(curve.transform(0.1));
    values.add(curve.transform(0.2));
    values.add(curve.transform(0.3));
    values.add(curve.transform(0.4));
    values.add(curve.transform(0.5));
    values.add(curve.transform(0.6));
    values.add(curve.transform(0.7));
    values.add(curve.transform(0.8));
    values.add(curve.transform(0.9));
    values.add(curve.transform(1.0));

    return <double>[
      values.reduce(math.min),
      values.reduce(math.max),
    ];
  }

  test('Ellastic overshoots its bounds', () {
    expect(Curves.elasticIn, hasOneLineDescription);
    expect(Curves.elasticOut, hasOneLineDescription);
    expect(Curves.elasticInOut, hasOneLineDescription);

    List<double> bounds;
    bounds = estimateBounds(Curves.elasticIn);
    expect(bounds[0], lessThan(0.0));
    expect(bounds[1], lessThanOrEqualTo(1.0));
    bounds = estimateBounds(Curves.elasticOut);
    expect(bounds[0], greaterThanOrEqualTo(0.0));
    expect(bounds[1], greaterThan(1.0));
    bounds = estimateBounds(Curves.elasticInOut);
    expect(bounds[0], lessThan(0.0));
    expect(bounds[1], greaterThan(1.0));
  });

  test('Decelerate does so', () {
    expect(Curves.decelerate, hasOneLineDescription);

    final List<double> bounds = estimateBounds(Curves.decelerate);
    expect(bounds[0], greaterThanOrEqualTo(0.0));
    expect(bounds[1], lessThanOrEqualTo(1.0));

    final double d1 = Curves.decelerate.transform(0.2) - Curves.decelerate.transform(0.0);
    final double d2 = Curves.decelerate.transform(1.0) - Curves.decelerate.transform(0.8);
    expect(d2, lessThan(d1));
  });

  test('Invalid transform parameter should assert', () {
    expect(() => const SawTooth(2).transform(-0.0001), throwsAssertionError);
    expect(() => const SawTooth(2).transform(1.0001), throwsAssertionError);

    expect(() => const Interval(0.0, 1.0).transform(-0.0001), throwsAssertionError);
    expect(() => const Interval(0.0, 1.0).transform(1.0001), throwsAssertionError);

    expect(() => const Threshold(0.5).transform(-0.0001), throwsAssertionError);
    expect(() => const Threshold(0.5).transform(1.0001), throwsAssertionError);

    expect(() => const ElasticInCurve().transform(-0.0001), throwsAssertionError);
    expect(() => const ElasticInCurve().transform(1.0001), throwsAssertionError);

    expect(() => const ElasticOutCurve().transform(-0.0001), throwsAssertionError);
    expect(() => const ElasticOutCurve().transform(1.0001), throwsAssertionError);

    expect(() => const Cubic(0.42, 0.0, 0.58, 1.0).transform(-0.0001), throwsAssertionError);
    expect(() => const Cubic(0.42, 0.0, 0.58, 1.0).transform(1.0001), throwsAssertionError);

    expect(() => Curves.decelerate.transform(-0.0001), throwsAssertionError);
    expect(() => Curves.decelerate.transform(1.0001), throwsAssertionError);

    expect(() => Curves.bounceIn.transform(-0.0001), throwsAssertionError);
    expect(() => Curves.bounceIn.transform(1.0001), throwsAssertionError);

    expect(() => Curves.bounceOut.transform(-0.0001), throwsAssertionError);
    expect(() => Curves.bounceOut.transform(1.0001), throwsAssertionError);

    expect(() => Curves.bounceInOut.transform(-0.0001), throwsAssertionError);
    expect(() => Curves.bounceInOut.transform(1.0001), throwsAssertionError);
  });

}
