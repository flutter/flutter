// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common.dart';

const int _kNumIterations = 10000;
const int _kNumWarmUp = 100;
const int _kScale = 1000;

/// Benchmark to measure the performance impact of the dependency cleanup feature.
///
/// This benchmark measures:
/// 1. The cost of inserting dependencies into the hashmap during `dependOnInheritedElement`
/// 2. The cost of computing set difference in `ComponentElement.performRebuild`
/// 3. The overall overhead when no cleanup is needed vs when cleanup occurs
///
/// The goal is to ensure that the cleanup mechanism adds minimal overhead when
/// widgets don't need cleaning up (the common case).
Future<void> execute() async {
  assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");

  final printer = BenchmarkResultPrinter();

  // Run benchmarks
  await _runNoDependenciesBenchmark(printer);
  await _runDependenciesNoCleanupBenchmark(printer);
  await _runDependenciesWithCleanupEnabledBenchmark(printer);
  await _runDependenciesWithActualCleanupBenchmark(printer);
  await _runManyDependenciesBenchmark(printer);

  printer.printToStdout();
}

/// Measures baseline rebuild time with no inherited dependencies.
Future<void> _runNoDependenciesBenchmark(BenchmarkResultPrinter printer) async {
  await benchmarkWidgets((WidgetTester tester) async {
    final rebuildTrigger = ValueNotifier<int>(0);

    await tester.pumpWidget(_NoDependenciesWidget(rebuildTrigger: rebuildTrigger));

    // Warm up
    for (var i = 0; i < _kNumWarmUp; i++) {
      rebuildTrigger.value++;
      await tester.pump();
    }

    final watch = Stopwatch()..start();
    for (var i = 0; i < _kNumIterations; i++) {
      rebuildTrigger.value++;
      await tester.pump();
    }
    watch.stop();

    final double averagePerIteration = watch.elapsedMicroseconds / _kNumIterations;
    printer.addResult(
      description: 'Rebuild (no dependencies)',
      value: averagePerIteration * _kScale,
      unit: 'ns per iteration',
      name: 'rebuild_no_deps',
    );
  });
}

/// Measures rebuild time with inherited dependencies (cleanupUnusedDependents = false).
Future<void> _runDependenciesNoCleanupBenchmark(BenchmarkResultPrinter printer) async {
  for (final depCount in <int>[1, 5, 10]) {
    await benchmarkWidgets((WidgetTester tester) async {
      final rebuildTrigger = ValueNotifier<int>(0);

      await tester.pumpWidget(
        _buildInheritedStack(
          depth: depCount,
          cleanupEnabled: false,
          child: _DependentWidget(
            rebuildTrigger: rebuildTrigger,
            dependencyCount: depCount,
            cleanupEnabled: false,
          ),
        ),
      );

      // Warm up
      for (var i = 0; i < _kNumWarmUp; i++) {
        rebuildTrigger.value++;
        await tester.pump();
      }

      final watch = Stopwatch()..start();
      for (var i = 0; i < _kNumIterations; i++) {
        rebuildTrigger.value++;
        await tester.pump();
      }
      watch.stop();

      final double averagePerIteration = watch.elapsedMicroseconds / _kNumIterations;
      printer.addResult(
        description: 'Rebuild ($depCount deps, no cleanup)',
        value: averagePerIteration * _kScale,
        unit: 'ns per iteration',
        name: 'rebuild_${depCount}deps_no_cleanup',
      );
    });
  }
}

/// Measures rebuild time with inherited dependencies (cleanupUnusedDependents = true)
/// but all dependencies are still used (no actual cleanup needed).
Future<void> _runDependenciesWithCleanupEnabledBenchmark(BenchmarkResultPrinter printer) async {
  for (final depCount in <int>[1, 5, 10]) {
    await benchmarkWidgets((WidgetTester tester) async {
      final rebuildTrigger = ValueNotifier<int>(0);

      await tester.pumpWidget(
        _buildInheritedStack(
          depth: depCount,
          cleanupEnabled: true,
          child: _DependentWidget(
            rebuildTrigger: rebuildTrigger,
            dependencyCount: depCount,
            cleanupEnabled: true,
          ),
        ),
      );

      // Warm up
      for (var i = 0; i < _kNumWarmUp; i++) {
        rebuildTrigger.value++;
        await tester.pump();
      }

      final watch = Stopwatch()..start();
      for (var i = 0; i < _kNumIterations; i++) {
        rebuildTrigger.value++;
        await tester.pump();
      }
      watch.stop();

      final double averagePerIteration = watch.elapsedMicroseconds / _kNumIterations;
      printer.addResult(
        description: 'Rebuild ($depCount deps, cleanup enabled)',
        value: averagePerIteration * _kScale,
        unit: 'ns per iteration',
        name: 'rebuild_${depCount}deps_cleanup_enabled',
      );
    });
  }
}

