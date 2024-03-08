// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/basic_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lerp Duration', () {
    test('linearly interpolates between positive Durations', () {
      expect(
        lerpDuration(const Duration(seconds: 1), const Duration(seconds: 2), 0.5),
        const Duration(milliseconds: 1500),
      );
    });

    test('linearly interpolates between negative Durations', () {
      expect(
        lerpDuration(const Duration(seconds: -1), const Duration(seconds: -2), 0.5),
        const Duration(milliseconds: -1500),
      );
    });

    test('linearly interpolates between positive and negative Durations', () {
      expect(
        lerpDuration(const Duration(seconds: -1), const Duration(seconds:2), 0.5),
        const Duration(milliseconds: 500),
      );
    });

    test('starts at first Duration', () {
      expect(
        lerpDuration(const Duration(seconds: 1), const Duration(seconds: 2), 0),
        const Duration(seconds: 1),
      );
    });

    test('ends at second Duration', () {
      expect(
        lerpDuration(const Duration(seconds: 1), const Duration(seconds: 2), 1),
        const Duration(seconds: 2),
      );
    });

    test('time values beyond 1.0 have a multiplier effect', () {
      expect(
        lerpDuration(const Duration(seconds: 1), const Duration(seconds: 2), 5),
        const Duration(seconds: 6),
      );

      expect(
        lerpDuration(const Duration(seconds: -1), const Duration(seconds: -2), 5),
        const Duration(seconds: -6),
      );
    });
  });

  group('Either', () {
    test('toString', () {
      expect(const Left<int, double>(1).toString(), 'Left<int, double>(1)');
      expect(const Right<int, bool>(true).toString(), 'Right<int, bool>(true)');
    });

    test('Equality', () {
      expect(const Left<int, double>(1) == const Left<int, double>(1), isTrue);
      expect(Left<int, double>(1) == Left<int, double>(1), isTrue); // ignore: prefer_const_constructors

      expect(const Left<int, double>(1) == const Left<int, Never>(1), isTrue);
      expect(const Left<int, Never>(1) == const Left<int, double>(1), isTrue);
    });

  });
}
