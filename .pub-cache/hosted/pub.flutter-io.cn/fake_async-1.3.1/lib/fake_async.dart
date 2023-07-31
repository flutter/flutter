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
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';

/// The type of a microtask callback.
typedef _Microtask = void Function();

/// Runs [callback] in a [Zone] where all asynchrony is controlled by an
/// instance of [FakeAsync].
///
/// All [Future]s, [Stream]s, [Timer]s, microtasks, and other time-based
/// asynchronous features used within [callback] are controlled by calls to
/// [FakeAsync.elapse] rather than the passing of real time.
///
/// The [`clock`][] property will be set to a clock that reports the fake
/// elapsed time. By default, it starts at the time [fakeAsync] was created
/// (according to [`clock.now()`][]), but this can be controlled by passing
/// [initialTime].
///
/// [`clock`]: https://www.dartdocs.org/documentation/clock/latest/clock/clock.html
/// [`clock.now()`]: https://www.dartdocs.org/documentation/clock/latest/clock/Clock/now.html
///
/// Returns the result of [callback].
T fakeAsync<T>(T Function(FakeAsync async) callback, {DateTime? initialTime}) =>
    FakeAsync(initialTime: initialTime).run(callback);

/// A class that mocks out the passage of time within a [Zone].
///
/// Test code can be passed as a callback to [run], which causes it to be run in
/// a [Zone] which fakes timer and microtask creation, such that they are run
/// during calls to [elapse] which simulates the asynchronous passage of time.
///
/// The synchronous passage of time (as from blocking or expensive calls) can
/// also be simulated using [elapseBlocking].
class FakeAsync {
  /// The value of [clock] within [run].
  late final Clock _clock;

  /// The amount of fake time that's elapsed since this [FakeAsync] was
  /// created.
  Duration get elapsed => _elapsed;
  var _elapsed = Duration.zero;

  /// Whether Timers created by this FakeAsync will include a creation stack
  /// trace in [FakeAsync.pendingTimersDebugString].
  final bool includeTimerStackTrace;

  /// The fake time at which the current call to [elapse] will finish running.
  ///
  /// This is `null` if there's no current call to [elapse].
  Duration? _elapsingTo;

  /// Tasks that are scheduled to run when fake time progresses.
  final _microtasks = Queue<_Microtask>();

  /// All timers created within [run].
  final _timers = <FakeTimer>{};

  /// All the current pending timers.
  List<FakeTimer> get pendingTimers => _timers.toList(growable: false);

  /// The debug strings for all the current pending timers.
  List<String> get pendingTimersDebugString =>
      pendingTimers.map((timer) => timer.debugString).toList(growable: false);

  /// The number of active periodic timers created within a call to [run] or
  /// [fakeAsync].
  int get periodicTimerCount =>
      _timers.where((timer) => timer.isPeriodic).length;

  /// The number of active non-periodic timers created within a call to [run] or
  /// [fakeAsync].
  int get nonPeriodicTimerCount =>
      _timers.where((timer) => !timer.isPeriodic).length;

  /// The number of pending microtasks scheduled within a call to [run] or
  /// [fakeAsync].
  int get microtaskCount => _microtasks.length;

  /// Creates a [FakeAsync].
  ///
  /// Within [run], the [`clock`][] property will start at [initialTime] and
  /// move forward as fake time elapses.
  ///
  /// [`clock`]: https://www.dartdocs.org/documentation/clock/latest/clock/clock.html
  ///
  /// Note: it's usually more convenient to use [fakeAsync] rather than creating
  /// a [FakeAsync] object and calling [run] manually.
  FakeAsync({DateTime? initialTime, this.includeTimerStackTrace = true}) {
    var nonNullInitialTime = initialTime ?? clock.now();
    _clock = Clock(() => nonNullInitialTime.add(elapsed));
  }

