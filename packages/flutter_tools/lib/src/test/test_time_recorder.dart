// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../globals.dart' as globals;

class TestTimeRecorder {
  final List<TestTimeRecord> _phaseRecords = List<TestTimeRecord>.generate(TestTimePhases.values.length, (_) => TestTimeRecord());

  Stopwatch start(TestTimePhases phase) {
    return _phaseRecords[phase.index].start();
  }

  void stop(TestTimePhases phase, Stopwatch stopwatch) {
    _phaseRecords[phase.index].stop(stopwatch);
  }

  void print() {
    for(final TestTimePhases phase in TestTimePhases.values) {
      globals.printTrace(_getPrintStringForPhase(phase));
    }
  }

  List<String> getPrintAsListForTesting() {
    final List<String> result = <String>[];
    for(final TestTimePhases phase in TestTimePhases.values) {
      result.add(_getPrintStringForPhase(phase));
    }
    return result;
  }

  String _getPrintStringForPhase(final TestTimePhases phase) {
    assert(_phaseRecords[phase.index].isDone());
    return 'Runtime for phase ${phase.name}: ${_phaseRecords[phase.index]}';
  }
}

class TestTimeRecord {
  Duration _combinedRuntime = Duration.zero;
  final Stopwatch _wallClockRuntime = Stopwatch();
  int _currentlyRunningCount = 0;

  Stopwatch start() {
    final Stopwatch stopwatch = Stopwatch()..start();
    if (_currentlyRunningCount == 0) {
      _wallClockRuntime.start();
    }
    _currentlyRunningCount++;
    return stopwatch;
  }

  void stop(Stopwatch stopwatch) {
    _currentlyRunningCount--;
    if (_currentlyRunningCount == 0) {
      _wallClockRuntime.stop();
    }
    _combinedRuntime = _combinedRuntime + stopwatch.elapsed;
    assert(_currentlyRunningCount >= 0);
  }

  @override
  String toString() {
    return 'Wall-clock: ${_wallClockRuntime.elapsed}; combined: $_combinedRuntime.';
  }

  bool isDone() {
    return _currentlyRunningCount == 0;
  }
}

enum TestTimePhases {
  TestRunner,
  Compile,
  Run,
  CoverageTotal,
  Coverage_collect,
  Coverage_parseJson,
  Coverage_addHitmap,
  CoverageDataCollect,
  WatcherFinishedTest,
}
