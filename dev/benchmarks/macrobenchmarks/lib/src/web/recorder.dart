// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
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
const int kMinSampleCount = 50;

/// Maximum number of samples collected by a benchmark irrespective of noise
/// levels.
///
/// If the noise doesn't settle down before we reach the max we'll report noisy
/// results assuming the benchmarks is simply always noisy.
const int kMaxSampleCount = 10 * kMinSampleCount;

/// The number of samples used to extract metrics, such as noise, means,
/// max/min values.
///
/// Keep this constant in sync with the same constant defined in `dev/devicelab/lib/framework/browser.dart`.
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

/// A function that performs asynchronous work.
typedef AsyncVoidCallback = Future<void> Function();

/// Runs the benchmark using the given [recorder].
///
/// Notifies about "set up" and "tear down" events via the [setUpAllDidRun]
/// and [tearDownAllWillRun] callbacks.
@sealed
class Runner {
  /// Creates a runner for the [recorder].
  ///
  /// All arguments must not be null.
  Runner({
    @required this.recorder,
    @required this.setUpAllDidRun,
    @required this.tearDownAllWillRun,
  });

  /// The recorder that will run and record the benchmark.
  final Recorder recorder;

  /// Called immediately after [Recorder.setUpAll] future is resolved.
  ///
  /// This is useful, for example, to kick off a profiler or a tracer such that
  /// the "set up" computations are not included in the metrics.
  final AsyncVoidCallback setUpAllDidRun;

  /// Called just before calling [Recorder.tearDownAll].
  ///
  /// This is useful, for example, to stop a profiler or a tracer such that
  /// the "tear down" computations are not included in the metrics.
  final AsyncVoidCallback tearDownAllWillRun;

  /// Runs the benchmark and reports the results.
  Future<Profile> run() async {
    await recorder.setUpAll();
    await setUpAllDidRun();
    final Profile profile = await recorder.run();
    await tearDownAllWillRun();
    await recorder.tearDownAll();
    return profile;
  }
}

/// Base class for benchmark recorders.
///
/// Each benchmark recorder has a [name] and a [run] method at a minimum.
abstract class Recorder {
  Recorder._(this.name);

  /// The name of the benchmark.
  ///
  /// The results displayed in the Flutter Dashboard will use this name as a
  /// prefix.
  final String name;

  /// Called once before all runs of this benchmark recorder.
  ///
  /// This is useful for doing one-time setup work that's needed for the
  /// benchmark.
  Future<void> setUpAll() async {}

  /// The implementation of the benchmark that will produce a [Profile].
  Future<Profile> run();

  /// Called once after all runs of this benchmark recorder.
  ///
  /// This is useful for doing one-time clean up work after the benchmark is
  /// complete.
  Future<void> tearDownAll() async {}
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
///   void body(Profile profile) {
///     profile.record('loop', () {
///       double x = 0;
///       for (int i = 0; i < 10000000; i++) {
///         x *= 1.5;
///       }
///     });
///   }
/// }
/// ```
abstract class RawRecorder extends Recorder {
  RawRecorder({@required String name}) : super._(name);

  /// The body of the benchmark.
  ///
  /// This is the part that records measurements of the benchmark.
  void body(Profile profile);

