import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:stocks/main.dart' as stocks;
import 'package:stocks/stock_data.dart' as stock_data;

const int _kNumberOfIterations = 100000;
const bool _kRunForever = false;

void main() {
  stock_data.StockDataFetcher.actuallyFetchData = false;

  benchmarkWidgets((WidgetTester tester) {
    stocks.main();
    tester.pump(); // Start startup animation
    tester.pump(const Duration(seconds: 1)); // Complete startup animation
    tester.tapAt(new Point(20.0, 20.0)); // Open drawer
    tester.pump(); // Start drawer animation
    tester.pump(const Duration(seconds: 1)); // Complete drawer animation
  });

  ViewConfiguration big = const ViewConfiguration(size: const Size(360.0, 640.0));
  ViewConfiguration small = const ViewConfiguration(size: const Size(355.0, 635.0));
  RenderView renderView = WidgetsBinding.instance.renderView;

  Stopwatch watch = new Stopwatch()
    ..start();

  for (int i = 0; i < _kNumberOfIterations || _kRunForever; ++i) {
    renderView.configuration = (i % 2 == 0) ? big : small;
    RendererBinding.instance.pipelineOwner.flushLayout();
  }

  watch.stop();
  print("Stock layout: " + watch.elapsed.toString());
  exit(0);
}