  /// Returns a fake [Clock] whose time can is elapsed by calls to [elapse] and
  /// [elapseBlocking].
  ///
  /// The returned clock starts at [initialTime] plus the fake time that's
  /// already been elapsed. Further calls to [elapse] and [elapseBlocking] will
  /// advance the clock as well.
  ///
  /// Note that it's usually easier to use the top-level [`clock`][] property.
  /// Only call this function if you want a different [initialTime] than the
  /// default.
  ///
  /// [`clock`]: https://www.dartdocs.org/documentation/clock/latest/clock/clock.html
  Clock getClock(DateTime initialTime) =>
      Clock(() => initialTime.add(_elapsed));

  /// Simulates the asynchronous passage of time.
  ///
  /// Throws an [ArgumentError] if [duration] is negative. Throws a [StateError]
  /// if a previous call to [elapse] has not yet completed.
  ///
  /// Any timers created within [run] or [fakeAsync] will fire if their time is
  /// within [duration]. The microtask queue is processed before and after each
  /// timer fires.
  void elapse(Duration duration) {
    if (duration.inMicroseconds < 0) {
      throw ArgumentError.value(duration, 'duration', 'may not be negative');
    } else if (_elapsingTo != null) {
      throw StateError('Cannot elapse until previous elapse is complete.');
    }

    _elapsingTo = _elapsed + duration;
    _fireTimersWhile((next) => next._nextCall <= _elapsingTo!);
    _elapseTo(_elapsingTo!);
    _elapsingTo = null;
  }

  /// Simulates the synchronous passage of time, resulting from blocking or
  /// expensive calls.
  ///
  /// Neither timers nor microtasks are run during this call, but if this is
  /// called within [elapse] they may fire afterwards.
  ///
  /// Throws an [ArgumentError] if [duration] is negative.
  void elapseBlocking(Duration duration) {
    if (duration.inMicroseconds < 0) {
      throw ArgumentError('Cannot call elapse with negative duration');
    }

    _elapsed += duration;
    var elapsingTo = _elapsingTo;
    if (elapsingTo != null && _elapsed > elapsingTo) _elapsingTo = _elapsed;
  }

  /// Runs [callback] in a [Zone] where all asynchrony is controlled by `this`.
  ///
  /// All [Future]s, [Stream]s, [Timer]s, microtasks, and other time-based
  /// asynchronous features used within [callback] are controlled by calls to
  /// [elapse] rather than the passing of real time.
  ///
  /// The [`clock`][] property will be set to a clock that reports the fake
  /// elapsed time. By default, it starts at the time the [FakeAsync] was
  /// created (according to [`clock.now()`][]), but this can be controlled by
  /// passing `initialTime` to [new FakeAsync].
  ///
  /// [`clock`]: https://www.dartdocs.org/documentation/clock/latest/clock/clock.html
  /// [`clock.now()`]: https://www.dartdocs.org/documentation/clock/latest/clock/Clock/now.html
  ///
  /// Calls [callback] with `this` as argument and returns its result.
  ///
  /// Note: it's usually more convenient to use [fakeAsync] rather than creating
  /// a [FakeAsync] object and calling [run] manually.
  T run<T>(T Function(FakeAsync self) callback) =>
      runZoned(() => withClock(_clock, () => callback(this)),
          zoneSpecification: ZoneSpecification(
              createTimer: (_, __, ___, duration, callback) =>
                  _createTimer(duration, callback, false),
              createPeriodicTimer: (_, __, ___, duration, callback) =>
                  _createTimer(duration, callback, true),
              scheduleMicrotask: (_, __, ___, microtask) =>
                  _microtasks.add(microtask)));

  /// Runs all pending microtasks scheduled within a call to [run] or
  /// [fakeAsync] until there are no more microtasks scheduled.
  ///
  /// Does not run timers.
  void flushMicrotasks() {
    while (_microtasks.isNotEmpty) {
      _microtasks.removeFirst()();
    }
  }

