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

/// Maximum number of samples collected by a benchmark irrespective of noise
/// levels.
///
/// If the noise doesn't settle down before we reach the max we'll report noisy
/// results assuming the benchmarks is simply always noisy.
const int _kMaxSampleCount = 10 * _kMinSampleCount;

/// The number of samples used to extract metrics, such as noise, means,
/// max/min values.
const int _kMeasuredSampleCount = 10;

/// Maximum tolerated noise level.
///
/// A benchmark continues running until a noise level below this threshold is
/// reached.
const double _kNoiseThreshold = 0.05; // 5%

/// Measures the amount of time [action] takes.
Duration timeAction(VoidCallback action) {
  final Stopwatch stopwatch = Stopwatch()..start();
  action();
  stopwatch.stop();
  return stopwatch.elapsed;
}

/// Base class for benchmark recorders.
///
/// Each benchmark recorder has a [name] and a [run] method at a minimum.
abstract class Recorder<T extends Profile<dynamic>> {
  const Recorder._(this.name);

  /// The name of the benchmark.
  ///
  /// The results displayed in the Flutter Dashboard will use this name as a
  /// prefix.
  final String name;

  /// The implementation of the benchmark that will produce a [Profile].
  Future<T> run();
}

/// A recorder for benchmarking raw execution of Dart code.
///
/// This is useful for benchmarks that don't need frames or widgets.
///
/// Example:
///
/// ```
/// class BenchForLoop extends RawRecorder {
///   BenchForLoop() : super(name: benchmarkName);
///
///   static const String benchmarkName = 'for_loop';
///
///   @override
///   void body() {
///     double x = 0;
///     for (int i = 0; i < 10000000; i++) {
///       x *= 1.5;
///     }
///   }
/// }
/// ```
abstract class RawRecorder extends Recorder<RawProfile> {
  RawRecorder({@required String name}) : super._(name);

  /// Called before each benchmark run.
  ///
  /// This is useful for doing any setup work that's needed for the benchmark,
  /// but shouldn't count towards the benchmark numbers.
  void setUp() {}

  /// Called after each benchmark run.
  ///
  /// This is useful for doing clean up work that shouldn't count towards
  /// benchmark numbers.
  void tearDown() {}

  /// The body of the benchmark.
  ///
  /// This is the part that will be measured by the benchmark.
  void body();

  final List<Duration> _durations = <Duration>[];

  @override
  @nonVirtual
  Future<RawProfile> run() async {
    RawProfile profile;
    do {
      await Future<void>.value(null);
      _durations.add(_runOnce());
      profile = generateProfile();
    } while (profile.shouldContinue());
    return profile;
  }

  Duration _runOnce() {
    setUp();
    final Duration duration = timeAction(body);
    tearDown();
    return duration;
  }

  RawProfile generateProfile() {
    return RawProfile.fromDurations(name: name, durations: _durations);
  }
}

/// A recorder for benchmarking interactions with the engine without the
/// framework by directly exercising [SceneBuilder].
///
/// To implement a benchmark, extend this class and implement [onDrawFrame].
///
/// Example:
///
/// ```
/// class BenchDrawCircle extends SceneBuilderRecorder {
///   BenchDrawCircle() : super(name: benchmarkName);
///
///   static const String benchmarkName = 'draw_circle';
///
///   @override
///   void onDrawFrame(SceneBuilder sceneBuilder, FrameMetricsBuilder metricsBuilder) {
///     final PictureRecorder pictureRecorder = PictureRecorder();
///     final Canvas canvas = Canvas(pictureRecorder);
///     final Paint paint = Paint()..color = const Color.fromARGB(255, 255, 0, 0);
///     final Size windowSize = window.physicalSize;
///     canvas.drawCircle(windowSize.center(Offset.zero), 50.0, paint);
///     final Picture picture = pictureRecorder.endRecording();
///     sceneBuilder.addPicture(picture);
///   }
/// }
/// ```
abstract class SceneBuilderRecorder extends FrameRecorder {
  SceneBuilderRecorder({@required String name}) : super._(name);

