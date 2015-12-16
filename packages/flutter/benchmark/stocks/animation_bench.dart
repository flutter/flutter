import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:stocks/main.dart' as stocks;
import 'package:stocks/stock_data.dart' as stock_data;

const int _kNumberOfIterations = 50000;
const bool _kRunForever = false;

void main() {
  assert(false); // Don't run in checked mode
  stock_data.StockDataFetcher.actuallyFetchData = false;

  const Duration _kAnimationDuration = const Duration(milliseconds: 200);
  const Duration tickDuration = const Duration(milliseconds: 2);
  int numberOfTicks = _kAnimationDuration.inMicroseconds ~/ tickDuration.inMicroseconds;
  int numberOfRounts = _kNumberOfIterations ~/ numberOfTicks;

  Stopwatch watch = new Stopwatch()
    ..start();

  testWidgets((WidgetTester tester) {
    stocks.main();
    tester.pump(); // Start startup animation
    tester.pump(const Duration(seconds: 1)); // Complete startup animation

    bool drawerIsOpen = false;

    for (int i = 0; i < numberOfRounts || _kRunForever; ++i) {
      if (drawerIsOpen)
        tester.tapAt(const Point(20.0, 20.0)); // Open drawer
      else
        tester.tapAt(const Point(780.0, 20.0)); // Close drawer

      tester.pump(); // Start drawer animation

      for (int j = 0; j < numberOfTicks; ++j)
        tester.pump(tickDuration);

      tester.pump(const Duration(seconds: 1)); // Complete animation
      drawerIsOpen = !drawerIsOpen;
    }
  });

  watch.stop();
  print("Stock animation: " + watch.elapsed.toString());

  exit(0);
}
