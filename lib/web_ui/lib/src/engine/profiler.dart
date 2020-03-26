// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

typedef OnBenchmark = void Function(String name, num value);

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
    defaultValue: true,
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