  /// Elapses time until there are no more active timers.
  ///
  /// If `flushPeriodicTimers` is `true` (the default), this will repeatedly run
  /// periodic timers until they're explicitly canceled. Otherwise, this will
  /// stop when the only active timers are periodic.
  ///
  /// The [timeout] controls how much fake time may elapse before a [StateError]
  /// is thrown. This ensures that a periodic timer doesn't cause this method to
  /// deadlock. It defaults to one hour.
  void flushTimers(
      {Duration timeout = const Duration(hours: 1),
      bool flushPeriodicTimers = true}) {
    var absoluteTimeout = _elapsed + timeout;
    _fireTimersWhile((timer) {
      if (timer._nextCall > absoluteTimeout) {
        // TODO(nweiz): Make this a [TimeoutException].
        throw StateError('Exceeded timeout $timeout while flushing timers');
      }

      if (flushPeriodicTimers) return _timers.isNotEmpty;

      // Continue firing timers until the only ones left are periodic *and*
      // every periodic timer has had a change to run against the final
      // value of [_elapsed].
      return _timers
          .any((timer) => !timer.isPeriodic || timer._nextCall <= _elapsed);
    });
  }

  /// Invoke the callback for each timer until [predicate] returns `false` for
  /// the next timer that would be fired.
  ///
  /// Microtasks are flushed before and after each timer is fired. Before each
  /// timer fires, [_elapsed] is updated to the appropriate duration.
  void _fireTimersWhile(bool Function(FakeTimer timer) predicate) {
    flushMicrotasks();
    for (;;) {
      if (_timers.isEmpty) break;

      var timer = minBy(_timers, (FakeTimer timer) => timer._nextCall)!;
      if (!predicate(timer)) break;

      _elapseTo(timer._nextCall);
      timer._fire();
      flushMicrotasks();
    }
  }

  /// Creates a new timer controlled by `this` that fires [callback] after
  /// [duration] (or every [duration] if [periodic] is `true`).
  Timer _createTimer(Duration duration, Function callback, bool periodic) {
    var timer = FakeTimer._(duration, callback, periodic, this,
        includeStackTrace: includeTimerStackTrace);
    _timers.add(timer);
    return timer;
  }

  /// Sets [_elapsed] to [to] if [to] is longer than [_elapsed].
  void _elapseTo(Duration to) {
    if (to > _elapsed) _elapsed = to;
  }
}

/// An implementation of [Timer] that's controlled by a [FakeAsync].
class FakeTimer implements Timer {
  /// If this is periodic, the time that should elapse between firings of this
  /// timer.
  ///
  /// This is not used by non-periodic timers.
  final Duration duration;

  /// The callback to invoke when the timer fires.
  ///
  /// For periodic timers, this is a `void Function(Timer)`. For non-periodic
  /// timers, it's a `void Function()`.
  final Function _callback;

  /// Whether this is a periodic timer.
  final bool isPeriodic;

  /// The [FakeAsync] instance that controls this timer.
  final FakeAsync _async;

  /// The value of [FakeAsync._elapsed] at (or after) which this timer should be
  /// fired.
  late Duration _nextCall;

  /// The current stack trace when this timer was created.
  ///
  /// If [FakeAsync.includeTimerStackTrace] is set to false then accessing
  /// this field will throw a [TypeError].
  StackTrace get creationStackTrace => _creationStackTrace!;
  final StackTrace? _creationStackTrace;

  var _tick = 0;

  @override
  int get tick => _tick;

  /// Returns debugging information to try to identify the source of the
  /// [Timer].
  String get debugString => 'Timer (duration: $duration, periodic: $isPeriodic)'
      '${_creationStackTrace != null ? ', created:\n$creationStackTrace' : ''}';

  FakeTimer._(Duration duration, this._callback, this.isPeriodic, this._async,
      {bool includeStackTrace = true})
      : duration = duration < Duration.zero ? Duration.zero : duration,
        _creationStackTrace = includeStackTrace ? StackTrace.current : null {
    _nextCall = _async._elapsed + this.duration;
  }

  @override
  bool get isActive => _async._timers.contains(this);

  @override
  void cancel() => _async._timers.remove(this);

  /// Fires this timer's callback and updates its state as necessary.
  void _fire() {
    assert(isActive);
    _tick++;
    if (isPeriodic) {
      _callback(this);
      _nextCall += duration;
    } else {
      cancel();
      _callback();
    }
  }
}
