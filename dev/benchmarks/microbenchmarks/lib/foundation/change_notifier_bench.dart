// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../common.dart';

const int _kNumIterations = 1000;
const double _scale = 1000.0 / _kNumIterations;
const int _kNumWarmUp = 100;

void _listener() {}
void _listener2() {}
void _listener3() {}
void _listener4() {}
void _listener5() {}

const List<VoidCallback> _allListeners = <VoidCallback>[
  _listener,
  _listener2,
  _listener3,
  _listener4,
  _listener5,
];

void main() {
  assert(false, "Don't run benchmarks in checked mode! Use 'flutter run --release'.");

  // Warm up lap
  for (int i = 0; i < _kNumWarmUp; i += 1) {
    _Notifier()
      ..addListener(_listener)
      ..addListener(_listener2)
      ..addListener(_listener3)
      ..addListener(_listener4)
      ..addListener(_listener5)
      ..notify()
      ..removeListener(_listener)
      ..removeListener(_listener2)
      ..removeListener(_listener3)
      ..removeListener(_listener4)
      ..removeListener(_listener5);
  }

  final Stopwatch addListenerWatch = Stopwatch();
  final Stopwatch removeListenerWatch = Stopwatch();
  final Stopwatch removeListenerWhileNotifyingWatch = Stopwatch();
  final Stopwatch notifyListenersWatch = Stopwatch();
  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();

  for (int listenersCount = 0; listenersCount <= 5; listenersCount++) {

    for (int j = 0; j < _kNumIterations; j += 1) {
      final _Notifier notifier = _Notifier();

      addListenerWatch.start();
      for (int l = 0; l < listenersCount; l++) {
        notifier.addListener(_allListeners[l]);
      }
      addListenerWatch.stop();

      notifyListenersWatch.start();
      notifier.notify();
      notifyListenersWatch.stop();

      removeListenerWatch.start();
      // Remove listeners in reverse order to evaluate the worse-case scenario:
      // the listener removed is the last listener
      for (int l = listenersCount - 1; l >= 0; l--) {
        notifier.removeListener(_allListeners[l]);
      }
      removeListenerWatch.stop();
    }

    final int notifyListener = notifyListenersWatch.elapsedMicroseconds;
    notifyListenersWatch.reset();
    final int addListenerElapsed = addListenerWatch.elapsedMicroseconds;
    addListenerWatch.reset();
    final int removeListenerElapsed = removeListenerWatch.elapsedMicroseconds;
    removeListenerWatch.reset();

    // Special iteration for benchmarking the removing of listeners during the
    // call to notifyListeners.
    for (int j = 0; j < _kNumIterations; j += 1) {
      final _Notifier notifier = _Notifier();

      for (int l = 0; l < listenersCount; l++) {
        notifier.addListener(_allListeners[l]);
      }

      notifier.addListener(() {
        for (int l = listenersCount - 1; l >= 0; l--) {
          notifier.removeListener(_allListeners[l]);
        }
      });

      removeListenerWhileNotifyingWatch.start();
      notifier.notify();
      removeListenerWhileNotifyingWatch.stop();
    }

    final int removeListenerWhileNotifyingElapsed = removeListenerWhileNotifyingWatch.elapsedMicroseconds;
    removeListenerWhileNotifyingWatch.reset();

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
      description: 'removeListenerWhileNotifying ($listenersCount listeners)',
      value: removeListenerWhileNotifyingElapsed * _scale,
      unit: 'ns per iteration',
      name: 'removeListenerWhileNotifying${listenersCount}_iteration',
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
