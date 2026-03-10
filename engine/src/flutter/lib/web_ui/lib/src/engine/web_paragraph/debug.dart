// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../engine.dart';

typedef Entry = ({String group, String name});

/// Debugging utilities for WebParagraph.
class WebParagraphDebug {
  static bool logging = false;
  static bool apiLogging = false;

  /// Logs a debug message if logging is enabled.
  static void log(String arg) {
    assert(() {
      if (logging) {
        print(arg);
      }
      return true;
    }());
  }

  /// Logs an API trace message if API logging is enabled.
  static void apiTrace(String arg) {
    assert(() {
      if (apiLogging || logging) {
        print(arg);
      }
      return true;
    }());
  }

  /// Logs an API warning message.
  static void warning(String arg) {
    assert(() {
      print('WARNING: $arg');
      return true;
    }());
  }

  /// Logs an API error message.
  static void error(String arg) {
    assert(() {
      print('ERROR: $arg');
      return true;
    }());
  }
}

/// Profiler for WebParagraph related operations.
class WebParagraphProfiler {
  static Map<String, Duration> durations = {};
  static Map<String, int> counts = {};

  /// Register an engine benchmark callback to collect profiling data for WebParagraph operations.
  static void register() {
    if (!Profiler.isBenchmarkMode) {
      return;
    }
    Profiler.ensureInitialized();
    engineBenchmarkValueCallback = (String name, double value) {
      counts[name] = (counts[name] ?? 0) + 1;
      durations[name] = (durations[name] ?? Duration.zero) + Duration(microseconds: value.toInt());
    };
  }

  /// Logs the collected profiling information to the console.
  static void log() {
    if (!Profiler.isBenchmarkMode) {
      return;
    }
    for (final MapEntry<String, Duration> entry in durations.entries) {
      print('${entry.key}: ${entry.value.inMilliseconds}ms');
    }
  }

  /// Resets the collected profiling information.
  static void reset() {
    durations = {};
    counts = {};
  }
}
