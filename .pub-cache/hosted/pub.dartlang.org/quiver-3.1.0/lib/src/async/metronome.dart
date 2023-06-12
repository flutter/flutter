// Copyright 2014 Google Inc. All Rights Reserved.
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

import 'package:quiver/time.dart';

/// A stream of [DateTime] events at [interval]s centered on [anchor].
///
/// This stream accounts for drift but only guarantees that events are
/// delivered on or after the interval. If the system is busy for longer than
/// two [interval]s, only one will be delivered.
///
/// [anchor] defaults to [clock.now], which means the stream represents a
/// self-correcting periodic timer. If anchor is the epoch, then the stream is
/// synchronized to wall-clock time. It can be anchored anywhere in time, but
/// this does not delay the first delivery.
///
/// Examples:
///
///     new Metronome.epoch(aMinute).listen((d) => print(d));
///
/// Could print the following stream of events, anchored by epoch, till the
/// stream is canceled:
///
///     2014-05-04 14:06:00.001
///     2014-05-04 14:07:00.000
///     2014-05-04 14:08:00.003
///     ...
///
/// Example anchored in the future (now = 2014-05-05 20:06:00.123)
///
///     new IsochronousStream.periodic(aMillisecond * 100,
///         anchorMs: DateTime.parse("2014-05-05 21:07:00"))
///         .listen(print);
///
///     2014-05-04 20:06:00.223
///     2014-05-04 20:06:00.324
///     2014-05-04 20:06:00.423
///     ...
class Metronome extends Stream<DateTime> {
  Metronome.epoch(Duration interval, {Clock clock = const Clock()})
      : this._(interval, clock: clock, anchor: _epoch);

  Metronome.periodic(Duration interval,
      {Clock clock = const Clock(), DateTime? anchor})
      : this._(interval, clock: clock, anchor: anchor);

  Metronome._(this.interval, {this.clock = const Clock(), this.anchor})
      : _intervalMs = interval.inMilliseconds,
        _anchorMs = (anchor ?? clock.now()).millisecondsSinceEpoch {
    _controller = StreamController<DateTime>.broadcast(
        sync: true,
        onCancel: () {
          _timer!.cancel();
        },
        onListen: () {
          _startTimer(clock.now());
        });
  }

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

  final Clock clock;
  final Duration interval;
  final DateTime? anchor;

  Timer? _timer;
  late final StreamController<DateTime> _controller;
  final int _intervalMs;
  final int _anchorMs;

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<DateTime> listen(void onData(DateTime event)?,
          {Function? onError, void onDone()?, bool? cancelOnError}) =>
      _controller.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  void _startTimer(DateTime now) {
    var delay =
        _intervalMs - ((now.millisecondsSinceEpoch - _anchorMs) % _intervalMs);
    _timer = Timer(Duration(milliseconds: delay), _tickDate);
  }

  void _tickDate() {
    // Hey now, what's all this hinky clock.now() calls? Simple, if the workers
    // on the receiving end of _controller.add() take a non-zero amount of time
    // to do their thing (e.g. rendering a large scene with canvas), the next
    // timer must be adjusted to account for the lapsed time.
    _controller.add(clock.now());
    _startTimer(clock.now());
  }
}
