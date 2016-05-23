import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:stocks/main.dart' as stocks;
import 'package:stocks/stock_data.dart' as stock_data;

const Duration kBenchmarkTime = const Duration(seconds: 15);

void _doNothing() { }

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


    final stocks.StocksAppState appState = tester.state(find.byType(stocks.StocksApp));
    final BuildOwner buildOwner = WidgetsBinding.instance.buildOwner;

    watch.start();
    while (watch.elapsed < kBenchmarkTime) {
      appState.setState(_doNothing);
      buildOwner.buildDirtyElements();
      iterations += 1;
    }
    watch.stop();
  });

  print('Stock build: ${(watch.elapsedMicroseconds / iterations).toStringAsFixed(1)}µs per iteration');
  exit(0);
}
