// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../common.dart';

const int _kNumIterations = 1000;
const double _scale = 1000.0 / _kNumIterations;
const int _kNumWarmUp = 100;

void main() {
  assert(false, "Don't run benchmarks in checked mode! Use 'flutter run --release'.");

  // Warm up lap
  for (int i = 0; i < _kNumWarmUp; i += 1) {
    _Notifier().notify();
    _Notifier()
      ..addListeners(1)
      ..notify();
    _Notifier()
      ..addListeners(2)
      ..notify();
    _Notifier()
      ..addListeners(3)
      ..notify();
    _Notifier()
      ..addListeners(4)
      ..notify();
  }

  final Stopwatch watch = Stopwatch();
  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();

  for (int i = 0; i <= 5; i++) {
    final _Notifier notifier = _Notifier()..addListeners(i);

    watch.start();
    for (int i = 0; i < _kNumIterations; i += 1) {
      notifier.notify();
    }
    final int notifyListener = watch.elapsedMicroseconds;
    watch.reset();

    printer.addResult(
      description: 'notifyListener ($i listeners)',
      value: notifyListener * _scale,
      unit: 'ns per iteration',
      name: 'notifyListener${i}_iteration',
    );
  }

  printer.printToStdout();
}

class _Notifier extends ChangeNotifier {
  void notify() => notifyListeners();

  void addListeners(int listenersCount) {
    for (int i = 0; i < listenersCount; i++) {
      addListener(() {});
    }
  }
}
