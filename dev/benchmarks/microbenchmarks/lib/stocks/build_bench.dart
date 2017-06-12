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

const Duration kBenchmarkTime = const Duration(seconds: 15);

Future<Null> main() async {
  assert(false); // don't run this in checked mode! Use --release.
  stock_data.StockDataFetcher.actuallyFetchData = false;

  // This allows us to call onBeginFrame even when the engine didn't request it,
  // and have it actually do something:
  final LiveTestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final Stopwatch watch = new Stopwatch();
  int iterations = 0;

  await benchmarkWidgets((WidgetTester tester) async {
    stocks.main();
    await tester.pump(); // Start startup animation
    await tester.pump(const Duration(seconds: 1)); // Complete startup animation
    await tester.tapAt(const Offset(20.0, 40.0)); // Open drawer
    await tester.pump(); // Start drawer animation
    await tester.pump(const Duration(seconds: 1)); // Complete drawer animation

    final Element appState = tester.element(find.byType(stocks.StocksApp));

    watch.start();
    while (watch.elapsed < kBenchmarkTime) {
      appState.markNeedsBuild();
      // We don't use tester.pump() because we're trying to drive it in an
      // artificially high load to find out how much CPU each frame takes.
      // This differs from normal benchmarks which might look at how many
      // frames are missed, etc.
      ui.window.onBeginFrame(new Duration(milliseconds: iterations * 16));
      iterations += 1;
    }
    watch.stop();
  });

  final BenchmarkResultPrinter printer = new BenchmarkResultPrinter();
  printer.addResult(
    description: 'Stock build',
    value: watch.elapsedMicroseconds / iterations,
    unit: 'µs per iteration',
    name: 'stock_build_iteration',
  );
  printer.printToStdout();
}
