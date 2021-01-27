// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/scheduler.dart';
import 'package:stocks/main.dart' as stocks;
import 'package:stocks/stock_data.dart' as stock_data;

import '../common.dart';

const Duration kBenchmarkTime = Duration(seconds: 15);

class BenchmarkingBinding extends LiveTestWidgetsFlutterBinding {
  BenchmarkingBinding(this.stopwatch);

  final Stopwatch stopwatch;

  @override
  void handleBeginFrame(Duration rawTimeStamp) {
    stopwatch.start();
    super.handleBeginFrame(rawTimeStamp);
  }

  @override
  void handleDrawFrame() {
    super.handleDrawFrame();
    stopwatch.stop();
  }
}

Future<void> main() async {
  assert(false, "Don't run benchmarks in checked mode! Use 'flutter run --release'.");
  stock_data.StockData.actuallyFetchData = false;

  final Stopwatch wallClockWatch = Stopwatch();
  final Stopwatch cpuWatch = Stopwatch();
  BenchmarkingBinding(cpuWatch);

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
        await tester.tapAt(const Offset(780.0, 250.0)); // Close drawer
        await tester.pump();
        totalCloseIterationCount += 1;
        totalCloseFrameElapsedMicroseconds += cpuWatch.elapsedMicroseconds;
      } else {
        await tester.tapAt(const Offset(20.0, 50.0)); // Open drawer
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

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  printer.addResult(
    description: 'Stock animation',
    value: wallClockWatch.elapsedMicroseconds / (1000 * 1000),
    unit: 's',
    name: 'stock_animation_total_run_time',
  );
  printer.addResult(
    description: '  Opening first frame average time',
    value: totalOpenFrameElapsedMicroseconds / totalOpenIterationCount,
    unit: 'µs per frame ($totalOpenIterationCount frames)',
    name: 'stock_animation_open_first_frame_average',
  );
  printer.addResult(
    description: '  Closing first frame average time',
    value: totalCloseFrameElapsedMicroseconds / totalCloseIterationCount,
    unit: 'µs per frame ($totalCloseIterationCount frames)',
    name: 'stock_animation_close_first_frame_average',
  );
  printer.addResult(
    description: '  Subsequent frames average time',
    value: totalSubsequentFramesElapsedMicroseconds / totalSubsequentFramesIterationCount,
    unit: 'µs per frame ($totalSubsequentFramesIterationCount frames)',
    name: 'stock_animation_subsequent_frame_average',
  );
  printer.printToStdout();
}
