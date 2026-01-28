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

  // Run multi-type benchmarks (tests "width" - many different InheritedWidget types)
  await _runMultipleTypeBenchmark(printer);
  await _runDepthAndWidthBenchmark(printer);
  await _runMultiTypeCleanupBenchmark(printer);

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

/// Measures rebuild time with multiple distinct InheritedWidget types.
/// This tests "width" (many different dependency types) in addition to "depth".
/// Real apps have many different InheritedWidget types (Theme, MediaQuery, Navigator, etc.),
/// so this benchmark better reflects real-world Set.difference performance.
Future<void> _runMultipleTypeBenchmark(BenchmarkResultPrinter printer) async {
  // Test with different numbers of distinct types
  for (final typeCount in <int>[5, 10, 20]) {
    await benchmarkWidgets((WidgetTester tester) async {
      final rebuildTrigger = ValueNotifier<int>(0);

      await tester.pumpWidget(
        _buildMultiTypeInheritedStack(
          typeCount: typeCount,
          child: _MultiTypeDependentWidget(rebuildTrigger: rebuildTrigger, typeCount: typeCount),
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
        description: 'Rebuild ($typeCount types, width test)',
        value: averagePerIteration * _kScale,
        unit: 'ns per iteration',
        name: 'rebuild_${typeCount}types_width',
      );
    });
  }
}

/// Measures rebuild time with both depth and width.
/// Creates a stack with multiple distinct InheritedWidget types, each with multiple instances.
Future<void> _runDepthAndWidthBenchmark(BenchmarkResultPrinter printer) async {
  // Test combinations of types (width) and instances per type (depth)
  const configs = <(int, int)>[
    (5, 10), // 5 types, 10 instances each = 50 total dependencies
    (10, 10), // 10 types, 10 instances each = 100 total dependencies
    (20, 5), // 20 types, 5 instances each = 100 total dependencies
    (10, 50), // 10 types, 50 instances each = 500 total dependencies
  ];

  for (final (int typeCount, int instancesPerType) in configs) {
    final int totalDeps = typeCount * instancesPerType;
    await benchmarkWidgets((WidgetTester tester) async {
      final rebuildTrigger = ValueNotifier<int>(0);

      await tester.pumpWidget(
        _buildMultiTypeMultiInstanceStack(
          typeCount: typeCount,
          instancesPerType: instancesPerType,
          child: _MultiTypeMultiInstanceDependentWidget(
            rebuildTrigger: rebuildTrigger,
            typeCount: typeCount,
            instancesPerType: instancesPerType,
          ),
        ),
      );

      // Warm up (fewer iterations for large dep counts)
      final int warmUpIterations = totalDeps > 100 ? 10 : _kNumWarmUp;
      for (var i = 0; i < warmUpIterations; i++) {
        rebuildTrigger.value++;
        await tester.pump();
      }

      // Fewer iterations for stress test
      final int iterations = totalDeps > 100 ? 1000 : _kNumIterations;
      final watch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        rebuildTrigger.value++;
        await tester.pump();
      }
      watch.stop();

      final double averagePerIteration = watch.elapsedMicroseconds / iterations;
      printer.addResult(
        description: 'Rebuild (${typeCount}x$instancesPerType=$totalDeps deps)',
        value: averagePerIteration * _kScale,
        unit: 'ns per iteration',
        name: 'rebuild_${typeCount}types_${instancesPerType}inst',
      );
    });
  }
}

