// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Returns the current test time in microseconds.
typedef Now = int Function();

/// A [Stopwatch] implementation that gets the current time in microseconds
/// via a user-supplied function.
class FakeStopwatch implements Stopwatch {
  FakeStopwatch(int now(), this.frequency)
      : _now = now,
        _start = null,
        _stop = null;

  final Now _now;
  int? _start;
  int? _stop;

  @override
  int frequency;

  @override
  void start() {
    if (isRunning) return;
    if (_start == null) {
      _start = _now();
    } else {
      _start = _now() - (_stop! - _start!);
      _stop = null;
    }
  }

  @override
  void stop() {
    if (!isRunning) return;
    _stop = _now();
  }

  @override
  void reset() {
    if (_start == null) return;
    _start = _now();
    if (_stop != null) {
      _stop = _start;
    }
  }

  @override
  int get elapsedTicks {
    if (_start == null) {
      return 0;
    }
    return (_stop == null) ? (_now() - _start!) : (_stop! - _start!);
  }

  @override
  Duration get elapsed => Duration(microseconds: elapsedMicroseconds);

  @override
  int get elapsedMicroseconds => (elapsedTicks * 1000000) ~/ frequency;

  @override
  int get elapsedMilliseconds => (elapsedTicks * 1000) ~/ frequency;

  @override
  bool get isRunning => _start != null && _stop == null;
}
