// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show clampDouble;

import '../common.dart';

const int _kNumIterations = 1000000;

void main() {
  assert(false,
      "Don't run benchmarks in checked mode! Use 'flutter run --release'.");
  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();

  final Stopwatch watch = Stopwatch();
  double tally = 0;
  watch.start();
  for (int i = 0; i < _kNumIterations; i += 1) {
    tally += clampDouble(-1.0, 0.0, 1.0);
    tally += clampDouble(2.0, 0.0, 1.0);
    tally += clampDouble(0.0, 0.0, 1.0);
    tally += clampDouble(double.nan, 0.0, 1.0);
  }
  watch.stop();

  printer.addResult(
    description: 'clamp - clampDouble',
    value: watch.elapsedMicroseconds.toDouble() / _kNumIterations,
    unit: 'us per iteration',
    name: 'clamp_clampDouble',
  );

  watch.reset();
  watch.start();
  for (int i = 0; i < _kNumIterations; i += 1) {
    tally += -1.0.clamp(0.0, 1.0);
    tally += 2.0.clamp(0.0, 1.0);
    tally += 0.0.clamp(0.0, 1.0);
    tally += double.nan.clamp(0.0, 1.0);
  }
  watch.stop();

  printer.addResult(
    description: 'clamp - Double.clamp',
    value: watch.elapsedMicroseconds.toDouble() / _kNumIterations,
    unit: 'us per iteration',
    name: 'clamp_Double_clamp',
  );

  printer.printToStdout();
}
