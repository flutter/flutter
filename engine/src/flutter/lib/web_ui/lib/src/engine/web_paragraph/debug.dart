// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../engine.dart';

typedef Entry = ({String group, String name});

class WebParagraphDebug {
  static bool logging = false;
  static bool apiLogging = false;

  static void log(String arg) {
    assert(() {
      if (logging) {
        print(arg);
      }
      return true;
    }());
  }

  static void apiTrace(String arg) {
    assert(() {
      if (apiLogging || logging) {
        print(arg);
      }
      return true;
    }());
  }

  static void warning(String arg) {
    assert(() {
      print('WARNING: $arg');
      return true;
    }());
  }

  static void error(String arg) {
    assert(() {
      print('ERROR: $arg');
      return true;
    }());
  }
}

class WebParagraphProfiler {
  static Map<String, Duration> durations = {};
  static Map<String, int> counts = {};

  static void register() {
    Profiler.ensureInitialized();
    engineBenchmarkValueCallback = (String name, double value) {
      durations[name] = Duration(milliseconds: value.toInt());
      counts[name] = (counts[name] ?? 0) + 1;
    };
  }

  static void log() {
    for (final MapEntry<String, Duration> entry in durations.entries) {
      //print('${entry.key}: ${entry.value.inMicroseconds}μs');
      print(
        entry.key.contains('/')
            ? '${entry.key}: ${entry.value.inMilliseconds}ms / ${counts[entry.key] ?? 1} = ${(entry.value.inMilliseconds / (counts[entry.key] ?? 1)).toStringAsFixed(3)}ms'
            : '${entry.key}: ${entry.value.inMilliseconds}ms',
      );
    }
  }

  static void reset() {
    durations = {};
  }
}
