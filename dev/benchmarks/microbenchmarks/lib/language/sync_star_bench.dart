// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../common.dart';

const int _kNumIterations = 1000;
const int _kNumWarmUp = 100;

Future<void> execute() async {
  assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");

  // Warm up lap
  for (var i = 0; i < _kNumWarmUp; i += 1) {
    sumIterable(generateIterableSyncStar());
    sumIterable(generateIterableList());
    sumIterable(Iterable<int>.generate(100, generate));
  }

  final watch = Stopwatch();
  watch.start();
  for (var i = 0; i < _kNumIterations; i += 1) {
    sumIterable(generateIterableSyncStar());
  }
  final int traverseIterableSyncStar = watch.elapsedMicroseconds;
  watch
    ..reset()
    ..start();
  for (var i = 0; i < _kNumIterations; i += 1) {
    sumIterable(generateIterableList());
  }
  final int traverseIterableList = watch.elapsedMicroseconds;
  watch
    ..reset()
    ..start();
  for (var i = 0; i < _kNumIterations; i += 1) {
    sumIterable(Iterable<int>.generate(100, generate));
  }
  final int traverseIterableGenerated = watch.elapsedMicroseconds;
  watch
    ..reset()
    ..start();

  final printer = BenchmarkResultPrinter();
  const double scale = 1000.0 / _kNumIterations;
  printer.addResult(
    description: 'traverseIterableSyncStar',
    value: traverseIterableSyncStar * scale,
    unit: 'ns per iteration',
    name: 'traverseIterableSyncStar_iteration',
  );
  printer.addResult(
    description: 'traverseIterableList',
    value: traverseIterableList * scale,
    unit: 'ns per iteration',
    name: 'traverseIterableList_iteration',
  );
  printer.addResult(
    description: 'traverseIterableGenerated',
    value: traverseIterableGenerated * scale,
    unit: 'ns per iteration',
    name: 'traverseIterableGenerated_iteration',
  );
  printer.printToStdout();
}

int generate(int index) => index;

// Generate an Iterable using a sync* method.
Iterable<int> generateIterableSyncStar() sync* {
  for (var i = 0; i < 100; i++) {
    yield i;
  }
}

// Generate an Iterable using a List.
Iterable<int> generateIterableList() {
  final items = <int>[];
  for (var i = 0; i < 100; i++) {
    items.add(i);
  }
  return items;
}

int sumIterable(Iterable<int> values) {
  var result = 0;
  for (final value in values) {
    result += value;
  }
  return result;
}

//
//  Note that the benchmark is normally run by benchmark_collection.dart.
//
Future<void> main() async {
  return execute();
}
