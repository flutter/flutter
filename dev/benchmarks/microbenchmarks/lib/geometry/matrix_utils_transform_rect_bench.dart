// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';

import '../common.dart';

const int _kNumIters = 10000;

void main() {
  assert(false, "Don't run benchmarks in checked mode! Use 'flutter run --release'.");
  print('MatrixUtils.transformRect benchmark...');

  final Matrix4 transform = Matrix4.zero()
    ..scale(1.2, 1.3, 1.0)
    ..rotateZ(0.1);

  final List<Rect> _rects = List.generate(_kNumIters, (int i ) {
    return Rect.fromLTRB(i * 1.1, i * 1.2, i * 1.5, i * 1.8);
  });

  final Stopwatch watch = Stopwatch();
  watch.start();
  for (int i = 0; i < _kNumIters; i += 1) {
    final Rect rect = _rects[i];
    MatrixUtils.transformRect(transform, rect);
  }
  watch.stop();

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  printer.addResult(
    description: 'MatrixUtils.transformRect',
    value: watch.elapsedMicroseconds / _kNumIters,
    unit: 'µs per iteration',
    name: 'MatrixUtils_transformRect_iteration',
  );
  printer.printToStdout();
}
