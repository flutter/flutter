// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testDegrees() {
  relativeTest(degrees(math.pi), 180.0);
}

void testRadians() {
  relativeTest(radians(90.0), math.pi / 2.0);
}

void testMix() {
  relativeTest(mix(2.5, 3.0, 1.0), 3.0);
  relativeTest(mix(1.0, 3.0, 0.5), 2.0);
  relativeTest(mix(2.5, 3.0, 0.0), 2.5);
  relativeTest(mix(-1.0, 0.0, 2.0), 1.0);
}

void testSmoothStep() {
  relativeTest(smoothStep(2.5, 3.0, 2.5), 0.0);
  relativeTest(smoothStep(2.5, 3.0, 2.75), 0.5);
  relativeTest(smoothStep(2.5, 3.0, 3.5), 1.0);
}

void testCatmullRom() {
  relativeTest(catmullRom(2.5, 3.0, 1.0, 3.0, 1.0), 1.0);
  relativeTest(catmullRom(1.0, 3.0, 1.0, 3.0, 0.5), 2.0);
  relativeTest(catmullRom(2.5, 3.0, 1.0, 3.0, 0.0), 3.0);
  relativeTest(catmullRom(-1.0, 0.0, 1.0, 0.0, 2.0), -2.0);
}

void main() {
  group('Utilities', () {
    test('degrees', testDegrees);
    test('radians', testRadians);
    test('mix', testMix);
    test('smoothStep', testSmoothStep);
    test('catmullRom', testCatmullRom);
  });
}
