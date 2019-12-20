// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';
import 'package:flutter/animation.dart';

import '../common.dart';

const int _kNumIters = 10000;

void main() {
  assert(false, "Don't run benchmarks in checked mode! Use 'flutter run --release'.");
  final Stopwatch watch = Stopwatch();
  print('Cubic animation transform benchmark...');
  const Cubic curve = Cubic(0.0, 0.25, 0.5, 1.0);
  watch.start();
  for (int i = 0; i < _kNumIters; i += 1) {
    final double t = i / _kNumIters.toDouble();
    curve.transform(t);
  }
  watch.stop();

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  printer.addResult(
    description: 'Cubic animation transform',
    value: watch.elapsedMicroseconds / _kNumIters,
    unit: 'µs per iteration',
    name: 'cubic_animation_transform_iteration',
  );

  print('CatmullRomCurve animation transform benchmark...');
  final CatmullRomCurve catmullRomCurve = CatmullRomCurve(const <Offset>[
    Offset(0.09, 0.99),
    Offset(0.21, 0.01),
    Offset(0.28, 0.99),
    Offset(0.38, -0.00),
    Offset(0.43, 0.99),
    Offset(0.54, -0.01),
    Offset(0.59, 0.98),
    Offset(0.70, 0.04),
    Offset(0.78, 0.98),
    Offset(0.88, -0.00),
  ], tension: 0.00);
  watch.start();
  for (int i = 0; i < _kNumIters; i += 1) {
    final double t = i / _kNumIters.toDouble();
    catmullRomCurve.transform(t);
  }
  watch.stop();

  printer.addResult(
    description: 'CatmullRomCurve animation transform',
    value: watch.elapsedMicroseconds / _kNumIters,
    unit: 'µs per iteration',
    name: 'catmullrom_transform_iteration',
  );
  printer.printToStdout();
}
