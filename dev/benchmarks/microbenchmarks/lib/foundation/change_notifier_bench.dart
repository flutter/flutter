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

  void listener() {}
  void listener2() {}
  void listener3() {}
  void listener4() {}
  void listener5() {}

  // Warm up lap
  for (int i = 0; i < _kNumWarmUp; i += 1) {
    _Notifier()
      ..addListener(listener)
      ..addListener(listener2)
      ..addListener(listener3)
      ..addListener(listener4)
      ..addListener(listener5)
      ..notify()
      ..removeListener(listener)
      ..removeListener(listener2)
      ..removeListener(listener3)
      ..removeListener(listener4)
      ..removeListener(listener5);
  }

  final Stopwatch addListenerWatch = Stopwatch();
  final Stopwatch removeListenerWatch = Stopwatch();
  final Stopwatch notifyListenersWatch = Stopwatch();
  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();

  for (int listenersCount = 0; listenersCount <= 5; listenersCount++) {

    for (int j = 0; j < _kNumIterations; j += 1) {
      final _Notifier notifier = _Notifier();
      addListenerWatch.start();

      notifier.addListener(listener);
      if (listenersCount > 1)
        notifier.addListener(listener2);
      if (listenersCount > 2)
        notifier.addListener(listener3);
      if (listenersCount > 3)
        notifier.addListener(listener4);
      if (listenersCount > 4)
        notifier.addListener(listener5);

      addListenerWatch.stop();
      notifyListenersWatch.start();

      notifier.notify();

      notifyListenersWatch.stop();
      removeListenerWatch.start();

      // Remove listeners in reverse order to evaluate the worse-case scenario:
      // the listener removed is the last listener
      if (listenersCount > 4)
        notifier.removeListener(listener5);
      if (listenersCount > 3)
        notifier.removeListener(listener4);
      if (listenersCount > 2)
        notifier.removeListener(listener3);
      if (listenersCount > 1)
        notifier.removeListener(listener2);
      notifier.removeListener(listener);

      removeListenerWatch.stop();
    }

    final int notifyListener = notifyListenersWatch.elapsedMicroseconds;
    notifyListenersWatch.reset();
    final int addListenerElapsed = addListenerWatch.elapsedMicroseconds;
    addListenerWatch.reset();
    final int removeListenerElapsed = removeListenerWatch.elapsedMicroseconds;
    removeListenerWatch.reset();

    printer.addResult(
      description: 'addListener ($listenersCount listeners)',
      value: addListenerElapsed * _scale,
      unit: 'ns per iteration',
      name: 'addListener${listenersCount}_iteration',
    );

    printer.addResult(
      description: 'removeListener ($listenersCount listeners)',
      value: removeListenerElapsed * _scale,
      unit: 'ns per iteration',
      name: 'removeListener${listenersCount}_iteration',
    );

    printer.addResult(
      description: 'notifyListener ($listenersCount listeners)',
      value: notifyListener * _scale,
      unit: 'ns per iteration',
      name: 'notifyListener${listenersCount}_iteration',
    );
  }

  printer.printToStdout();
}

class _Notifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
