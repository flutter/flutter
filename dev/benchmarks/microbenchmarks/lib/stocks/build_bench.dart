// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:stocks/main.dart' as stocks;
import 'package:stocks/stock_data.dart' as stock_data;

import '../common.dart';

const Duration kBenchmarkTime = Duration(seconds: 15);

Future<void> main() async {
  assert(false); // don't run this in checked mode! Use --release.
  stock_data.StockData.actuallyFetchData = false;

  // We control the framePolicy below to prevent us from scheduling frames in
  // the engine, so that the engine does not interfere with our timings.
  final LiveTestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();

  final Stopwatch watch = Stopwatch();
  int iterations = 0;

  await benchmarkWidgets((WidgetTester tester) async {
    stocks.main();
    await tester.pump(); // Start startup animation
    await tester.pump(const Duration(seconds: 1)); // Complete startup animation
    await tester.tapAt(const Offset(20.0, 40.0)); // Open drawer
    await tester.pump(); // Start drawer animation
    await tester.pump(const Duration(seconds: 1)); // Complete drawer animation

    final Element appState = tester.element(find.byType(stocks.StocksApp));
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmark;

    watch.start();
    while (watch.elapsed < kBenchmarkTime) {
      appState.markNeedsBuild();
      // We don't use tester.pump() because we're trying to drive it in an
      // artificially high load to find out how much CPU each frame takes.
      // This differs from normal benchmarks which might look at how many
      // frames are missed, etc.
      // We use Timer.run to ensure there's a microtask flush in between
      // the two calls below.
      Timer.run(() { ui.window.onBeginFrame(Duration(milliseconds: iterations * 16)); });
      Timer.run(() { ui.window.onDrawFrame(); });
      await tester.idle(); // wait until the frame has run (also uses Timer.run)
      iterations += 1;
    }
    watch.stop();
  });

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  printer.addResult(
    description: 'Stock build',
    value: watch.elapsedMicroseconds / iterations,
    unit: 'µs per iteration',
    name: 'stock_build_iteration',
  );
  printer.printToStdout();
}
