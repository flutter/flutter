// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:macrobenchmarks/common.dart';
import 'package:e2e/e2e.dart';
import 'package:macrobenchmarks/main.dart' as app;

/// The maximum amount of time considered safe to spend for a frame's build
/// phase. Anything past that is in the danger of missing the frame as 60FPS.
///
/// Changing this doesn't re-evaluate existing summary.
Duration kBuildBudget = const Duration(milliseconds: 16);
// TODO(CareF): Automatically calculate the refresh budget

typedef DriveCallback = Future<void> Function(WidgetController controller);

void macroPerfTestE2E(
  String testName,
  String routeName, {
  Duration pageDelay,
  Duration duration = const Duration(seconds: 3),
  Duration timeout = const Duration(seconds: 30),
  DriveCallback body,
  DriveCallback setup,
}) {
  assert(() {
    debugPrint(kDebugWarning);
    return true;
  }());
  final WidgetsBinding _binding = E2EWidgetsFlutterBinding.ensureInitialized();
  assert(_binding is E2EWidgetsFlutterBinding);
  final E2EWidgetsFlutterBinding binding = _binding as E2EWidgetsFlutterBinding;
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;

  testWidgets(testName, (WidgetTester tester) async {
    assert((tester.binding as LiveTestWidgetsFlutterBinding).framePolicy ==
        LiveTestWidgetsFlutterBindingFramePolicy.fullyLive);
    app.main();
    await tester.pumpAndSettle();

    // The slight initial delay avoids starting the timing during a
    // period of increased load on the device. Without this delay, the
    // benchmark has greater noise.
    // See: https://github.com/flutter/flutter/issues/19434
    await tester.binding.delayed(const Duration(microseconds: 250));

    final Finder scrollable =
        find.byKey(const ValueKey<String>(kScrollableName));
    expect(scrollable, findsOneWidget);
    final Finder button =
        find.byKey(ValueKey<String>(routeName), skipOffstage: false);
    await tester.ensureVisible(button);
    expect(button, findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(button);

    if (pageDelay != null) {
      // Wait for the page to load
      await tester.binding.delayed(pageDelay);
    }

    if (setup != null) {
      await setup(tester);
    }

    await watchPerformance(binding, () async {
      final Future<void> durationFuture = tester.binding.delayed(duration);
      if (body != null) {
        await body(tester);
      }
      await durationFuture;
    });
  }, semanticsEnabled: false, timeout: Timeout(timeout));
}

Future<void> watchPerformance(
  E2EWidgetsFlutterBinding binding,
  Future<void> action(),
) async {
  // This method might be good as part of e2e,
  // so is the helper `PerformanceWatcher` class.
  final List<FrameTiming> frameTimings = <FrameTiming>[];
  final TimingsCallback watcher = frameTimings.addAll;
  binding.addTimingsCallback(watcher);
  await action();
  binding.removeTimingsCallback(watcher);
  // TODO(CareF): determine if it's running on firebase and report metric online
  final FrameTimingSummarizer frameTimes = FrameTimingSummarizer(frameTimings);
  binding.reportData = <String, dynamic>{'performance': frameTimes.summary};
}

/// This class records [FrameTiming] and summarizes the building statistics.
///
/// Without otherwise noticed, all time in this class is in unit microseconds.
class FrameTimingSummarizer {
  factory FrameTimingSummarizer(List<FrameTiming>data) {
    assert(data != null);
    assert(data.isNotEmpty);
    final List<int> frameBuildTimeMicros = List<int>.unmodifiable(
      data.map<int>((FrameTiming datum) => datum.buildDuration.inMicroseconds),
    );
    final List<int> frameBuildTimeMicrosSorted = List<int>.from(frameBuildTimeMicros)..sort();
    final List<int> frameRasterizerTimeMicros = List<int>.unmodifiable(
      data.map<int>((FrameTiming datum) => datum.rasterDuration.inMicroseconds),
    );
    final List<int> frameRasterizerTimeMicrosSorted = List<int>.from(frameBuildTimeMicros)..sort();
    final int Function(int, int) add = (int a, int b) => a + b;
    return FrameTimingSummarizer._(
      frameBuildTimeMicros,
      frameRasterizerTimeMicros,
      frameBuildTimeMicros.reduce(add) / 1E3 / data.length,
      _findPercentile(frameBuildTimeMicrosSorted, 0.90) / 1E3,
      _findPercentile(frameBuildTimeMicrosSorted, 0.99) / 1E3,
      frameBuildTimeMicrosSorted.last / 1E3,
      _countExceed(frameBuildTimeMicrosSorted, kBuildBudget.inMicroseconds),
      frameRasterizerTimeMicros.reduce(add) / 1E3 / data.length,
      _findPercentile(frameRasterizerTimeMicrosSorted, 0.90) / 1E3,
      _findPercentile(frameRasterizerTimeMicrosSorted, 0.90) / 1E3,
      frameRasterizerTimeMicrosSorted.last / 1E3,
      _countExceed(frameRasterizerTimeMicrosSorted, kBuildBudget.inMicroseconds),
    );
  }

  const FrameTimingSummarizer._(
    this.frameBuildTimeMicros,
    this.frameRasterizerTimeMicros,
    this.averageFrameBuildTime,
    this.percentileFrameBuildTime90,
    this.percentileFrameBuildTime99,
    this.worstFrameBuildTime,
    this.missedFrameBuildBudget,
    this.averageFrameRasterizerTime,
    this.percentileFrameRasterizerTime90,
    this.percentileFrameRasterizerTime99,
    this.worstFrameRasterizerTime,
    this.missedFrameRasterizerBudget
  );

  /// List of frame build time in microseconds
  final List<int> frameBuildTimeMicros;

  /// List of frame rasterizer time in microseconds
  final List<int> frameRasterizerTimeMicros;

  /// The average value of [frameBuildTimeMicros] in milliseconds.
  final double averageFrameBuildTime;

  /// The 90-th percentile value of [frameBuildTimeMicros] in milliseconds
  final double percentileFrameBuildTime90;

  /// The 99-th percentile value of [frameBuildTimeMicros] in milliseconds
  final double percentileFrameBuildTime99;

  /// The largest value of [frameBuildTimeMicros] in milliseconds
  final double worstFrameBuildTime;

  /// Number of items in [frameBuildTimeMicros] that's greater than [kBuildBudget]
  final int missedFrameBuildBudget;

  /// The average value of [frameRasterizerTimeMicros] in milliseconds.
  final double averageFrameRasterizerTime;

  /// The 90-th percentile value of [frameRasterizerTimeMicros] in milliseconds.
  final double percentileFrameRasterizerTime90;

  /// The 99-th percentile value of [frameRasterizerTimeMicros] in milliseconds.
  final double percentileFrameRasterizerTime99;

  /// The largest value of [frameRasterizerTimeMicros] in milliseconds.
  final double worstFrameRasterizerTime;

  /// The largest value of [frameRasterizerTimeMicros] in milliseconds.
  final int missedFrameRasterizerBudget;

  Map<String, dynamic> get summary => <String, dynamic>{
    'average_frame_build_time_millis': averageFrameBuildTime,
    '90th_percentile_frame_build_time_millis': percentileFrameBuildTime90,
    '99th_percentile_frame_build_time_millis': percentileFrameBuildTime99,
    'worst_frame_build_time_millis': worstFrameBuildTime,
    'missed_frame_build_budget_count': missedFrameBuildBudget,
    'average_frame_rasterizer_time_millis': averageFrameRasterizerTime,
    '90th_percentile_frame_rasterizer_time_millis': percentileFrameRasterizerTime90,
    '99th_percentile_frame_rasterizer_time_millis': percentileFrameRasterizerTime99,
    'worst_frame_rasterizer_time_millis': worstFrameRasterizerTime,
    'missed_frame_rasterizer_budget_count': missedFrameRasterizerBudget,
    'frame_count': frameBuildTimeMicros.length,
    'frame_build_times': frameBuildTimeMicros,
    'frame_rasterizer_times': frameRasterizerTimeMicros,
  };
}

// The following helper functions require data sorted

// return the 100*p-th percentile of the data
T _findPercentile<T extends num>(List<T> data, double p) {
  assert(p >= 0 && p <= 1);
  return data[((data.length - 1) * p).round()];
}

// return the number of items in data that > threshold
int _countExceed<T extends num>(List<T> data, T threshold) {
  return data.length - data.indexWhere((T data) => data > threshold);
}
