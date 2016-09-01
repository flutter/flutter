// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'framework.dart';

/// A benchmark harness used to run a benchmark multiple times and report the
/// best result.
abstract class Benchmark {
  Benchmark(this.name);

  final String name;

  TaskResult bestResult;

  Future<Null> init() => new Future<Null>.value();

  Future<num> run();
  TaskResult get lastResult;

  @override
  String toString() => name;
}

/// Runs a [benchmark] [iterations] times and reports the best result.
///
/// Use [warmUpBenchmark] to discard cold performance results.
Future<num> runBenchmark(Benchmark benchmark, {
  int iterations: 1,
  bool warmUpBenchmark: false
}) async {
  await benchmark.init();

  List<num> allRuns = <num>[];

  num minValue;

  if (warmUpBenchmark)
    await benchmark.run();

  while (iterations > 0) {
    iterations--;

    print('');

    try {
      num result = await benchmark.run();
      allRuns.add(result);

      if (minValue == null || result < minValue) {
        benchmark.bestResult = benchmark.lastResult;
        minValue = result;
      }
    } catch (error) {
      print('benchmark failed with error: $error');
    }
  }

  return minValue;
}
