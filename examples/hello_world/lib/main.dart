// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/test_simd.dart';

var runs = 10000;
var results = <String, List<num>>{};

void main() async {
  print('waiting to start...');
  await Future<void>.delayed(const Duration(seconds: 10));
  for (var j = 0; j < 100; j++) {
  {
    Stopwatch sw = Stopwatch()..start();
    Matrix4 vmIdentity = Matrix4.identity();
    for (int i = 0; i < runs; i++) {
      vmIdentity.copyInverse(Matrix4.identity());
    }
    sw.stop();
    results['vector_math_invert'] ??= <num>[];
    results['vector_math_invert'].add(sw.elapsedMicroseconds);
  }

  {
    Stopwatch sw = Stopwatch()..start();
    Matrix4 vmIdentity = Matrix4.identity();
    for (int i = 0; i < runs; i++) {
      vmIdentity = vmIdentity.multiplied(vmIdentity);
    }
    sw.stop();
    results['vector_math_mult'] ??= <num>[];
    results['vector_math_mult'].add(sw.elapsedMicroseconds);
  }

  {
    Stopwatch sw = Stopwatch()..start();
    Matrix4 vmIdentity = Matrix4.identity();
    Matrix4 vmIdentityOther = Matrix4.identity();
    bool vmResult = false;
    for (int i = 0; i < runs; i++) {
      vmResult = MatrixUtils.matrixEquals(vmIdentity, vmIdentityOther);
    }
    sw.stop();
    results['vector_math_matrix_equals'] ??= <num>[];
    results['vector_math_matrix_equals'].add(sw.elapsedMicroseconds);
  }

  {
    Stopwatch sw = Stopwatch()..start();
    Matrix4 vmIdentity = Matrix4.identity();
    Offset offset = Offset(2, 3);
    for (int i = 0; i < runs; i++) {
      offset = MatrixUtils.transformPoint(vmIdentity, offset);
    }
    sw.stop();
    results['vector_math_transform_point'] ??= <num>[];
    results['vector_math_transform_point'].add(sw.elapsedMicroseconds);
  }

  {
    Stopwatch sw = Stopwatch()..start();
    SimdMatrix4 simdMatrix4 = SimdMatrix4.identity;
    for (int i = 0; i < runs; i++) {
      simdMatrix4 = simdMatrix4.invert();
    }
    sw.stop();
    results['simd_matrix_invert'] ??= <num>[];
    results['simd_matrix_invert'].add(sw.elapsedMicroseconds);
  }

  {
    Stopwatch sw = Stopwatch()..start();
    SimdMatrix4 simdMatrix4 = SimdMatrix4.identity;
    for (int i = 0; i < runs; i++) {
      simdMatrix4 = simdMatrix4 * simdMatrix4;
    }
    sw.stop();
    results['simd_matrix_mult'] ??= <num>[];
    results['simd_matrix_mult']?.add(sw.elapsedMicroseconds);
  }

  {
    Stopwatch sw = Stopwatch()..start();
    SimdMatrix4 simdMatrix4 = SimdMatrix4.identity;
    SimdMatrix4 simdMatrix4Other = SimdMatrix4.identity;
    bool result = false;
    for (int i = 0; i < runs; i++) {
      result = SimdMatrixUtils.matrixEquals(simdMatrix4, simdMatrix4Other);
    }
    sw.stop();
    results['simd_matrix_equals'] ??= <num>[];
    results['simd_matrix_equals'].add(sw.elapsedMicroseconds);
  }

  {
    Stopwatch sw = Stopwatch()..start();
    SimdMatrix4 simdMatrix4 = SimdMatrix4.identity;
    Offset offset = Offset(2, 3);
    for (int i = 0; i < runs; i++) {
      offset = SimdMatrixUtils.transformPoint(simdMatrix4, offset);
    }
    sw.stop();
    results['simd_transform_point'] ??= <num>[];
    results['simd_transform_point'].add(sw.elapsedMicroseconds);
  }
  }
  for (String key in results.keys) {
    print(key);
    print(results[key]);
  }
}