  @override
  @nonVirtual
  Future<Profile> run() async {
    final Profile profile = Profile(name: name);
    do {
      await Future<void>.delayed(Duration.zero);
      body(profile);
    } while (profile.shouldContinue());
    return profile;
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
///   void onDrawFrame(SceneBuilder sceneBuilder) {
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
abstract class SceneBuilderRecorder extends Recorder {
  SceneBuilderRecorder({@required String name}) : super._(name);

  /// Called from [Window.onBeginFrame].
  @mustCallSuper
  void onBeginFrame() {}

  /// Called on every frame.
  ///
  /// An implementation should exercise the [sceneBuilder] to build a frame.
  /// However, it must not call [SceneBuilder.build] or [Window.render].
  /// Instead the benchmark harness will call them and time them appropriately.
  void onDrawFrame(SceneBuilder sceneBuilder);

  @override
  Future<Profile> run() {
    final Completer<Profile> profileCompleter = Completer<Profile>();
    final Profile profile = Profile(name: name);

    window.onBeginFrame = (_) {
      try {
        startMeasureFrame();
        onBeginFrame();
      } catch (error, stackTrace) {
        profileCompleter.completeError(error, stackTrace);
        rethrow;
      }
    };
    window.onDrawFrame = () {
      try {
        profile.record('drawFrameDuration', () {
          final SceneBuilder sceneBuilder = SceneBuilder();
          onDrawFrame(sceneBuilder);
          profile.record('sceneBuildDuration', () {
            final Scene scene = sceneBuilder.build();
            profile.record('windowRenderDuration', () {
              window.render(scene);
            });
          });
        });
        endMeasureFrame();

        if (profile.shouldContinue()) {
          window.scheduleFrame();
        } else {
          profileCompleter.complete(profile);
        }
      } catch (error, stackTrace) {
        profileCompleter.completeError(error, stackTrace);
        rethrow;
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
abstract class WidgetRecorder extends Recorder implements FrameRecorder {
  WidgetRecorder({@required String name}) : super._(name);

  /// Creates a widget to be benchmarked.
  ///
  /// The widget must create its own animation to drive the benchmark. The
  /// animation should continue indefinitely. The benchmark harness will stop
  /// pumping frames automatically as soon as the noise levels are sufficiently
  /// low.
  Widget createWidget();

  @override
  VoidCallback didStop;

  Profile profile;
  Completer<void> _runCompleter;

  Stopwatch _drawFrameStopwatch;

  @override
  @mustCallSuper
  void frameWillDraw() {
    startMeasureFrame();
    _drawFrameStopwatch = Stopwatch()..start();
  }

  @override
  @mustCallSuper
  void frameDidDraw() {
    endMeasureFrame();
    profile.addDataPoint('drawFrameDuration', _drawFrameStopwatch.elapsed);

    if (profile.shouldContinue()) {
      window.scheduleFrame();
    } else {
      didStop();
      _runCompleter.complete();
    }
  }

  @override
  void _onError(dynamic error, StackTrace stackTrace) {
    _runCompleter.completeError(error, stackTrace);
  }

  @override
  Future<Profile> run() async {
    _runCompleter = Completer<void>();
    final Profile localProfile = profile = Profile(name: name);
    final _RecordingWidgetsBinding binding =
        _RecordingWidgetsBinding.ensureInitialized();
    final Widget widget = createWidget();
    binding._beginRecording(this, widget);

    try {
      await _runCompleter.future;
      return localProfile;
    } finally {
      _runCompleter = null;
      profile = null;
    }
  }
}

/// A recorder for measuring the performance of building a widget from scratch
/// starting from an empty frame.
///
/// The recorder will call [createWidget] and render it, then it will pump
/// another frame that clears the screen. It repeats this process, measuring the
/// performance of frames that render the widget and ignoring the frames that
/// clear the screen.
abstract class WidgetBuildRecorder extends Recorder implements FrameRecorder {
  WidgetBuildRecorder({@required String name}) : super._(name);

  /// Creates a widget to be benchmarked.
  ///
  /// The widget is not expected to animate as we only care about construction
  /// of the widget. If you are interested in benchmarking an animation,
  /// consider using [WidgetRecorder].
  Widget createWidget();

  @override
  VoidCallback didStop;

  Profile profile;
  Completer<void> _runCompleter;

  Stopwatch _drawFrameStopwatch;

  /// Whether in this frame we should call [createWidget] and render it.
  ///
  /// If false, then this frame will clear the screen.
  bool showWidget = true;

  /// The state that hosts the widget under test.
  _WidgetBuildRecorderHostState _hostState;

  Widget _getWidgetForFrame() {
    if (showWidget) {
      return createWidget();
    } else {
      return null;
    }
  }

  @override
  @mustCallSuper
  void frameWillDraw() {
    if (showWidget) {
      startMeasureFrame();
      _drawFrameStopwatch = Stopwatch()..start();
    }
  }

  @override
  @mustCallSuper
  void frameDidDraw() {
    // Only record frames that show the widget.
    if (showWidget) {
      endMeasureFrame();
      profile.addDataPoint('drawFrameDuration', _drawFrameStopwatch.elapsed);
    }

    if (profile.shouldContinue()) {
      showWidget = !showWidget;
      _hostState._setStateTrampoline();
    } else {
      didStop();
      _runCompleter.complete();
    }
  }

  @override
  void _onError(dynamic error, StackTrace stackTrace) {
    _runCompleter.completeError(error, stackTrace);
  }

  @override
  Future<Profile> run() async {
    _runCompleter = Completer<void>();
    final Profile localProfile = profile = Profile(name: name);
    final _RecordingWidgetsBinding binding =
        _RecordingWidgetsBinding.ensureInitialized();
    binding._beginRecording(this, _WidgetBuildRecorderHost(this));

    try {
      await _runCompleter.future;
      return localProfile;
    } finally {
      _runCompleter = null;
      profile = null;
    }
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

/// Series of time recordings indexed in time order.
///
/// It can calculate [average], [standardDeviation] and [noise]. If the amount
/// of data collected is higher than [_kMeasuredSampleCount], then these
/// calculations will only apply to the latest [_kMeasuredSampleCount] data
/// points.
class Timeseries {
  Timeseries(this.name);

  final String name;

  /// List of all the values that have been recorded.
  ///
  /// This list has no limit.
  final List<num> _allValues = <num>[];

  /// List of values that are being used for measurement purposes.
  ///
  /// [average], [standardDeviation] and [noise] are all based on this list, not
  /// the [_allValues] list.
  final List<num> _measuredValues = <num>[];

  /// The total amount of data collected, including ones that were dropped
  /// because of the sample size limit.
  int get count => _allValues.length;

  /// Computes the average value of the measured values.
  double get average => _computeAverage(name, _measuredValues);

  /// Computes the standard deviation of the measured values.
  double get standardDeviation =>
      _computeStandardDeviationForPopulation(name, _measuredValues);

  /// Computes noise as a multiple of the [average] value.
  ///
  /// This value can be multiplied by 100.0 to get noise as a percentage of
  /// the average.
  ///
  /// If [average] is zero, treats the result as perfect score, returns zero.
  double get noise => average > 0.0 ? standardDeviation / average : 0.0;

  /// Adds a value to this timeseries.
  void add(num value) {
    if (value < 0.0) {
      throw StateError(
        'Timeseries $name: negative metric values are not supported. Got: $value',
      );
    }
    _measuredValues.add(value);
    _allValues.add(value);
    // Don't let the [_measuredValues] list grow beyond [_kMeasuredSampleCount].
    if (_measuredValues.length > _kMeasuredSampleCount) {
      _measuredValues.removeAt(0);
    }
  }
}

/// Base class for a profile collected from running a benchmark.
class Profile {
  Profile({@required this.name}) : assert(name != null);

  /// The name of the benchmark that produced this profile.
  final String name;

  /// This data will be used to display cards in the Flutter Dashboard.
  final Map<String, Timeseries> scoreData = <String, Timeseries>{};

  /// This data isn't displayed anywhere. It's stored for completeness purposes.
  final Map<String, dynamic> extraData = <String, dynamic>{};

  /// Invokes [callback] and records the duration of its execution under [key].
  Duration record(String key, VoidCallback callback) {
    final Duration duration = timeAction(callback);
    addDataPoint(key, duration);
    return duration;
  }

  void addDataPoint(String key, Duration duration) {
    scoreData.putIfAbsent(key, () => Timeseries(key)).add(duration.inMicroseconds);
  }

  /// Decides whether the data collected so far is sufficient to stop, or
  /// whether the benchmark should continue collecting more data.
  ///
  /// The signals used are sample size, noise, and duration.
  ///
  /// If any of the timeseries doesn't satisfy the noise requirements, this
  /// method will return true (asking the benchmark to continue collecting
  /// data).
  bool shouldContinue() {
    // If we haven't recorded anything yet, we don't wanna stop now.
    if (scoreData.isEmpty) {
      return true;
    }

    // Accumulates all the messages to be printed when the final decision is to
    // stop collecting data.
    final StringBuffer buffer = StringBuffer();

    final Iterable<bool> shouldContinueList = scoreData.keys.map((String key) {
      final Timeseries timeseries = scoreData[key];

      // Collect enough data points before considering to stop.
      if (timeseries.count < kMinSampleCount) {
        return true;
      }

      // Is it still too noisy?
      if (timeseries.noise > _kNoiseThreshold) {
        // If the timeseries has enough data, stop it, even if it's noisy under
        // the assumption that this benchmark is always noisy and there's nothing
        // we can do about it.
        if (timeseries.count > kMaxSampleCount) {
          buffer.writeln(
            'WARNING: Noise of benchmark "$name.$key" did not converge below '
            '${_ratioToPercent(_kNoiseThreshold)}. Stopping because it reached the '
            'maximum number of samples $kMaxSampleCount. Noise level is '
            '${_ratioToPercent(timeseries.noise)}.',
          );
          return false;
        } else {
          return true;
        }
      }

      buffer.writeln(
        'SUCCESS: Benchmark "$name.$key" converged below ${_ratioToPercent(_kNoiseThreshold)}. '
        'Noise level is ${_ratioToPercent(timeseries.noise)}.',
      );
      return false;
    });

    // If any of the score data needs to continue to be collected, we should
    // return true.
    final bool finalDecision =
        shouldContinueList.any((bool element) => element);
    if (!finalDecision) {
      print(buffer.toString());
    }
    return finalDecision;
  }

  /// Returns a JSON representation of the profile that will be sent to the
  /// server.
  Map<String, dynamic> toJson() {
    final List<String> scoreKeys = <String>[];
    final Map<String, dynamic> json = <String, dynamic>{
      'name': name,
      'scoreKeys': scoreKeys,
    };

    for (final String key in scoreData.keys) {
      scoreKeys.add('$key.average');
      final Timeseries timeseries = scoreData[key];
      json['$key.average'] = timeseries.average;
      json['$key.noise'] = timeseries.noise;
    }

    json.addAll(extraData);

    return json;
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('name: $name');
    for (final String key in scoreData.keys) {
      final Timeseries timeseries = scoreData[key];
      buffer.writeln('$key: (samples=${timeseries.count})');
      buffer.writeln(' | average: ${timeseries.average} μs');
      buffer.writeln(' | noise: ${_ratioToPercent(timeseries.noise)}');
    }
    for (final String key in extraData.keys) {
      final dynamic value = extraData[key];
      if (value is List) {
        buffer.writeln('$key:');
        for (final dynamic item in value) {
          buffer.writeln(' - $item');
        }
      } else {
        buffer.writeln('$key: $value');
      }
    }
    return buffer.toString();
  }
}

/// Computes the arithmetic mean (or average) of given [values].
double _computeAverage(String label, Iterable<num> values) {
  if (values.isEmpty) {
    throw StateError('$label: attempted to compute an average of an empty value list.');
  }

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
double _computeStandardDeviationForPopulation(String label, Iterable<num> population) {
  if (population.isEmpty) {
    throw StateError('$label: attempted to compute the standard deviation of empty population.');
  }
  final double mean = _computeAverage(label, population);
  final double sumOfSquaredDeltas = population.fold<double>(
    0.0,
    (double previous, num value) => previous += math.pow(value - mean, 2),
  );
  return math.sqrt(sumOfSquaredDeltas / population.length);
}

String _ratioToPercent(double value) {
  return '${(value * 100).toStringAsFixed(2)}%';
}

/// Implemented by recorders that use [_RecordingWidgetsBinding] to receive
/// frame life-cycle calls.
abstract class FrameRecorder {
  /// Called by the recorder when it stops recording and doesn't need to collect
  /// any more data.
  set didStop(VoidCallback cb);

  /// Called just before calling [SchedulerBinding.handleDrawFrame].
  void frameWillDraw();

  /// Called immediately after calling [SchedulerBinding.handleDrawFrame].
  void frameDidDraw();

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

  FrameRecorder _recorder;
  bool _hasErrored = false;

  /// To short-circuit all frame lifecycle methods when the benchmark has
  /// stopped collecting data.
  bool _benchmarkStopped = false;

  void _beginRecording(FrameRecorder recorder, Widget widget) {
    if (_recorder != null) {
      throw Exception(
        'Cannot call _RecordingWidgetsBinding._beginRecording more than once',
      );
    }
    final FlutterExceptionHandler originalOnError = FlutterError.onError;

    recorder.didStop = () {
      _benchmarkStopped = true;
    };

    // Fail hard and fast on errors. Benchmarks should not have any errors.
    FlutterError.onError = (FlutterErrorDetails details) {
      _haltBenchmarkWithError(details.exception, details.stack);
      originalOnError(details);
    };
    _recorder = recorder;
    runApp(widget);
  }

  void _haltBenchmarkWithError(dynamic error, StackTrace stackTrace) {
    if (_hasErrored) {
      return;
    }
    _recorder._onError(error, stackTrace);
    _hasErrored = true;
  }

  @override
  void handleBeginFrame(Duration rawTimeStamp) {
    // Don't keep on truckin' if there's an error or the benchmark has stopped.
    if (_hasErrored || _benchmarkStopped) {
      return;
    }
    try {
      super.handleBeginFrame(rawTimeStamp);
    } catch (error, stackTrace) {
      _haltBenchmarkWithError(error, stackTrace);
      rethrow;
    }
  }

  @override
  void scheduleFrame() {
    // Don't keep on truckin' if there's an error or the benchmark has stopped.
    if (_hasErrored || _benchmarkStopped) {
      return;
    }
    super.scheduleFrame();
  }

  @override
  void handleDrawFrame() {
    // Don't keep on truckin' if there's an error or the benchmark has stopped.
    if (_hasErrored || _benchmarkStopped) {
      return;
    }
    try {
      _recorder.frameWillDraw();
      super.handleDrawFrame();
      _recorder.frameDidDraw();
    } catch (error, stackTrace) {
      _haltBenchmarkWithError(error, stackTrace);
      rethrow;
    }
  }
}

int _currentFrameNumber = 1;

/// Adds a marker indication the beginning of frame rendering.
///
/// This adds an event to the performance trace used to find measured frames in
/// Chrome tracing data. The tracing data contains all frames, but some
/// benchmarks are only interested in a subset of frames. For example,
/// [WidgetBuildRecorder] only measures frames that build widgets, and ignores
/// frames that clear the screen.
void startMeasureFrame() {
  html.window.performance.mark('measured_frame_start#$_currentFrameNumber');
}

/// Signals the end of a measured frame.
///
/// See [startMeasureFrame] for details on what this instrumentation is used
/// for.
void endMeasureFrame() {
  html.window.performance.mark('measured_frame_end#$_currentFrameNumber');
  html.window.performance.measure(
    'measured_frame',
    'measured_frame_start#$_currentFrameNumber',
    'measured_frame_end#$_currentFrameNumber',
  );
  _currentFrameNumber += 1;
}
