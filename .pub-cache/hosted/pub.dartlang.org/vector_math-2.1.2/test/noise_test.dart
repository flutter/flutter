// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';

void testSimplexNoise() {
  final noise = SimplexNoise();

  final values2D = List<double>.filled(10, 0);
  final values3D = List<double>.filled(10, 0);

  // Cache several values at known coordinates
  for (var i = 0; i < values2D.length; ++i) {
    values2D[i] = noise.noise2D(i.toDouble(), i.toDouble());
    values3D[i] = noise.noise3D(i.toDouble(), i.toDouble(), i.toDouble());
  }

  // Ensure that querying those same coordinates repeats the cached value
  for (var i = 0; i < values2D.length; ++i) {
    expect(values2D[i], equals(noise.noise2D(i.toDouble(), i.toDouble())));
    expect(values3D[i],
        equals(noise.noise3D(i.toDouble(), i.toDouble(), i.toDouble())));
  }
}

void main() {
  group('Noise', () {
    test('Simplex Noise', testSimplexNoise);
  });
}
