// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
class Stopwatch {
  static int Function() _timerTicks = () {
    return JS<double>("() => Date.now()").toInt();
  };

  @patch
  static int _initTicker() {
    if (JS<bool>("() => typeof dartUseDateNowForTicks !== \"undefined\"")) {
      // Millisecond precision, as int.
      return 1000;
    } else {
      // Microsecond precision as double. Convert to int without losing
      // precision.
      _timerTicks = () {
        return JS<double>("() => 1000 * performance.now()").toInt();
      };
      return 1000000;
    }
  }

  @patch
  static int _now() => _timerTicks();

  @patch
  int get elapsedMicroseconds {
    int ticks = elapsedTicks;
    if (_frequency == 1000000) return ticks;
    assert(_frequency == 1000);
    return ticks * 1000;
  }

  @patch
  int get elapsedMilliseconds {
    int ticks = elapsedTicks;
    if (_frequency == 1000) return ticks;
    assert(_frequency == 1000000);
    return ticks ~/ 1000;
  }
}
