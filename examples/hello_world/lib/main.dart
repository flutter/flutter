// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/widgets.dart';

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
      vmIdentity = vmIdentity.multiplied(vmIdentity);
    }
    sw.stop();
    results['vector_math_mult'] ??= <num>[];
    results['vector_math_mult']?.add(sw.elapsedMicroseconds);
  }

  {
    Stopwatch sw = Stopwatch()..start();
    Matrix4 simdMatrix4 = Matrix4.identity();
    for (int i = 0; i < runs; i++) {
      simdMatrix4 = MatrixUtils.multiplied(simdMatrix4, simdMatrix4);
    }
    sw.stop();
    results['simd_matrix_mult'] ??= <num>[];
    results['simd_matrix_mult']?.add(sw.elapsedMicroseconds);
  }

  {
    Stopwatch sw = Stopwatch()..start();
    Float32List simdMatrix4 = Float32List.fromList(Matrix4.identity().storage.toList());
    for (int i = 0; i < runs; i++) {
      simdMatrix4 = MatrixUtils.multiplied32(simdMatrix4, simdMatrix4);
    }
    sw.stop();
    results['simd_matrix_mult_32'] ??= <num>[];
    results['simd_matrix_mult_32']?.add(sw.elapsedMicroseconds);
  }

  }
  for (String key in results.keys) {
    print(key);
    print(results[key]);
  }
}
