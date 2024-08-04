// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common.dart';

late final LiveTestWidgetsFlutterBinding binding;
late final BenchmarkResultPrinter printer;

Future<void> main() async {
  assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");
  binding = TestWidgetsFlutterBinding.ensureInitialized() as LiveTestWidgetsFlutterBinding;
  printer = BenchmarkResultPrinter();
  // Run each benchmark at two sizes, to see how it scales.
  await measureBoundaryToggle(depth: 2000);
  await measureBoundaryToggle(depth: 4000);
  await measureSubtreeReparenting(depth: 2000);
  await measureSubtreeReparenting(depth: 4000);
  await measureSubtreeReparentingAccordion(depth: 1000);
  await measureSubtreeReparentingAccordion(depth: 2000);
  printer.printToStdout();
}

const Duration kBenchmarkTime = Duration(seconds: 5);
const Size kSize = Size.square(100);

Future<void> measureBoundaryToggle({required int depth}) {
  Widget chain = SizedBox.fromSize(size: kSize);
  for (int i = 0; i < depth; i++) {
    chain = SizedBox(child: chain);
  }
  chain = Align(child: chain);
  return measure(
    name: 'relayout_boundary_toggle_depth$depth',
    description: 'Relayout boundary toggling on/off, subtree depth $depth',
    SizedBox.fromSize(size: kSize, child: chain), // relayout boundary
    SizedBox(child: chain), // not a relayout boundary
  );
}

Future<void> measureSubtreeReparenting({required int depth}) {
  Widget chain = SizedBox.fromSize(size: kSize);
  for (int i = 0; i < depth; i++) {
    chain = SizedBox(child: chain);
  }
  chain = KeyedSubtree(key: GlobalKey(), child: chain);
  return measure(
    name: 'relayout_subtree_reparenting_depth$depth',
    description: 'Relayout subtree reparenting, depth $depth',
    chain,
    SizedBox(child: chain),
  );
}

Future<void> measureSubtreeReparentingAccordion({required int depth}) {
  Widget short = SizedBox.fromSize(size: kSize);
  Widget long = SizedBox.fromSize(size: kSize);
  for (int i = 0; i < depth; i++) {
    final GlobalKey key = GlobalKey(debugLabel: 'height $i');
    short = SizedBox(key: key, child: short);
    long = SizedBox(key: key, child: SizedBox(child: long));
  }
  return measure(
    name: 'relayout_subtree_reparenting_accordion_depth$depth',
    description: 'Relayout subtree reparenting in an accordion, depth $depth',
    short,
    long,
  );
}

Future<void> measure(Widget child1, Widget child2, {
  required String name, required String description,
}) async {
  final Stopwatch watch = Stopwatch();
  int iterations = 0;
  await benchmarkWidgets((WidgetTester tester) async {
    late StateSetter setState;
    bool state = false;
    Widget app = StatefulBuilder(builder: (BuildContext context, StateSetter setter) {
      setState = setter;
      return state ? child1 : child2;
    });
    app = Align(child: SizedBox.fromSize(size: kSize, child: Align(child: app)));

    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
    runApp(app);
    await tester.pump(const Duration(seconds: 1));

    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmark;
    while (watch.elapsed < kBenchmarkTime) {
      watch.start();
      setState(() {
        state = !state;
      });
      await tester.pumpBenchmark(Duration(milliseconds: iterations * 16));
      watch.stop();
      iterations += 1;
    }
  });

  printer.addResult(
    name: name,
    description: description,
    value: watch.elapsedMicroseconds / iterations,
    unit: 'µs per iteration',
  );
}