  /// Called from [Window.onBeginFrame].
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
  void onDrawFrame(SceneBuilder sceneBuilder);

  @override
  Future<FrameProfile> run() {
    final Completer<FrameProfile> profileCompleter = Completer<FrameProfile>();
    window.onBeginFrame = (_) {
      onBeginFrame();
    };
    window.onDrawFrame = () {
      Duration sceneBuildDuration;
      Duration windowRenderDuration;
      final Duration drawFrameDuration = timeAction(() {
        final SceneBuilder sceneBuilder = SceneBuilder();
        onDrawFrame(sceneBuilder);
        sceneBuildDuration = timeAction(() {
          final Scene scene = sceneBuilder.build();
          windowRenderDuration = timeAction(() {
            window.render(scene);
          });
        });
      });
      _frames.add(FrameMetrics._(
        drawFrameDuration: drawFrameDuration,
        sceneBuildDuration: sceneBuildDuration,
        windowRenderDuration: windowRenderDuration,
      ));

      final FrameProfile profile = generateProfile();
      if (profile.shouldContinue()) {
        window.scheduleFrame();
      } else {
        profileCompleter.complete(profile);
      }
    };
    window.scheduleFrame();
    return profileCompleter.future;
  }
}

/// A recorder for benchmarking interactions with the framework by creating
/// widgets.
///
/// To implement a benchmark, extend this class and implement [createWidget].
///
/// Example:
///
/// ```
/// class BenchListView extends WidgetRecorder {
///   BenchListView() : super(name: benchmarkName);
///
///   static const String benchmarkName = 'bench_list_view';
///
///   @override
///   Widget createWidget() {
///     return Directionality(
///       textDirection: TextDirection.ltr,
///       child: _TestListViewWidget(),
///     );
///   }
/// }
///
/// class _TestListViewWidget extends StatefulWidget {
///   @override
///   State<StatefulWidget> createState() {
///     return _TestListViewWidgetState();
///   }
/// }
///
/// class _TestListViewWidgetState extends State<_TestListViewWidget> {
///   ScrollController scrollController;
///
///   @override
///   void initState() {
///     super.initState();
///     scrollController = ScrollController();
///     Timer.run(() async {
///       bool forward = true;
///       while (true) {
///         await scrollController.animateTo(
///           forward ? 300 : 0,
///           curve: Curves.linear,
///           duration: const Duration(seconds: 1),
///         );
///         forward = !forward;
///       }
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return ListView.builder(
///       controller: scrollController,
///       itemCount: 10000,
///       itemBuilder: (BuildContext context, int index) {
///         return Text('Item #$index');
///       },
///     );
///   }
/// }
/// ```
abstract class WidgetRecorder extends FrameRecorder
    implements RecordingWidgetsBindingListener {
  WidgetRecorder({@required String name}) : super._(name);

  /// Creates a widget to be benchmarked.
  ///
  /// The widget must create its own animation to drive the benchmark. The
  /// animation should continue indefinitely. The benchmark harness will stop
  /// pumping frames automatically as soon as the noise levels are sufficiently
  /// low.
  Widget createWidget();

  final Completer<FrameProfile> _profileCompleter = Completer<FrameProfile>();

  Stopwatch _drawFrameStopwatch;

  @override
  void _frameWillDraw() {
    _drawFrameStopwatch = Stopwatch()..start();
  }

  @override
  void _frameDidDraw() {
    _frames.add(FrameMetrics._(
      drawFrameDuration: _drawFrameStopwatch.elapsed,
      sceneBuildDuration: null,
      windowRenderDuration: null,
    ));

    final FrameProfile profile = generateProfile();
    if (profile.shouldContinue()) {
      window.scheduleFrame();
    } else {
      _profileCompleter.complete(profile);
    }
  }

  @override
  void _onError(dynamic error, StackTrace stackTrace) {
    _profileCompleter.completeError(error, stackTrace);
  }

  @override
  Future<FrameProfile> run() {
    final _RecordingWidgetsBinding binding =
        _RecordingWidgetsBinding.ensureInitialized();
    final Widget widget = createWidget();
    binding._beginRecording(this, widget);
    return _profileCompleter.future;
  }
}

/// A recorder for measuring the performance of building a widget from scratch
/// starting from an empty frame.
///
/// The recorder will call [createWidget] and render it, then it will pump
/// another frame that clears the screen. It repeats this process, measuring the
/// performance of frames that render the widget and ignoring the frames that
/// clear the screen.
abstract class WidgetBuildRecorder extends FrameRecorder
    implements RecordingWidgetsBindingListener {
  WidgetBuildRecorder({@required String name}) : super._(name);

  /// Creates a widget to be benchmarked.
  ///
  /// The widget is not expected to animate as we only care about construction
  /// of the widget. If you are interested in benchmarking an animation,
  /// consider using [WidgetRecorder].
  Widget createWidget();

  final Completer<FrameProfile> _profileCompleter = Completer<FrameProfile>();

  Stopwatch _drawFrameStopwatch;

  /// Whether in this frame we should call [createWidget] and render it.
  ///
  /// If false, then this frame will clear the screen.
  bool _showWidget = true;

  /// The state that hosts the widget under test.
  _WidgetBuildRecorderHostState _hostState;

  Widget _getWidgetForFrame() {
    if (_showWidget) {
      return createWidget();
    } else {
      return null;
    }
  }

  @override
  void _frameWillDraw() {
    _drawFrameStopwatch = Stopwatch()..start();
  }

  @override
  void _frameDidDraw() {
    // Only record frames that show the widget.
    if (_showWidget) {
      _frames.add(FrameMetrics._(
        drawFrameDuration: _drawFrameStopwatch.elapsed,
        sceneBuildDuration: null,
        windowRenderDuration: null,
      ));
    }

    final FrameProfile profile = generateProfile();
    if (profile.shouldContinue()) {
      _showWidget = !_showWidget;
      _hostState._setStateTrampoline();
    } else {
      _profileCompleter.complete(profile);
    }
  }

  @override
  void _onError(dynamic error, StackTrace stackTrace) {
    _profileCompleter.completeError(error, stackTrace);
  }

  @override
  Future<FrameProfile> run() {
    final _RecordingWidgetsBinding binding =
        _RecordingWidgetsBinding.ensureInitialized();
    binding._beginRecording(this, _WidgetBuildRecorderHost(this));
    return _profileCompleter.future;
  }
}

/// Hosts widgets created by [WidgetBuildRecorder].
class _WidgetBuildRecorderHost extends StatefulWidget {
  const _WidgetBuildRecorderHost(this.recorder);

  final WidgetBuildRecorder recorder;

  @override
  State<StatefulWidget> createState() =>
      recorder._hostState = _WidgetBuildRecorderHostState();
}

class _WidgetBuildRecorderHostState extends State<_WidgetBuildRecorderHost> {
  // This is just to bypass the @protected on setState.
  void _setStateTrampoline() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: widget.recorder._getWidgetForFrame(),
    );
  }
}

