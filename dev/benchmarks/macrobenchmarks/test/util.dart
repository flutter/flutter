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
Duration get kBuildBudget => _kBuildBudget;
Duration _kBuildBudget = const Duration(milliseconds: 16);

typedef DriveCallback = Future<void> Function(WidgetController controller);

const String _kDebugWarning = '''
┏╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍┓
┇ ⚠    THIS BENCHMARK IS BEING RUN IN DEBUG MODE     ⚠  ┇
┡╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍┦
│                                                       │
│  Numbers obtained from a benchmark while asserts are  │
│  enabled will not accurately reflect the performance  │
│  that will be experienced by end users using release  ╎
│  builds. Benchmarks should be run using this command  ╎
│  line:  "flutter run --profile test_perf_e2e.dart"    ┊
│  or "flutter drive --profile -t test_perf_e2e.dart".  ┊
│                                                       ┊
└─────────────────────────────────────────────────╌┄┈  🐢
''';

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
    debugPrint(_kDebugWarning);
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
  final FrameTimingSummarizer frameTimes = FrameTimingSummarizer();
  final TimingsCallback watcher = frameTimes.addData;
  binding.addTimingsCallback(watcher);
  await action();
  binding.removeTimingsCallback(watcher);
  // TODO(CareF): determine if it's running on firebase and report metric online
  binding.reportData = <String, dynamic>{'performance': frameTimes.summary};
}

class FrameTimingSummarizer {
  FrameTimingSummarizer({this.data}) {
    data ??= <FrameTiming>[];

    _frameBuildTimeMicros = data.map<int>(
      (FrameTiming datum) => datum.buildDuration.inMicroseconds,
    ).toList();
    final List<int> frameBuildTimeMicrosSorted = List<int>.from(frameBuildTimeMicros)..sort();
    _averageFrameBuildTime = frameBuildTimeMicros.reduce((int a, int b) => a+b) / 1E3 / data.length;
    _percentileFrameBuildTime90 = _findPercentile(frameBuildTimeMicrosSorted, 0.90) / 1E3;
    _percentileFrameBuildTime99 = _findPercentile(frameBuildTimeMicrosSorted, 0.99) / 1E3;
    _worstFrameBuildTime = frameBuildTimeMicrosSorted.last / 1E3;
    _missedFrameBuildBudget = _countExceed(frameBuildTimeMicrosSorted, kBuildBudget.inMicroseconds);

    _frameRasterizerTimeMicros = data.map<int>(
      (FrameTiming datum) => datum.rasterDuration.inMicroseconds,
    ).toList();
    final List<int> frameRasterizerTimeMicrosSorted = List<int>.from(frameBuildTimeMicros)..sort();
    _averageFrameRasterizerTime = frameRasterizerTimeMicros.reduce((int a, int b) => a+b) / 1E3 / data.length;
    _percentileFrameRasterizerTime90 = _findPercentile(frameRasterizerTimeMicrosSorted, 0.90) / 1E3;
    _percentileFrameRasterizerTime99 = _findPercentile(frameRasterizerTimeMicrosSorted, 0.90) / 1E3;
    _worstFrameRasterizerTime = frameRasterizerTimeMicrosSorted.last / 1E3;
    _missedFrameRasterizerBudget = _countExceed(frameRasterizerTimeMicrosSorted, kBuildBudget.inMicroseconds);
  }

  /// Collected raw data.
  List<FrameTiming> data;

  /// List of frame build time in microseconds
  List<int> get frameBuildTimeMicros => _frameBuildTimeMicros;
  List<int> _frameBuildTimeMicros;

  /// List of frame rasterizer time in microseconds
  List<int> get frameRasterizerTimeMicros => _frameRasterizerTimeMicros;
  List<int> _frameRasterizerTimeMicros;

  /// The average value of [frameBuildTimeMicros] in milliseconds.
  double get averageFrameBuildTime => _averageFrameBuildTime;
  double _averageFrameBuildTime;

  /// The 90-th percentile value of [frameBuildTimeMicros] in milliseconds
  double get percentileFrameBuildTime90 => _percentileFrameBuildTime90;
  double _percentileFrameBuildTime90;

  /// The 99-th percentile value of [frameBuildTimeMicros] in milliseconds
  double get percentileFrameBuildTime99 => _percentileFrameBuildTime99;
  double _percentileFrameBuildTime99;

  /// The largest value of [frameBuildTimeMicros] in milliseconds
  double get worstFrameBuildTime => _worstFrameBuildTime;
  double _worstFrameBuildTime;

  /// Number of items in [frameBuildTimeMicros] that's greater than [kBuildBudget]
  int get missedFrameBuildBudget => _missedFrameBuildBudget;
  int _missedFrameBuildBudget;

  /// The average value of [frameRasterizerTimeMicros] in milliseconds.
  double get averageFrameRasterizerTime => _averageFrameRasterizerTime;
  double  _averageFrameRasterizerTime;

  /// The 90-th percentile value of [frameRasterizerTimeMicros] in milliseconds.
  double get percentileFrameRasterizerTime90 => _percentileFrameRasterizerTime90;
  double _percentileFrameRasterizerTime90;

  /// The 99-th percentile value of [frameRasterizerTimeMicros] in milliseconds.
  double get percentileFrameRasterizerTime99 => _percentileFrameRasterizerTime99;
  double _percentileFrameRasterizerTime99;

  /// The largest value of [frameRasterizerTimeMicros] in milliseconds.
  double get worstFrameRasterizerTime => _worstFrameRasterizerTime;
  double _worstFrameRasterizerTime;

  /// The largest value of [frameRasterizerTimeMicros] in milliseconds.
  int get missedFrameRasterizerBudget => _missedFrameRasterizerBudget;
  int _missedFrameRasterizerBudget;


  void addData(List<FrameTiming> timings) {
    data += timings;
  }

  Map<String, dynamic> get summary {
    if (data.isEmpty) {
      throw ArgumentError('durations is empty!');
    }

    return <String, dynamic>{
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
      'frame_count': data.length,
      'frame_build_times': frameBuildTimeMicros,
      'frame_rasterizer_times': frameRasterizerTimeMicros,
    };
  }
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
