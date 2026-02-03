// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common.dart';

/// Benchmark comparing const vs non-const Container performance.
///
/// This benchmark measures:
/// 1. Widget tree build time with const Containers
/// 2. Widget tree build time with non-const Containers
/// 3. Widget update (rebuild) performance demonstrating const optimization

const int kIterations = 1000;
const Duration kBenchmarkTime = Duration(seconds: 10);

/// Creates a tree of const Container widgets
Widget _buildConstContainerTree(int count) {
  Widget child = const SizedBox.shrink();
  for (int i = 0; i < count; i++) {
    child = const Container(
      width: 50,
      height: 50,
      padding: EdgeInsets.all(4),
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: SizedBox.shrink(),
    );
  }
  return child;
}

/// Creates a tree of non-const Container widgets (simulating runtime values)
Widget _buildNonConstContainerTree(int count, int seed) {
  Widget child = const SizedBox.shrink();
  for (int i = 0; i < count; i++) {
    // Using seed to prevent const folding by the compiler
    child = Container(
      width: 50.0 + (seed % 1) * 0.0001, // Tiny variation prevents const
      height: 50.0 + (seed % 1) * 0.0001,
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: const SizedBox.shrink(),
    );
  }
  return child;
}

/// Benchmark that measures widget construction time
Future<List<double>> runConstContainerBuildBenchmark() async {
  assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");

  final binding = TestWidgetsFlutterBinding.ensureInitialized() as LiveTestWidgetsFlutterBinding;
  final watch = Stopwatch();
  final values = <double>[];

  await benchmarkWidgets((WidgetTester tester) async {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmark;

    Duration elapsed = Duration.zero;
    int iterations = 0;

    while (elapsed < kBenchmarkTime) {
      watch.reset();
      watch.start();

      // Build and pump const container tree
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _buildConstContainerTree(100))));

      watch.stop();
      iterations += 1;
      elapsed += Duration(microseconds: watch.elapsedMicroseconds);
      values.add(watch.elapsedMicroseconds.toDouble());
    }
  });

  return values;
}

/// Benchmark that measures widget construction time for non-const
Future<List<double>> runNonConstContainerBuildBenchmark() async {
  assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");

  final binding = TestWidgetsFlutterBinding.ensureInitialized() as LiveTestWidgetsFlutterBinding;
  final watch = Stopwatch();
  final values = <double>[];

  await benchmarkWidgets((WidgetTester tester) async {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmark;

    Duration elapsed = Duration.zero;
    int iterations = 0;

    while (elapsed < kBenchmarkTime) {
      watch.reset();
      watch.start();

      // Build and pump non-const container tree
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: _buildNonConstContainerTree(100, iterations))),
      );

      watch.stop();
      iterations += 1;
      elapsed += Duration(microseconds: watch.elapsedMicroseconds);
      values.add(watch.elapsedMicroseconds.toDouble());
    }
  });

  return values;
}

/// Benchmark measuring widget rebuild skip optimization with const
Future<List<double>> runConstRebuildBenchmark() async {
  assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");

  final binding = TestWidgetsFlutterBinding.ensureInitialized() as LiveTestWidgetsFlutterBinding;
  final watch = Stopwatch();
  final values = <double>[];

  await benchmarkWidgets((WidgetTester tester) async {
    // Initial build
    await tester.pumpWidget(MaterialApp(home: _RebuildTestWidget(useConst: true)));

    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmark;

    Duration elapsed = Duration.zero;

    while (elapsed < kBenchmarkTime) {
      watch.reset();
      watch.start();

      // Trigger rebuild by tapping the button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      watch.stop();
      elapsed += Duration(microseconds: watch.elapsedMicroseconds);
      values.add(watch.elapsedMicroseconds.toDouble());
    }
  });

  return values;
}

class _RebuildTestWidget extends StatefulWidget {
  const _RebuildTestWidget({required this.useConst});

  final bool useConst;

  @override
  State<_RebuildTestWidget> createState() => _RebuildTestWidgetState();
}

class _RebuildTestWidgetState extends State<_RebuildTestWidget> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Text('Counter: $_counter'),
          ElevatedButton(
            onPressed: () => setState(() => _counter++),
            child: const Text('Increment'),
          ),
          // This subtree should be skipped during rebuild when using const
          if (widget.useConst) ..._buildConstContainers() else ..._buildNonConstContainers(),
        ],
      ),
    );
  }

  List<Widget> _buildConstContainers() {
    return List<Widget>.generate(50, (int index) {
      return const Container(width: 50, height: 50, margin: EdgeInsets.all(2), color: Colors.blue);
    });
  }

  List<Widget> _buildNonConstContainers() {
    return List<Widget>.generate(50, (int index) {
      return Container(
        width: 50.0 + index * 0.0001, // Prevent const folding
        height: 50,
        margin: const EdgeInsets.all(2),
        color: Colors.blue,
      );
    });
  }
}

Future<void> execute() async {
  final printer = BenchmarkResultPrinter();

  printer.addResultStatistics(
    description: 'Const Container build',
    values: await runConstContainerBuildBenchmark(),
    unit: 'µs per iteration',
    name: 'const_container_build_iteration',
  );

  printer.addResultStatistics(
    description: 'Non-const Container build',
    values: await runNonConstContainerBuildBenchmark(),
    unit: 'µs per iteration',
    name: 'non_const_container_build_iteration',
  );

  printer.addResultStatistics(
    description: 'Const Container rebuild (with skip optimization)',
    values: await runConstRebuildBenchmark(),
    unit: 'µs per iteration',
    name: 'const_container_rebuild_iteration',
  );

  printer.printToStdout();
}

Future<void> main() async {
  return execute();
}