/// Pumps frames and records frame metrics.
abstract class FrameRecorder extends Recorder<FrameProfile> {
  FrameRecorder._(String name) : super._(name);

  /// Frame metrics recorded during a single benchmark run.
  final List<FrameMetrics> _frames = <FrameMetrics>[];

  FrameProfile generateProfile() {
    return FrameProfile.fromFrames(name: name, frames: _frames);
  }
}

/// Base class for a profile collected from running a benchmark.
@immutable
abstract class Profile<T> {
  Profile._(this.name, this.entirePopulation)
      : assert(name != null),
        assert(entirePopulation != null),
        measuredPopulation = _getMeasuredSample(entirePopulation);

  /// The name of the benchmark that produced this profile.
  final String name;

  /// The entire population collected in the benchmark.
  final List<T> entirePopulation;

  /// Subset of [entirePopulation] that is considered for benchmark measurement.
  final List<T> measuredPopulation;

  /// List of times in μs mapped from [measuredPopulation].
  List<int> get measuredMicros =>
      measuredPopulation.map(getMicrosFromValue).toList();

  double get _average => _computeMean(measuredMicros);

  double get _standardDeviation =>
      _computeStandardDeviationForPopulation(measuredMicros);

  double get _noise => _standardDeviation / _average;

  String get _noiseString => '${(_noise * 100).toStringAsFixed(2)}%';