/// Measures rebuild time with multiple types and conditional dependencies (actual cleanup).
Future<void> _runMultiTypeCleanupBenchmark(BenchmarkResultPrinter printer) async {
  for (final typeCount in <int>[5, 10, 20]) {
    await benchmarkWidgets((WidgetTester tester) async {
      final rebuildTrigger = ValueNotifier<int>(0);

      await tester.pumpWidget(
        _buildMultiTypeInheritedStack(
          typeCount: typeCount,
          child: _MultiTypeConditionalDependentWidget(
            rebuildTrigger: rebuildTrigger,
            typeCount: typeCount,
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
        description: 'Rebuild ($typeCount types, cleanup)',
        value: averagePerIteration * _kScale,
        unit: 'ns per iteration',
        name: 'rebuild_${typeCount}types_cleanup',
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

/// Base class for typed inherited widgets with cleanup enabled.
abstract class _TypedInheritedWidget extends InheritedWidget {
  const _TypedInheritedWidget({required this.index, required super.child});

  final int index;

  @override
  bool get cleanupUnusedDependents => true;

  @override
  bool updateShouldNotify(covariant _TypedInheritedWidget oldWidget) => false;
}

// Define few distinct InheritedWidget types to simulate real app scenarios.
// Each class is a separate type in Dart's type system, since we can't add dynamically.
class _TypedInherited0 extends _TypedInheritedWidget {
  const _TypedInherited0({required super.index, required super.child});
}

class _TypedInherited1 extends _TypedInheritedWidget {
  const _TypedInherited1({required super.index, required super.child});
}

class _TypedInherited2 extends _TypedInheritedWidget {
  const _TypedInherited2({required super.index, required super.child});
}

class _TypedInherited3 extends _TypedInheritedWidget {
  const _TypedInherited3({required super.index, required super.child});
}

class _TypedInherited4 extends _TypedInheritedWidget {
  const _TypedInherited4({required super.index, required super.child});
}

class _TypedInherited5 extends _TypedInheritedWidget {
  const _TypedInherited5({required super.index, required super.child});
}

class _TypedInherited6 extends _TypedInheritedWidget {
  const _TypedInherited6({required super.index, required super.child});
}

class _TypedInherited7 extends _TypedInheritedWidget {
  const _TypedInherited7({required super.index, required super.child});
}

class _TypedInherited8 extends _TypedInheritedWidget {
  const _TypedInherited8({required super.index, required super.child});
}

class _TypedInherited9 extends _TypedInheritedWidget {
  const _TypedInherited9({required super.index, required super.child});
}

class _TypedInherited10 extends _TypedInheritedWidget {
  const _TypedInherited10({required super.index, required super.child});
}

class _TypedInherited11 extends _TypedInheritedWidget {
  const _TypedInherited11({required super.index, required super.child});
}

class _TypedInherited12 extends _TypedInheritedWidget {
  const _TypedInherited12({required super.index, required super.child});
}

class _TypedInherited13 extends _TypedInheritedWidget {
  const _TypedInherited13({required super.index, required super.child});
}

class _TypedInherited14 extends _TypedInheritedWidget {
  const _TypedInherited14({required super.index, required super.child});
}

class _TypedInherited15 extends _TypedInheritedWidget {
  const _TypedInherited15({required super.index, required super.child});
}

class _TypedInherited16 extends _TypedInheritedWidget {
  const _TypedInherited16({required super.index, required super.child});
}

class _TypedInherited17 extends _TypedInheritedWidget {
  const _TypedInherited17({required super.index, required super.child});
}

class _TypedInherited18 extends _TypedInheritedWidget {
  const _TypedInherited18({required super.index, required super.child});
}

class _TypedInherited19 extends _TypedInheritedWidget {
  const _TypedInherited19({required super.index, required super.child});
}

Widget _createTypedInherited(int typeIndex, int instanceIndex, Widget child) {
  return switch (typeIndex % 20) {
    0 => _TypedInherited0(index: instanceIndex, child: child),
    1 => _TypedInherited1(index: instanceIndex, child: child),
    2 => _TypedInherited2(index: instanceIndex, child: child),
    3 => _TypedInherited3(index: instanceIndex, child: child),
    4 => _TypedInherited4(index: instanceIndex, child: child),
    5 => _TypedInherited5(index: instanceIndex, child: child),
    6 => _TypedInherited6(index: instanceIndex, child: child),
    7 => _TypedInherited7(index: instanceIndex, child: child),
    8 => _TypedInherited8(index: instanceIndex, child: child),
    9 => _TypedInherited9(index: instanceIndex, child: child),
    10 => _TypedInherited10(index: instanceIndex, child: child),
    11 => _TypedInherited11(index: instanceIndex, child: child),
    12 => _TypedInherited12(index: instanceIndex, child: child),
    13 => _TypedInherited13(index: instanceIndex, child: child),
    14 => _TypedInherited14(index: instanceIndex, child: child),
    15 => _TypedInherited15(index: instanceIndex, child: child),
    16 => _TypedInherited16(index: instanceIndex, child: child),
    17 => _TypedInherited17(index: instanceIndex, child: child),
    18 => _TypedInherited18(index: instanceIndex, child: child),
    19 => _TypedInherited19(index: instanceIndex, child: child),
    _ => throw StateError('Unexpected type index: $typeIndex'),
  };
}

final List<bool Function(Widget)> _typeCheckers = <bool Function(Widget)>[
  (Widget w) => w is _TypedInherited0,
  (Widget w) => w is _TypedInherited1,
  (Widget w) => w is _TypedInherited2,
  (Widget w) => w is _TypedInherited3,
  (Widget w) => w is _TypedInherited4,
  (Widget w) => w is _TypedInherited5,
  (Widget w) => w is _TypedInherited6,
  (Widget w) => w is _TypedInherited7,
  (Widget w) => w is _TypedInherited8,
  (Widget w) => w is _TypedInherited9,
  (Widget w) => w is _TypedInherited10,
  (Widget w) => w is _TypedInherited11,
  (Widget w) => w is _TypedInherited12,
  (Widget w) => w is _TypedInherited13,
  (Widget w) => w is _TypedInherited14,
  (Widget w) => w is _TypedInherited15,
  (Widget w) => w is _TypedInherited16,
  (Widget w) => w is _TypedInherited17,
  (Widget w) => w is _TypedInherited18,
  (Widget w) => w is _TypedInherited19,
];

/// Depend on a specific typed inherited widget by type index.
void _dependOnTypedInherited(BuildContext context, int typeIndex, {int? instanceIndex}) {
  final bool Function(Widget) checker = _typeCheckers[typeIndex % 20];
  context.visitAncestorElements((Element element) {
    if (checker(element.widget)) {
      final inherited = element.widget as _TypedInheritedWidget;
      if (instanceIndex == null || inherited.index == instanceIndex) {
        context.dependOnInheritedElement(element as InheritedElement);
        return false;
      }
    }
    return true;
  });
}

/// Builds a nested stack with multiple distinct InheritedWidget types.
/// Each type appears once for width test.
Widget _buildMultiTypeInheritedStack({required int typeCount, required Widget child}) {
  var result = child;
  for (int i = typeCount - 1; i >= 0; i--) {
    result = _createTypedInherited(i, 0, result);
  }
  return Directionality(textDirection: TextDirection.ltr, child: result);
}

/// Builds a nested stack with multiple distinct InheritedWidget types,
/// each with multiple instances for width + depth test.
Widget _buildMultiTypeMultiInstanceStack({
  required int typeCount,
  required int instancesPerType,
  required Widget child,
}) {
  var result = child;
  for (int instance = instancesPerType - 1; instance >= 0; instance--) {
    for (int type = typeCount - 1; type >= 0; type--) {
      result = _createTypedInherited(type, instance, result);
    }
  }
  return Directionality(textDirection: TextDirection.ltr, child: result);
}

class _MultiTypeDependentWidget extends StatefulWidget {
  const _MultiTypeDependentWidget({required this.rebuildTrigger, required this.typeCount});

  final ValueNotifier<int> rebuildTrigger;
  final int typeCount;

  @override
  State<_MultiTypeDependentWidget> createState() => _MultiTypeDependentWidgetState();
}

class _MultiTypeDependentWidgetState extends State<_MultiTypeDependentWidget> {
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
    // Depend on all types every build
    for (var i = 0; i < widget.typeCount; i++) {
      _dependOnTypedInherited(context, i);
    }
    return const SizedBox.shrink();
  }
}

/// A widget that depends on multiple types and multiple instances per type.
class _MultiTypeMultiInstanceDependentWidget extends StatefulWidget {
  const _MultiTypeMultiInstanceDependentWidget({
    required this.rebuildTrigger,
    required this.typeCount,
    required this.instancesPerType,
  });

  final ValueNotifier<int> rebuildTrigger;
  final int typeCount;
  final int instancesPerType;

  @override
  State<_MultiTypeMultiInstanceDependentWidget> createState() =>
      _MultiTypeMultiInstanceDependentWidgetState();
}

class _MultiTypeMultiInstanceDependentWidgetState
    extends State<_MultiTypeMultiInstanceDependentWidget> {
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
    // Depend on all types and all instances every build
    for (var type = 0; type < widget.typeCount; type++) {
      for (var instance = 0; instance < widget.instancesPerType; instance++) {
        _dependOnTypedInherited(context, type, instanceIndex: instance);
      }
    }
    return const SizedBox.shrink();
  }
}

/// A widget that conditionally depends on different typed inherited widgets.
/// On odd rebuilds, it uses all types.
/// On even rebuilds, it uses only half (creating cleanup work).
class _MultiTypeConditionalDependentWidget extends StatefulWidget {
  const _MultiTypeConditionalDependentWidget({
    required this.rebuildTrigger,
    required this.typeCount,
  });

  final ValueNotifier<int> rebuildTrigger;
  final int typeCount;

  @override
  State<_MultiTypeConditionalDependentWidget> createState() =>
      _MultiTypeConditionalDependentWidgetState();
}

class _MultiTypeConditionalDependentWidgetState
    extends State<_MultiTypeConditionalDependentWidget> {
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
    final int count = useAll ? widget.typeCount : widget.typeCount ~/ 2;

    for (var i = 0; i < count; i++) {
      _dependOnTypedInherited(context, i);
    }
    return const SizedBox.shrink();
  }
}

//
//  Note that the benchmark is normally run by benchmark_collection.dart.
//
Future<void> main() async {
  return execute();
}
