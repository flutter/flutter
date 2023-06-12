// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Interface describing clocks used by the [MemoryFileSystem].
///
/// The [MemoryFileSystem] uses a clock to determine the modification times of
/// files that are created in that file system.
abstract class Clock {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Clock();

  /// A real-time clock.
  ///
  /// Uses [DateTime.now] to reflect the actual time reported by the operating
  /// system.
  const factory Clock.realTime() = _RealtimeClock;

  /// A monotonically-increasing test clock.
  ///
  /// Each time [now] is called, the time increases by one minute.
  ///
  /// The `start` argument can be used to set the seed time for the clock.
  /// The first value will be that time plus one minute.
  /// By default, `start` is midnight on the first of January, 2000.
  factory Clock.monotonicTest() = _MonotonicTestClock;

  /// Returns the value of the clock.
  DateTime get now;
}

class _RealtimeClock extends Clock {
  const _RealtimeClock();

  @override
  DateTime get now => DateTime.now();
}

class _MonotonicTestClock extends Clock {
  _MonotonicTestClock({
    DateTime? start,
  }) : _current = start ?? DateTime(2000);

  DateTime _current;

  @override
  DateTime get now {
    _current = _current.add(const Duration(minutes: 1));
    return _current;
  }
}