/// Measures rebuild time when dependencies actually need to be cleaned up.
/// Half the dependencies are used on odd rebuilds, creating cleanup work.
Future<void> _runDependenciesWithActualCleanupBenchmark(BenchmarkResultPrinter printer) async {
  for (final depCount in <int>[2, 6, 10]) {
    await benchmarkWidgets((WidgetTester tester) async {
      final rebuildTrigger = ValueNotifier<int>(0);

      await tester.pumpWidget(
        _buildInheritedStack(
          depth: depCount,
          cleanupEnabled: true,
          child: _ConditionalDependentWidget(
            rebuildTrigger: rebuildTrigger,
            totalDependencies: depCount,
          ),
        ),
      );

      // Warm up
      for (var i = 0; i < _kNumWarmUp; i++) {
        rebuildTrigger.value++;
        await tester.pump();
      }

      final watch = Stopwatch()..start();
      for (var i = 0; i < _kNumIterations; i++) {
        rebuildTrigger.value++;
        await tester.pump();
      }
      watch.stop();

      final double averagePerIteration = watch.elapsedMicroseconds / _kNumIterations;
      printer.addResult(
        description: 'Rebuild ($depCount deps, actual cleanup)',
        value: averagePerIteration * _kScale,
        unit: 'ns per iteration',
        name: 'rebuild_${depCount}deps_actual_cleanup',
      );
    });
  }
}

/// Measures rebuild time with a large number of dependencies to stress test.
Future<void> _runManyDependenciesBenchmark(BenchmarkResultPrinter printer) async {
  for (final depCount in <int>[50, 100, 500, 1000]) {
    await benchmarkWidgets((WidgetTester tester) async {
      final rebuildTrigger = ValueNotifier<int>(0);

      await tester.pumpWidget(
        _buildInheritedStack(
          depth: depCount,
          cleanupEnabled: true,
          child: _DependentWidget(
            rebuildTrigger: rebuildTrigger,
            dependencyCount: depCount,
            cleanupEnabled: true,
          ),
        ),
      );

      // Warm up (fewer iterations for large dep counts)
      for (var i = 0; i < 10; i++) {
        rebuildTrigger.value++;
        await tester.pump();
      }

      // Fewer iterations for stress test
      const iterations = 1000;
      final watch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        rebuildTrigger.value++;
        await tester.pump();
      }
      watch.stop();

      final double averagePerIteration = watch.elapsedMicroseconds / iterations;
      printer.addResult(
        description: 'Rebuild ($depCount deps, stress test)',
        value: averagePerIteration * _kScale,
        unit: 'ns per iteration',
        name: 'rebuild_${depCount}deps_stress',
      );
    });
  }
}

/// Builds a nested stack of InheritedWidgets.
Widget _buildInheritedStack({
  required int depth,
  required bool cleanupEnabled,
  required Widget child,
}) {
  var result = child;
  for (int i = depth - 1; i >= 0; i--) {
    if (cleanupEnabled) {
      result = _CleanupInheritedWidget(index: i, child: result);
    } else {
      result = _NoCleanupInheritedWidget(index: i, child: result);
    }
  }
  return Directionality(textDirection: TextDirection.ltr, child: result);
}

/// A widget with no inherited dependencies for baseline measurement.
class _NoDependenciesWidget extends StatefulWidget {
  const _NoDependenciesWidget({required this.rebuildTrigger});

  final ValueNotifier<int> rebuildTrigger;

  @override
  State<_NoDependenciesWidget> createState() => _NoDependenciesWidgetState();
}

