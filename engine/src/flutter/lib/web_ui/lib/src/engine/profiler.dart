// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// A function that receives a benchmark [value] labeleb by [name].
typedef OnBenchmark = void Function(String name, num value);

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
    Profiler.instance.benchmark(name, stopwatch.elapsedMicroseconds);
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
    if (_instance == null) {
      throw Exception(
        'Profiler has not been properly initialized. '
        'Make sure Profiler.ensureInitialized() is being called before you '
        'access Profiler.instance',
      );
    }
    return _instance;
  }

  static Profiler _instance;

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
  void benchmark(String name, num value) {
    _checkBenchmarkMode();

    final OnBenchmark onBenchmark =
        js_util.getProperty(html.window, '_flutter_internal_on_benchmark');
    if (onBenchmark != null) {
      onBenchmark(name, value);
    }
  }
}
