// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('When snapToEnd is set, value is exactly `end` after completion', () {
    final description = SpringDescription.withDampingRatio(mass: 1.0, stiffness: 400);
    const time = 0.4;

    final regularSimulation = SpringSimulation(
      description,
      0,
      1,
      0,
      tolerance: const Tolerance(distance: 0.1, velocity: 0.1),
    );
    expect(regularSimulation.x(time), lessThan(1));
    expect(regularSimulation.dx(time), greaterThan(0));

    final snappingSimulation = SpringSimulation(
      description,
      0,
      1,
      0,
      snapToEnd: true,
      tolerance: const Tolerance(distance: 0.1, velocity: 0.1),
    );
    // Must be exactly equal
    expect(snappingSimulation.x(time), 1);
    expect(snappingSimulation.dx(time), 0);
  });

  test('SpringSimulation results are continuous near critical damping', () {
    // Regression test for https://github.com/flutter/flutter/issues/163858
    const time = 0.4;
    const stiffness = 0.4;
    const mass = 0.4;
    final critical = SpringSimulation(
      SpringDescription.withDampingRatio(stiffness: stiffness, mass: mass),
      0,
      1,
      0,
    );
    expect(critical.x(time), moreOrLessEquals(0.06155, epsilon: 0.01));
    expect(critical.dx(time), moreOrLessEquals(0.2681, epsilon: 0.01));

    final slightlyOver = SpringSimulation(
      SpringDescription.withDampingRatio(stiffness: stiffness, mass: mass, ratio: 1 + 1e-3),
      0,
      1,
      0,
    );
    expect(slightlyOver.x(time), moreOrLessEquals(0.06155, epsilon: 0.01));
    expect(slightlyOver.dx(time), moreOrLessEquals(0.2681, epsilon: 0.01));

    final slightlyUnder = SpringSimulation(
      SpringDescription.withDampingRatio(stiffness: stiffness, mass: mass, ratio: 1 - 1e-3),
      0,
      1,
      0,
    );
    expect(slightlyUnder.x(time), moreOrLessEquals(0.06155, epsilon: 0.01));
    expect(slightlyUnder.dx(time), moreOrLessEquals(0.2681, epsilon: 0.01));
  });

  group('SpringDescription.withDurationAndBounce', () {
    test('creates spring with expected results', () {
      final spring = SpringDescription.withDurationAndBounce(bounce: 0.3);

      expect(spring.mass, equals(1.0));
      expect(spring.stiffness, moreOrLessEquals(157.91, epsilon: 0.01));
      expect(spring.damping, moreOrLessEquals(17.59, epsilon: 0.01));

      // Verify that getters recalculate correctly
      expect(spring.bounce, moreOrLessEquals(0.3, epsilon: 0.0001));
      expect(spring.duration.inMilliseconds, equals(500));
    });

    test('creates spring with negative bounce', () {
      final spring = SpringDescription.withDurationAndBounce(bounce: -0.3);

      expect(spring.mass, equals(1.0));
      expect(spring.stiffness, moreOrLessEquals(157.91, epsilon: 0.01));
      expect(spring.damping, moreOrLessEquals(35.90, epsilon: 0.01));

      // Verify that getters recalculate correctly
      expect(spring.bounce, moreOrLessEquals(-0.3, epsilon: 0.0001));
      expect(spring.duration.inMilliseconds, equals(500));
    });

    test('get duration and bounce based on mass and stiffness', () {
      const spring = SpringDescription(mass: 1.0, stiffness: 157.91, damping: 17.59);

      expect(spring.bounce, moreOrLessEquals(0.3, epsilon: 0.001));
      expect(spring.duration.inMilliseconds, equals(500));
    });

    test('custom duration', () {
      final spring = SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 100),
      );

      expect(spring.mass, equals(1.0));
      expect(spring.stiffness, moreOrLessEquals(3947.84, epsilon: 0.01));
      expect(spring.damping, moreOrLessEquals(125.66, epsilon: 0.01));

      expect(spring.bounce, moreOrLessEquals(0, epsilon: 0.001));
      expect(spring.duration.inMilliseconds, equals(100));
    });

    test('duration <= 0 should fail', () {
      expect(
        () => SpringDescription.withDurationAndBounce(
          duration: const Duration(seconds: -1),
          bounce: 0.3,
        ),
        throwsA(isAssertionError),
      );

      expect(
        () => SpringDescription.withDurationAndBounce(duration: Duration.zero, bounce: 0.3),
        throwsA(isAssertionError),
      );
    });
  });
}
