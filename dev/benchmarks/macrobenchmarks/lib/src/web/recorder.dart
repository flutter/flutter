// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:meta/meta.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Minimum number of samples collected by a benchmark irrespective of noise
/// levels.
const int _kMinSampleCount = 50;

/// Maximum number of samples collected.
///
/// If the noise doesn't settle down before we reach the max we'll report noisy
/// results.
const int _kMaxSampleCount = 10 * _kMinSampleCount;

/// The number of samples used to extract metrics, such as noise, means,
/// max/min values.
const int _kMeasuredSampleCount = 10;

/// Maximum tolerated noise level.
///
/// A benchmark continues running until a noise level below this threshold is
/// reached.
const double _kNoiseThreshold = 0.02; // 2%

/// Signature for a function that draws a frame.
///
/// Such function is passed to [Recorder.recordFrame] to record
/// performance metrics of a single frame.
typedef DrawFrameCallback = void Function(FrameMetricsBuilder);

Duration timeAction(VoidCallback action) {
  final Stopwatch stopwatch = Stopwatch()..start();
  action();
  stopwatch.stop();
  return stopwatch.elapsed;
}

abstract class RawRecorder extends Recorder {
  RawRecorder({ @required String name }): super._(name);

  @mustCallSuper
  void onBeginFrame() {}

  /// Called on every frame.
  ///
  /// An implementation should exercise the [sceneBuilder] to build a frame.
  /// However, it must not call [SceneBuilder.build] or [Window.render].
  /// Instead the benchmark harness will call them and time them appropriately.
  ///
  /// The callback is given a [FrameMetricsBuilder] that can be populated
  /// with various frame-related metrics, such as paint time and layout time.
  void onDrawFrame(SceneBuilder sceneBuilder, FrameMetricsBuilder metricsBuilder);

  @override
  Future<Profile> run() {
    final Completer<Profile> profileCompleter = Completer<Profile>();
    window.onBeginFrame = (_) {
      onBeginFrame();
    };
    window.onDrawFrame = () {
      final FrameMetricsBuilder metricsBuilder = FrameMetricsBuilder();
      Duration sceneBuildDuration;
      Duration windowRenderDuration;
      final Duration drawFrameDuration = timeAction(() {
        final SceneBuilder sceneBuilder = SceneBuilder();
        onDrawFrame(sceneBuilder, metricsBuilder);
        sceneBuildDuration = timeAction(() {
          final Scene scene = sceneBuilder.build();
          windowRenderDuration = timeAction(() {
            window.render(scene);
          });
        });
      });
      _frames.add(FrameMetrics(
        drawFrameDuration: drawFrameDuration,
        sceneBuildDuration: sceneBuildDuration,
        windowRenderDuration: windowRenderDuration,
      ));
      if (_shouldContinue()) {
        window.scheduleFrame();
      } else {
        final Profile profile = _generateProfile();
        profileCompleter.complete(profile);
      }
    };
    window.scheduleFrame();
    return profileCompleter.future;
  }
}

abstract class WidgetRecorder extends Recorder {
  WidgetRecorder({ @required String name }): super._(name);

  Widget createWidget();

  final Completer<Profile> profileCompleter = Completer<Profile>();

  Stopwatch drawFrameStopwatch;

  void frameWillDraw() {
    drawFrameStopwatch = Stopwatch()..start();
  }

  void frameDidDraw() {
    _frames.add(FrameMetrics(
      drawFrameDuration: drawFrameStopwatch.elapsed,
      sceneBuildDuration: null,
      windowRenderDuration: null,
    ));
    if (_shouldContinue()) {
      window.scheduleFrame();
    } else {
      final Profile profile = _generateProfile();
      profileCompleter.complete(profile);
    }
  }

  @override
  Future<Profile> run() {
    final RecordingWidgetsBinding binding = RecordingWidgetsBinding.ensureInitialized();
    final Widget widget = createWidget();
    binding.beginRecording(this, widget);
    return profileCompleter.future;
  }
}

/// Pumps frames and records frame metrics.
abstract class Recorder {
  Recorder._(this.name);

  /// The name of the benchmark being recorded.
  final String name;

  /// Frame metrics recorded during a single benchmark run.
  final List<FrameMetrics> _frames = <FrameMetrics>[];

  Future<Profile> run();

  /// Decides whether the data collected so far is sufficient to stop, or
  /// whether the benchmark should continue collecting more data.
  ///
  /// The signals used are sample size, noise, and duration.
  bool _shouldContinue() {
    // Run through a minimum number of frames.
    if (_frames.length < _kMinSampleCount) {
      return true;
    }

    // If the benchmark has run long enough, stop it, even if it's noisy under
    // the assumption that this benchmark is always noisy and there's nothing
    // we can do about it.
    if (_frames.length > _kMaxSampleCount) {
      return false;
    }

    // If the profile is not noisy, stop the benchmark.
    final Profile profile = _generateProfile();

    if (profile.drawFrameDurationNoise > _kNoiseThreshold) {
      // Still too noisy.
      return true;
    }

    return false;
  }

