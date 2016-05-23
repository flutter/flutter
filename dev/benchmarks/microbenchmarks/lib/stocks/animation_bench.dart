// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:stocks/main.dart' as stocks;
import 'package:stocks/stock_data.dart' as stock_data;

const Duration kBenchmarkTime = const Duration(seconds: 15);

class BenchmarkingBinding extends LiveTestWidgetsFlutterBinding {
  BenchmarkingBinding(this.stopwatch);

  final Stopwatch stopwatch;

  @override
  void handleBeginFrame(Duration rawTimeStamp) {
    stopwatch.start();
    super.handleBeginFrame(rawTimeStamp);
    stopwatch.stop();
  }
}

Future<Null> main() async {
  assert(false); // don't run this in checked mode! Use --release.
  stock_data.StockDataFetcher.actuallyFetchData = false;

  final Stopwatch wallClockWatch = new Stopwatch();
  final Stopwatch cpuWatch = new Stopwatch();
  new BenchmarkingBinding(cpuWatch);

  int totalOpenFrameElapsedMicroseconds = 0;
  int totalOpenIterationCount = 0;
  int totalCloseFrameElapsedMicroseconds = 0;
  int totalCloseIterationCount = 0;
  int totalSubsequentFramesElapsedMicroseconds = 0;
  int totalSubsequentFramesIterationCount = 0;

  await benchmarkWidgets((WidgetTester tester) async {
    stocks.main();
    await tester.pump(); // Start startup animation
    await tester.pump(const Duration(seconds: 1)); // Complete startup animation

    bool drawerIsOpen = false;
    wallClockWatch.start();
    while (wallClockWatch.elapsed < kBenchmarkTime) {
      cpuWatch.reset();
      if (drawerIsOpen) {
        await tester.tapAt(const Point(780.0, 250.0)); // Close drawer
        await tester.pump();
        totalCloseIterationCount += 1;
        totalCloseFrameElapsedMicroseconds += cpuWatch.elapsedMicroseconds;
      } else {
        await tester.tapAt(const Point(20.0, 50.0)); // Open drawer
        await tester.pump();
        totalOpenIterationCount += 1;
        totalOpenFrameElapsedMicroseconds += cpuWatch.elapsedMicroseconds;
      }
      drawerIsOpen = !drawerIsOpen;

      // Time how long each frame takes
      cpuWatch.reset();
      while (SchedulerBinding.instance.hasScheduledFrame) {
        await tester.pump();
        totalSubsequentFramesIterationCount += 1;
      }
      totalSubsequentFramesElapsedMicroseconds += cpuWatch.elapsedMicroseconds;
    }
  });

  print('Stock animation (ran for ${(wallClockWatch.elapsedMicroseconds / (1000 * 1000)).toStringAsFixed(1)}s):');
  print('  Opening first frame average time: ${(totalOpenFrameElapsedMicroseconds / (totalOpenIterationCount)).toStringAsFixed(1)}µs per frame ($totalOpenIterationCount frames)');
  print('  Closing first frame average time: ${(totalCloseFrameElapsedMicroseconds / (totalCloseIterationCount)).toStringAsFixed(1)}µs per frame ($totalCloseIterationCount frames)');
  print('  Subsequent frames average time: ${(totalSubsequentFramesElapsedMicroseconds / (totalSubsequentFramesIterationCount)).toStringAsFixed(1)}µs per frame ($totalSubsequentFramesIterationCount frames)');

  exit(0);
}
