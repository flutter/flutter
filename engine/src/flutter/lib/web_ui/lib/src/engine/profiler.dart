// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// A function that receives a benchmark [value] labeleb by [name].
typedef OnBenchmark = void Function(String name, double value);

/// A function that computes a value of type [R].
///
/// Functions of this signature can be passed to [timeAction] for performance
/// profiling.
typedef Action<R> = R Function();

/// Uses the [Profiler] to time a synchronous [action] function and reports the
/// result under the give metric [name].
///
/// If profiling is disabled, simply calls [action] and returns the result.
///
/// Use this for situations when the cost of an extra closure is negligible.
/// This function reduces the boilerplate associated with checking if profiling
/// is enabled and exercising the stopwatch.
///
/// Example:
///
/// ```
/// final result = timeAction('expensive_operation', () {
///   ... expensive work ...
///   return someValue;
/// });
/// ```
R timeAction<R>(String name, Action<R> action) {
  if (!Profiler.isBenchmarkMode) {
    return action();
  } else {
    final Stopwatch stopwatch = Stopwatch()..start();
    final R result = action();
    stopwatch.stop();
    Profiler.instance.benchmark(name, stopwatch.elapsedMicroseconds.toDouble());
    return result;
  }
}

/// The purpose of this class is to facilitate communication of
/// profiling/benchmark data to the outside world (e.g. a macrobenchmark that's
/// running a flutter app).
///
/// To use the [Profiler]:
///
/// 1. Set the environment variable `FLUTTER_WEB_ENABLE_PROFILING` to true.
///
/// 2. Using JS interop, assign a listener function to
///    `window._flutter_internal_on_benchmark` in the browser.
///
/// The listener function will be called every time a new benchmark number is
/// calculated. The signature is `Function(String name, num value)`.
class Profiler {
  Profiler._() {
    _checkBenchmarkMode();
  }

  static bool isBenchmarkMode = const bool.fromEnvironment(
    'FLUTTER_WEB_ENABLE_PROFILING',
    defaultValue: false,
  );

  static Profiler ensureInitialized() {
    _checkBenchmarkMode();
    return Profiler._instance ??= Profiler._();
  }

  static Profiler get instance {
    _checkBenchmarkMode();
    final Profiler? profiler = _instance;
    if (profiler == null) {
      throw Exception(
        'Profiler has not been properly initialized. '
        'Make sure Profiler.ensureInitialized() is being called before you '
        'access Profiler.instance',
      );
    }
    return profiler;
  }

  static Profiler? _instance;

  static void _checkBenchmarkMode() {
    if (!isBenchmarkMode) {
      throw Exception(
        'Cannot use Profiler unless benchmark mode is enabled. '
        'You can enable it by setting the `FLUTTER_WEB_ENABLE_PROFILING` '
        'environment variable to true.',
      );
    }
  }

  /// Used to send benchmark data to whoever is listening to them.
  void benchmark(String name, double value) {
    _checkBenchmarkMode();

    final OnBenchmark? onBenchmark =
        js_util.getProperty(html.window, '_flutter_internal_on_benchmark');
    if (onBenchmark != null) {
      onBenchmark(name, value);
    }
  }
}

/// Whether we are collecting [ui.FrameTiming]s.
bool get _frameTimingsEnabled {
  return EnginePlatformDispatcher.instance._onReportTimings != null;
}

/// Collects frame timings from frames.
///
/// This list is periodically reported to the framework (see
/// [_kFrameTimingsSubmitInterval]).
List<ui.FrameTiming> _frameTimings = <ui.FrameTiming>[];

/// The amount of time in microseconds we wait between submitting
/// frame timings.
const int _kFrameTimingsSubmitInterval = 100000; // 100 milliseconds

/// The last time (in microseconds) we submitted frame timings.
int _frameTimingsLastSubmitTime = _nowMicros();

// These variables store individual [ui.FrameTiming] properties.
int _vsyncStartMicros = -1;
int _buildStartMicros = -1;
int _buildFinishMicros = -1;
int _rasterStartMicros = -1;
int _rasterFinishMicros = -1;

/// Records the vsync timestamp for this frame.
void _frameTimingsOnVsync() {
  if (!_frameTimingsEnabled) {
    return;
  }
  _vsyncStartMicros = _nowMicros();
}

/// Records the time when the framework started building the frame.
void _frameTimingsOnBuildStart() {
  if (!_frameTimingsEnabled) {
    return;
  }
  _buildStartMicros = _nowMicros();
}

/// Records the time when the framework finished building the frame.
void _frameTimingsOnBuildFinish() {
  if (!_frameTimingsEnabled) {
    return;
  }
  _buildFinishMicros = _nowMicros();
}

/// Records the time when the framework started rasterizing the frame.
///
/// On the web, this value is almost always the same as [_buildFinishMicros]
/// because it's single-threaded so there's no delay between building
/// and rasterization.
///
/// This also means different things between HTML and CanvasKit renderers.
///
/// In HTML "rasterization" only captures DOM updates, but not the work that
/// the browser performs after the DOM updates are committed. The browser
/// does not report that information.
///
/// CanvasKit captures everything because we control the rasterization
/// process, so we know exactly when rasterization starts and ends.
void _frameTimingsOnRasterStart() {
  if (!_frameTimingsEnabled) {
    return;
  }
  _rasterStartMicros = _nowMicros();
}

/// Records the time when the framework started rasterizing the frame.
///
/// See [_frameTimingsOnRasterStart] for more details on what rasterization
/// timings mean on the web.
void _frameTimingsOnRasterFinish() {
  if (!_frameTimingsEnabled) {
    return;
  }
  final int now = _nowMicros();
  _rasterFinishMicros = now;
  _frameTimings.add(ui.FrameTiming(
    vsyncStart: _vsyncStartMicros,
    buildStart: _buildStartMicros,
    buildFinish: _buildFinishMicros,
    rasterStart: _rasterStartMicros,
    rasterFinish: _rasterFinishMicros,
  ));
  _vsyncStartMicros = -1;
  _buildStartMicros = -1;
  _buildFinishMicros = -1;
  _rasterStartMicros = -1;
  _rasterFinishMicros = -1;
  if (now - _frameTimingsLastSubmitTime > _kFrameTimingsSubmitInterval) {
    _frameTimingsLastSubmitTime = now;
    EnginePlatformDispatcher.instance.invokeOnReportTimings(_frameTimings);
    _frameTimings = <ui.FrameTiming>[];
  }
}

/// Current timestamp in microseconds taken from the high-precision
/// monotonically increasing timer.
///
/// See also:
///
/// * https://developer.mozilla.org/en-US/docs/Web/API/Performance/now,
///   particularly notes about Firefox rounding to 1ms for security reasons,
///   which can be bypassed in tests by setting certain browser options.
int _nowMicros() {
  return (html.window.performance.now() * 1000).toInt();
}