class _NoDependenciesWidgetState extends State<_NoDependenciesWidget> {
  @override
  void initState() {
    super.initState();
    widget.rebuildTrigger.addListener(_onRebuild);
  }

  @override
  void dispose() {
    widget.rebuildTrigger.removeListener(_onRebuild);
    super.dispose();
  }

  void _onRebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// A widget that depends on a fixed number of inherited widgets every rebuild.
class _DependentWidget extends StatefulWidget {
  const _DependentWidget({
    required this.rebuildTrigger,
    required this.dependencyCount,
    required this.cleanupEnabled,
  });

  final ValueNotifier<int> rebuildTrigger;
  final int dependencyCount;
  final bool cleanupEnabled;

  @override
  State<_DependentWidget> createState() => _DependentWidgetState();
}

class _DependentWidgetState extends State<_DependentWidget> {
  @override
  void initState() {
    super.initState();
    widget.rebuildTrigger.addListener(_onRebuild);
  }

  @override
  void dispose() {
    widget.rebuildTrigger.removeListener(_onRebuild);
    super.dispose();
  }

  void _onRebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Access all dependencies every build
    for (var i = 0; i < widget.dependencyCount; i++) {
      if (widget.cleanupEnabled) {
        _CleanupInheritedWidget.of(context, i);
      } else {
        _NoCleanupInheritedWidget.of(context, i);
      }
    }
    return const SizedBox.shrink();
  }
}

/// A widget that conditionally depends on inherited widgets.
/// On odd rebuilds, it uses all dependencies.
/// On even rebuilds, it uses only half (creating cleanup work).
class _ConditionalDependentWidget extends StatefulWidget {
  const _ConditionalDependentWidget({
    required this.rebuildTrigger,
    required this.totalDependencies,
  });

  final ValueNotifier<int> rebuildTrigger;
  final int totalDependencies;

  @override
  State<_ConditionalDependentWidget> createState() => _ConditionalDependentWidgetState();
}

class _ConditionalDependentWidgetState extends State<_ConditionalDependentWidget> {
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    widget.rebuildTrigger.addListener(_onRebuild);
  }

  @override
  void dispose() {
    widget.rebuildTrigger.removeListener(_onRebuild);
    super.dispose();
  }

  void _onRebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    final bool useAll = _buildCount.isOdd;
    final int count = useAll ? widget.totalDependencies : widget.totalDependencies ~/ 2;

    for (var i = 0; i < count; i++) {
      _CleanupInheritedWidget.of(context, i);
    }
    return const SizedBox.shrink();
  }
}

/// An InheritedWidget with cleanupUnusedDependents = false (default behavior).
class _NoCleanupInheritedWidget extends InheritedWidget {
  const _NoCleanupInheritedWidget({required this.index, required super.child});

  final int index;

  static int of(BuildContext context, int index) {
    var result = -1;
    context.visitAncestorElements((Element element) {
      if (element.widget is _NoCleanupInheritedWidget) {
        final inherited = element.widget as _NoCleanupInheritedWidget;
        if (inherited.index == index) {
          context.dependOnInheritedElement(element as InheritedElement);
          result = inherited.index;
          return false; // Stop walking
        }
      }
      return true; // Continue walking
    });
    return result;
  }

  @override
  bool updateShouldNotify(_NoCleanupInheritedWidget oldWidget) => false;
}

/// An InheritedWidget with cleanupUnusedDependents = true.
class _CleanupInheritedWidget extends InheritedWidget {
  const _CleanupInheritedWidget({required this.index, required super.child});

  final int index;

  @override
  bool get cleanupUnusedDependents => true;

  static int of(BuildContext context, int index) {
    var result = -1;
    context.visitAncestorElements((Element element) {
      if (element.widget is _CleanupInheritedWidget) {
        final inherited = element.widget as _CleanupInheritedWidget;
        if (inherited.index == index) {
          context.dependOnInheritedElement(element as InheritedElement);
          result = inherited.index;
          return false; // Stop walking
        }
      }
      return true; // Continue walking
    });
    return result;
  }

  @override
  bool updateShouldNotify(_CleanupInheritedWidget oldWidget) => false;
}

//
//  Note that the benchmark is normally run by benchmark_collection.dart.
//
Future<void> main() async {
  return execute();
}