  /// Returns the time in μs for the given value from the population.
  int getMicrosFromValue(T value);

  /// Returns a JSON representation of the profile that will be sent to the
  /// server.
  Map<String, dynamic> toJson();

  /// Returns a description of the [Profile] that will be formatted and printed
  /// to the console/terminal.
  List<String> toDescription();

  /// Decides whether the data collected so far is sufficient to stop, or
  /// whether the benchmark should continue collecting more data.
  ///
  /// The signals used are sample size, noise, and duration.
  bool shouldContinue() {
    // Collect enough population before considering to stop.
    if (entirePopulation.length < _kMinSampleCount) {
      return true;
    }

    // Is it still too noisy?
    if (_noise > _kNoiseThreshold) {
      // If the benchmark has run long enough, stop it, even if it's noisy under
      // the assumption that this benchmark is always noisy and there's nothing
      // we can do about it.
      if (entirePopulation.length > _kMaxSampleCount) {
        print(
          'WARNING: Benchmark noise did not converge below ${_kNoiseThreshold * 100}%. '
          'Stopping because it reached the maximum number of samples $_kMaxSampleCount. '
          'Noise level is $_noiseString.',
        );
        return false;
      }

      // Keep running.
      return true;
    }

    print(
      'SUCCESS: Benchmark converged below ${_kNoiseThreshold * 100}%. '
      'Noise level is $_noiseString.',
    );
    return false;
  }

  @override
  String toString() {
    return _formatToStringLines(toDescription());
  }
}

/// Contains metrics for raw benchmark runs that only record durations.
@immutable
class RawProfile extends Profile<Duration> {
  RawProfile.fromDurations({
    @required String name,
    @required List<Duration> durations,
  }) : super._(name, durations);

  @override
  int getMicrosFromValue(Duration value) => value.inMicroseconds;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'benchmarkScoreKeys': <String>['average'],
      'name': name,
      'average': _average,
      'noise': _noise,
      'durations': measuredMicros,
    };
  }

  @override
  List<String> toDescription() {
    return <String>[
      'benchmark: $name',
      'average: $_average μs',
      'noise: $_noiseString',
      'durations:',
      ...measuredMicros.map((int duration) => '- $duration μs'),
    ];
  }
}

/// Contains metrics for a series of rendered frames.
@immutable
class FrameProfile extends Profile<FrameMetrics> {
  FrameProfile.fromFrames({
    @required String name,
    @required List<FrameMetrics> frames,
  }) : super._(name, frames);

  @override
  int getMicrosFromValue(FrameMetrics value) {
    return value.drawFrameDuration.inMicroseconds;
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'benchmarkScoreKeys': <String>['averageDrawFrameDuration'],
      'averageDrawFrameDuration': _average,
      'drawFrameDurationNoise': _noise,
      'frames': measuredPopulation
          .map((FrameMetrics frameMetrics) => frameMetrics.toJson())
          .toList(),
    };
  }

  @override
  List<String> toDescription() {
    return <String>[
      'benchmark: $name',
      'averageDrawFrameDuration: $_average μs',
      'drawFrameDurationNoise: $_noiseString',
      'frames:',
      ...measuredPopulation.expand((FrameMetrics frame) =>
          '$frame\n'.split('\n').map((String line) => '- $line\n')),
    ];
  }
}

