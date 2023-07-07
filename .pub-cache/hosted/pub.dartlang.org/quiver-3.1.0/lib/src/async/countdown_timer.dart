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

import 'dart:async';

/// A simple countdown timer that fires events in regular increments until a
/// duration has passed.
///
/// CountdownTimer implements [Stream] and sends itself as the event. From the
/// timer you can get the [remaining] and [elapsed] time, or [cancel] the
/// timer.
class CountdownTimer extends Stream<CountdownTimer> {
  /// Creates a new [CountdownTimer] that fires events in increments of
  /// [increment], until the [duration] has passed.
  ///
  /// [stopwatch] is for testing purposes. If you're using CountdownTimer and
  /// need to control time in a test, pass a mock or a fake. See [FakeAsync]
  /// and [FakeStopwatch].
  CountdownTimer(Duration duration, this.increment, {Stopwatch? stopwatch})
      : _duration = duration,
        _stopwatch = stopwatch ?? Stopwatch(),
        _controller = StreamController<CountdownTimer>.broadcast(sync: true) {
    _timer = Timer.periodic(increment, _tick);
    _stopwatch.start();
  }

  static const _THRESHOLD_MS = 4;

  final Duration _duration;
  final Stopwatch _stopwatch;

  /// The duration between timer events.
  final Duration increment;
  final StreamController<CountdownTimer> _controller;
  late final Timer _timer;

  @override
  StreamSubscription<CountdownTimer> listen(void onData(CountdownTimer event)?,
          {Function? onError, void onDone()?, bool? cancelOnError}) =>
      _controller.stream.listen(onData, onError: onError, onDone: onDone);

  Duration get elapsed => _stopwatch.elapsed;

  Duration get remaining => _duration - _stopwatch.elapsed;

  bool get isRunning => _stopwatch.isRunning;

  void cancel() {
    _stopwatch.stop();
    _timer.cancel();
    _controller.close();
  }

  void _tick(Timer timer) {
    var t = remaining;
    _controller.add(this);
    // timers may have a 4ms resolution
    if (t.inMilliseconds < _THRESHOLD_MS) {
      cancel();
    }
  }
}
