import 'dart:async';

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

  final Stopwatch watch = new Stopwatch();
  int iterations = 0;

  await benchmarkWidgets((WidgetTester tester) async {
    stocks.main();
    await tester.pump(); // Start startup animation
    await tester.pump(const Duration(seconds: 1)); // Complete startup animation
    await tester.tapAt(new Point(20.0, 20.0)); // Open drawer
    await tester.pump(); // Start drawer animation
    await tester.pump(const Duration(seconds: 1)); // Complete drawer animation


    final BuildableElement appState = tester.element(find.byType(stocks.StocksApp));
    final BuildOwner buildOwner = WidgetsBinding.instance.buildOwner;

    watch.start();
    while (watch.elapsed < kBenchmarkTime) {
      appState.markNeedsBuild();
      buildOwner.buildScope(WidgetsBinding.instance.renderViewElement);
      iterations += 1;
    }
    watch.stop();
  });

  BenchmarkResultPrinter printer = new BenchmarkResultPrinter();
  printer.addResult(
    description: 'Stock build',
    value: watch.elapsedMicroseconds / iterations,
    unit: 'µs per iteration',
    name: 'stock_build_iteration',
  );
  printer.printToStdout();
}