/// Contains metrics for a single frame.
class FrameMetrics {
  FrameMetrics._({
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

List<T> _getMeasuredSample<T>(List<T> population) {
  if (population.length <= _kMeasuredSampleCount) {
    return List<T>.unmodifiable(population);
  }

  // We only want the last [_kMeasuredSampleCount] items.
  return List<T>.unmodifiable(
    population.sublist(population.length - _kMeasuredSampleCount),
  );
}

/// Computes the arithmetic mean (or average) of given [values].
double _computeMean(Iterable<num> values) {
  final num sum = values.reduce((num a, num b) => a + b);
  return sum / values.length;
}

/// Computes population standard deviation.
///
/// Unlike sample standard deviation, which divides by N - 1, this divides by N.
///
/// See also:
///
/// * https://en.wikipedia.org/wiki/Standard_deviation
double _computeStandardDeviationForPopulation(Iterable<num> population) {
  final double mean = _computeMean(population);
  final double sumOfSquaredDeltas = population.fold<double>(
    0.0,
    (double previous, num value) => previous += math.pow(value - mean, 2),
  );
  return math.sqrt(sumOfSquaredDeltas / population.length);
}

/// Implemented by recorders that use [_RecordingWidgetsBinding] to receive
/// frame life-cycle calls.
abstract class RecordingWidgetsBindingListener {
  /// Generate a profile for the benchmark runs up to this point in time.
  Profile<dynamic> generateProfile();

  /// Called just before calling [SchedulerBinding.handleDrawFrame].
  void _frameWillDraw();

  /// Called immediately after calling [SchedulerBinding.handleDrawFrame].
  void _frameDidDraw();

  /// Reports an error.
  ///
  /// The implementation is expected to halt benchmark execution as soon as possible.
  void _onError(dynamic error, StackTrace stackTrace);
}

/// A variant of [WidgetsBinding] that collaborates with a [Recorder] to decide
/// when to stop pumping frames.
///
/// A normal [WidgetsBinding] typically always pumps frames whenever a widget
/// instructs it to do so by calling [scheduleFrame] (transitively via
/// `setState`). This binding will stop pumping new frames as soon as benchmark
/// parameters are satisfactory (e.g. when the metric noise levels become low
/// enough).
class _RecordingWidgetsBinding extends BindingBase
    with
        GestureBinding,
        ServicesBinding,
        SchedulerBinding,
        PaintingBinding,
        SemanticsBinding,
        RendererBinding,
        WidgetsBinding {
  /// Makes an instance of [_RecordingWidgetsBinding] the current binding.
  static _RecordingWidgetsBinding ensureInitialized() {
    if (WidgetsBinding.instance == null) {
      _RecordingWidgetsBinding();
    }
    return WidgetsBinding.instance as _RecordingWidgetsBinding;
  }

  RecordingWidgetsBindingListener _listener;
  bool _hasErrored = false;

  void _beginRecording(RecordingWidgetsBindingListener recorder, Widget widget) {
    final FlutterExceptionHandler originalOnError = FlutterError.onError;

    // Fail hard and fast on errors. Benchmarks should not have any errors.
    FlutterError.onError = (FlutterErrorDetails details) {
      if (_hasErrored) {
        return;
      }
      _listener._onError(details.exception, details.stack);
      _hasErrored = true;
      originalOnError(details);
    };
    _listener = recorder;
    runApp(widget);
  }

  /// To avoid calling [Profile.shouldContinue] every time [scheduleFrame] is
  /// called, we cache this value at the beginning of the frame.
  bool _benchmarkStopped = false;

  @override
  void handleBeginFrame(Duration rawTimeStamp) {
    // Don't keep on truckin' if there's an error.
    if (_hasErrored) {
      return;
    }
    _benchmarkStopped = !_listener.generateProfile().shouldContinue();
    super.handleBeginFrame(rawTimeStamp);
  }

  @override
  void scheduleFrame() {
    // Don't keep on truckin' if there's an error.
    if (!_benchmarkStopped && !_hasErrored) {
      super.scheduleFrame();
    }
  }

  @override
  void handleDrawFrame() {
    // Don't keep on truckin' if there's an error.
    if (_hasErrored) {
      return;
    }
    _listener._frameWillDraw();
    super.handleDrawFrame();
    _listener._frameDidDraw();
  }
}
