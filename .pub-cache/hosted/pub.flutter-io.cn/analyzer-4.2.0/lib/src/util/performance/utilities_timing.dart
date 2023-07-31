// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A `CountedStopwatch` is a [Stopwatch] that counts the number of times the
/// stop method has been invoked.
class CountedStopwatch extends Stopwatch {
  /// The number of times the [stop] method has been invoked.
  int stopCount = 0;

  /// Initialize a newly created stopwatch.
  CountedStopwatch();

  /// The average number of millisecond that were recorded each time the [start]
  /// and [stop] methods were invoked.
  int get averageMilliseconds => elapsedMilliseconds ~/ stopCount;

  @override
  void reset() {
    super.reset();
    stopCount = 0;
  }

  @override
  void stop() {
    super.stop();
    stopCount++;
  }
}
