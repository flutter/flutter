// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import '../common.dart';

const int _kNumIterations = 65536;
const int _kNumWarmUp = 100;
const int _kScale = 1000;

Future<void> execute() async {
  assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");

  final printer = BenchmarkResultPrinter();

  void runNullAspectBenchmark(int iteration, {bool addResult = true}) {
    final modelElement = InheritedModelElement<int>(
      const _BenchmarkInheritedModel(child: SizedBox.shrink()),
    );
    final dependents = List<Element>.generate(
      iteration,
      (_) => SingleChildRenderObjectElement(const SizedBox.shrink()),
      growable: false,
    );

    final watch = Stopwatch()..start();
    for (var i = 0; i < iteration; i += 1) {
      modelElement.updateDependencies(dependents[i], null);
    }
    watch.stop();

    if (addResult) {
      printer.addResult(
        description: 'InheritedModelElement.updateDependencies (null aspect)',
        value: (watch.elapsedMicroseconds / iteration) * _kScale,
        unit: 'ns per iteration',
        name: 'inherited_model_update_dependencies_null_aspect',
      );
    }
  }

  void runExistingAspectSetBenchmark(int iteration, {bool addResult = true}) {
    final modelElement = InheritedModelElement<int>(
      const _BenchmarkInheritedModel(child: SizedBox.shrink()),
    );
    final dependent = SingleChildRenderObjectElement(const SizedBox.shrink());
    modelElement.updateDependencies(dependent, 0);

    final watch = Stopwatch()..start();
    for (var i = 0; i < iteration; i += 1) {
      modelElement.updateDependencies(dependent, i & 3);
    }
    watch.stop();

    if (addResult) {
      printer.addResult(
        description: 'InheritedModelElement.updateDependencies (existing aspect set)',
        value: (watch.elapsedMicroseconds / iteration) * _kScale,
        unit: 'ns per iteration',
        name: 'inherited_model_update_dependencies_existing_set',
      );
    }
  }

  runNullAspectBenchmark(_kNumWarmUp, addResult: false);
  runNullAspectBenchmark(_kNumIterations);

  runExistingAspectSetBenchmark(_kNumWarmUp, addResult: false);
  runExistingAspectSetBenchmark(_kNumIterations);

  printer.printToStdout();
}

class _BenchmarkInheritedModel extends InheritedModel<int> {
  const _BenchmarkInheritedModel({required super.child});

  @override
  bool updateShouldNotify(_BenchmarkInheritedModel oldWidget) => true;

  @override
  bool updateShouldNotifyDependent(_BenchmarkInheritedModel oldWidget, Set<int> dependencies) {
    return dependencies.contains(0);
  }
}