  Profile _generateProfile() {
    final List<FrameMetrics> measuredFrames = _frames.sublist(_frames.length - _kMeasuredSampleCount);
    final Iterable<double> noiseCheckDrawFrameTimes = measuredFrames
      .map<double>((FrameMetrics metric) => metric.drawFrameDuration.inMicroseconds.toDouble());
    final double averageDrawFrameDuration = computeMean(noiseCheckDrawFrameTimes);
    final double drawFrameDurationNoise = computeStandardDeviationForPopulation(noiseCheckDrawFrameTimes) / averageDrawFrameDuration;

    return Profile(
      name: name,
      averageDrawFrameDurationMicros: averageDrawFrameDuration,
      drawFrameDurationNoise: drawFrameDurationNoise,
      frames: measuredFrames,
    );
  }
}

/// Contains metrics for a series of rendered frames.
@immutable
class Profile {
  Profile({
    @required this.name,
    @required this.drawFrameDurationNoise,
    @required this.averageDrawFrameDurationMicros,
    @required List<FrameMetrics> frames,
  }) : frames = List<FrameMetrics>.unmodifiable(frames);

  /// The name of the benchmark that produced this profile.
  final String name;

  final double averageDrawFrameDurationMicros;
  final double drawFrameDurationNoise;

  /// Frame metrics recorded during a single benchmark run.
  final List<FrameMetrics> frames;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'averageDrawFrameDuration': averageDrawFrameDurationMicros,
      'drawFrameDurationNoise': drawFrameDurationNoise,
      'frames': frames.map((FrameMetrics frameMetrics) => frameMetrics.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return _formatToStringLines(<String>[
      'benchmark: $name',
      'averageDrawFrameDuration: $averageDrawFrameDurationMicrosμs',
      'drawFrameDurationNoise: ${drawFrameDurationNoise * 100}%',
      'frames:',
      ...frames.expand((FrameMetrics frame) => '$frame\n'.split('\n').map((String line) => '- $line\n')),
    ]);
  }
}

/// Contains metrics for a single frame.
class FrameMetrics {
  FrameMetrics({
    @required this.drawFrameDuration,
    @required this.sceneBuildDuration,
    @required this.windowRenderDuration,
  });

  /// Total amount of time taken by [Window.onDrawFrame].
  final Duration drawFrameDuration;

  /// The amount of time [SceneBuilder.build] took.
  final Duration sceneBuildDuration;

  /// The amount of time [Window.render] took.
  final Duration windowRenderDuration;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'drawFrameDuration': drawFrameDuration.inMicroseconds,
      if (sceneBuildDuration != null)
        'sceneBuildDuration': sceneBuildDuration.inMicroseconds,
      if (windowRenderDuration != null)
        'windowRenderDuration': windowRenderDuration.inMicroseconds,
    };
  }

  @override
  String toString() {
    return _formatToStringLines(<String>[
      'drawFrameDuration: ${drawFrameDuration.inMicroseconds}μs',
      if (sceneBuildDuration != null)
        'sceneBuildDuration: ${sceneBuildDuration.inMicroseconds}μs',
      if (windowRenderDuration != null)
        'windowRenderDuration: ${windowRenderDuration.inMicroseconds}μs',
    ]);
  }
}

String _formatToStringLines(List<String> lines) {
  return lines
    .map((String line) => line.trim())
    .where((String line) => line.isNotEmpty)
    .join('\n');
}

class FrameMetricsBuilder {

}

/// Computes the arithmetic mean (or average) of given [values].
double computeMean(Iterable<double> values) {
  final double sum = values.reduce((double a, double b) => a + b);
  return sum / values.length;
}

/// Computes population standard deviation.
///
/// Unlike sample standard deviation, which divides by N - 1, this divides by N.
///
/// See also:
///
/// * https://en.wikipedia.org/wiki/Standard_deviation
double computeStandardDeviationForPopulation(Iterable<double> population) {
  final double mean = computeMean(population);
  final double sumOfSquaredDeltas = population.fold<double>(
    0.0,
    (double previous, double value) => previous += math.pow(value - mean, 2),
  );
  return math.sqrt(sumOfSquaredDeltas / population.length);
}

/// A variant of [WidgetsBinding] that collaborates with a [Recorder] to decide
/// when to stop pumping frames.
///
/// A normal [WidgetsBinding] typically always pumps frames whenever a widget
/// instructs it to do so by calling [scheduleFrame] (transitively via
/// `setState`). This binding will stop pumping new frames as soon as benchmark
/// parameters are satisfactory (e.g. when the metric noise levels become low
/// enough).
class RecordingWidgetsBinding extends BindingBase with GestureBinding, ServicesBinding, SchedulerBinding, PaintingBinding, SemanticsBinding, RendererBinding, WidgetsBinding {
  /// Makes an instance of [RecordingWidgetsBinding] the current binding.
  static RecordingWidgetsBinding ensureInitialized() {
    if (WidgetsBinding.instance == null)
      RecordingWidgetsBinding();
    return WidgetsBinding.instance as RecordingWidgetsBinding;
  }

  WidgetRecorder recorder;

  void beginRecording(WidgetRecorder recorder, Widget widget) {
    this.recorder = recorder;
    runApp(widget);
  }

  @override
  void scheduleFrame() {
    if (recorder._shouldContinue()) {
      super.scheduleFrame();
    }
  }

  @override
  void handleDrawFrame() {
    recorder.frameWillDraw();
    super.handleDrawFrame();
    recorder.frameDidDraw();
  }
}
