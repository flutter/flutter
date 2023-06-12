// Copyright 2018 Google Inc. All Rights Reserved.
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

import 'clock.dart';

/// The system's timer frequency in Hz.
///
/// We can't really know how frequently the clock is updated, and that may not
/// even make sense for some implementations, so we just pretend we follow the
/// system's frequency.
final _frequency = Stopwatch().frequency;

/// A stopwatch that gets its notion of the current time from a [Clock].
class ClockStopwatch implements Stopwatch {
  /// The provider for this stopwatch's notion of the current time.
  final Clock _clock;

  /// The number of elapsed microseconds that have been recorded from previous
  /// runs of this stopwatch.
  ///
  /// This doesn't include the time between [_start] and the current time.
  var _elapsed = 0;

  /// The point at which [start] was called most recently, or `null` if this
  /// isn't active.
  DateTime? _start;

  ClockStopwatch(this._clock);

  @override
  int get frequency => _frequency;
  @override
  int get elapsedTicks => (elapsedMicroseconds * frequency) ~/ 1000000;
  @override
  Duration get elapsed => Duration(microseconds: elapsedMicroseconds);
  @override
  int get elapsedMilliseconds => elapsedMicroseconds ~/ 1000;
  @override
  bool get isRunning => _start != null;

  @override
  int get elapsedMicroseconds =>
      _elapsed +
      (_start == null ? 0 : _clock.now().difference(_start!).inMicroseconds);

  @override
  void start() {
    _start ??= _clock.now();
  }

  @override
  void stop() {
    _elapsed = elapsedMicroseconds;
    _start = null;
  }

  @override
  void reset() {
    _elapsed = 0;
    if (_start != null) _start = _clock.now();
  }
}
