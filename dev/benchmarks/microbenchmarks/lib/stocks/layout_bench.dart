import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:stocks/main.dart' as stocks;
import 'package:stocks/stock_data.dart' as stock_data;

const Duration kBenchmarkTime = const Duration(seconds: 15);



Future<Null> main() async {
  assert(false); // don't run this in checked mode! Use --release.
  stock_data.StockDataFetcher.actuallyFetchData = false;

  final Stopwatch watch = new Stopwatch();
  int iterations = 0;

  await benchmarkWidgets((WidgetTester tester) async {
    stocks.main();
    await tester.pump(); // Start startup animation
    await tester.pump(const Duration(seconds: 1)); // Complete startup animation
    await tester.tapAt(new Point(20.0, 20.0)); // Open drawer
    await tester.pump(); // Start drawer animation
    await tester.pump(const Duration(seconds: 1)); // Complete drawer animation

    final TestViewConfiguration big = new TestViewConfiguration(size: const Size(360.0, 640.0));
    final TestViewConfiguration small = new TestViewConfiguration(size: const Size(355.0, 635.0));
    final RenderView renderView = WidgetsBinding.instance.renderView;

    watch.start();
    while (watch.elapsed < kBenchmarkTime) {
      renderView.configuration = (iterations % 2 == 0) ? big : small;
      RendererBinding.instance.pipelineOwner.flushLayout();
      iterations += 1;
    }
    watch.stop();
  });

  print('Stock layout: ${(watch.elapsedMicroseconds / iterations).toStringAsFixed(1)}µs per iteration');
  exit(0);
}
